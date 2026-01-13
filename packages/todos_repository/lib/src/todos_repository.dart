import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_api/todo_api.dart';

import 'local/outbox_dao.dart';
import 'local/todos_dao.dart';
import 'local/todos_database.dart';
import 'models/outbox_op.dart';
import 'models/sync_status.dart';
import 'models/todos_repository_failure.dart';

/// Local-first repository with an outbox for offline sync.
class TodosRepository {
  TodosRepository({
    required JsonPlaceholderApiClient todoApiClient,
    TodosDatabase? database,
    Connectivity? connectivity,
  }) : _todoApiClient = todoApiClient,
       _database = database ?? TodosDatabase(),
       _connectivity = connectivity ?? Connectivity(),
       _syncStatusController = StreamController<SyncStatus>.broadcast() {
    _todosDao = TodosDao(database: _database);
    _outboxDao = OutboxDao(database: _database);
  }

  final JsonPlaceholderApiClient _todoApiClient;
  final TodosDatabase _database;
  final Connectivity _connectivity;
  final StreamController<SyncStatus> _syncStatusController;
  late final TodosDao _todosDao;
  late final OutboxDao _outboxDao;

  /// Stream of todos from the local cache.
  Stream<List<Todo>> watchTodos() => _todosDao.watchTodos();

  /// Forces a local emit to seed listeners with cached data.
  Future<void> loadFromCache() async {
    await _todosDao.notifyListeners();
  }

  /// Stream of sync status updates for background sync work.
  Stream<SyncStatus> watchSyncStatus() => _syncStatusController.stream;

  /// Emits connectivity changes mapped to an online/offline boolean.
  Stream<bool> watchOnlineStatus() => _connectivity.onConnectivityChanged
      .map(
        (status) =>
            status.contains(ConnectivityResult.wifi) ||
            status.contains(ConnectivityResult.mobile),
      )
      .distinct();

  /// Quick connectivity check.
  Future<bool> isOnline() async {
    final status = await _connectivity.checkConnectivity();
    return status.contains(ConnectivityResult.wifi) ||
        status.contains(ConnectivityResult.mobile);
  }

  /// Pulls from the server and merges into cache, preserving pending edits.
  Future<void> refreshFromNetwork() async {
    if (!await isOnline()) {
      return;
    }

    try {
      final remoteTodos = await _todoApiClient.getTodos();
      final localRows = await _todosDao.getTodoRows(includeDeleted: true);
      final localById = {
        for (final row in localRows) row.id: row,
      };

      final todosToUpsert = <Todo>[];
      for (final todo in remoteTodos) {
        final localRow = localById[todo.id];
        if (localRow == null) {
          todosToUpsert.add(todo);
          continue;
        }
        if (localRow.pendingSync || localRow.deleted) {
          continue;
        }
        todosToUpsert.add(todo);
      }
      await _todosDao.upsertTodos(todosToUpsert);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  /// Optimistically creates a todo and enqueues a create op.
  Future<Todo> addTodo(String title) async {
    final localId = _generateLocalId();
    final todo = Todo(
      id: localId,
      title: title,
      completed: false,
      pendingSync: true,
    );
    final op = OutboxOp(
      todoId: localId,
      type: OutboxOpType.create,
      payload: {'title': title, 'completed': false},
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final db = await _database.database;
    await db.transaction((txn) async {
      await _todosDao.upsertTodo(
        todo,
        pendingSync: true,
        executor: txn,
      );
      await _outboxDao.insertOp(op, executor: txn);
    });
    await _todosDao.notifyListeners();

    unawaited(_triggerSyncIfOnline());
    return todo;
  }

  /// Optimistically updates the title and enqueues an update op.
  Future<Todo> updateTodoTitle(int id, String title) async {
    final existing = await _todosDao.getTodoRow(id);
    if (existing == null) {
      throw const TodosRepositoryFailure('Todo not found.');
    }

    final updated = Todo(
      id: id,
      title: title,
      completed: existing.completed,
      pendingSync: true,
    );
    final op = OutboxOp(
      todoId: id,
      type: OutboxOpType.updateTitle,
      payload: {'title': title, 'completed': existing.completed},
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final db = await _database.database;
    await db.transaction((txn) async {
      await _todosDao.upsertTodo(
        updated,
        pendingSync: true,
        executor: txn,
      );
      await _outboxDao.insertOp(op, executor: txn);
    });
    await _todosDao.notifyListeners();

    unawaited(_triggerSyncIfOnline());
    return updated;
  }

  /// Optimistically toggles completion and enqueues a toggle op.
  Future<Todo> toggleTodoCompletion(int id, bool completed) async {
    final existing = await _todosDao.getTodoRow(id);
    if (existing == null) {
      throw const TodosRepositoryFailure('Todo not found.');
    }

    final updated = Todo(
      id: id,
      title: existing.title,
      completed: completed,
      pendingSync: true,
    );
    final op = OutboxOp(
      todoId: id,
      type: OutboxOpType.toggle,
      payload: {'completed': completed, 'title': existing.title},
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final db = await _database.database;
    await db.transaction((txn) async {
      await _todosDao.upsertTodo(
        updated,
        pendingSync: true,
        executor: txn,
      );
      await _outboxDao.insertOp(op, executor: txn);
    });
    await _todosDao.notifyListeners();

    unawaited(_triggerSyncIfOnline());
    return updated;
  }

  /// Optimistically marks deleted and enqueues a delete op.
  Future<void> deleteTodo(int id) async {
    final op = OutboxOp(
      todoId: id,
      type: OutboxOpType.delete,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final db = await _database.database;
    await db.transaction((txn) async {
      await _todosDao.markDeleted(id, executor: txn);
      await _outboxDao.insertOp(op, executor: txn);
    });
    await _todosDao.notifyListeners();

    unawaited(_triggerSyncIfOnline());
  }

  /// Applies pending outbox operations to the server when online.
  Future<void> syncOutbox() async {
    if (!await isOnline()) {
      return;
    }

    final ops = await _outboxDao.getPendingOps();
    if (ops.isEmpty) {
      return;
    }

    _syncStatusController.add(SyncStatus.syncing);

    final coalesced = _coalesceOps(ops);
    for (final item in coalesced) {
      if (item.dropTodo) {
        final db = await _database.database;
        await db.transaction((txn) async {
          await _todosDao.hardDelete(item.todoId, executor: txn);
          await _outboxDao.deleteOpsForTodo(item.todoId, executor: txn);
        });
        await _todosDao.notifyListeners();
        continue;
      }

      final op = item.op;
      if (op == null) {
        continue;
      }

      try {
        switch (op.type) {
          case OutboxOpType.create:
            await _applyCreate(op);
            break;
          case OutboxOpType.updateTitle:
          case OutboxOpType.toggle:
            await _applyUpdate(op);
            break;
          case OutboxOpType.delete:
            await _applyDelete(op);
            break;
        }
      } catch (error) {
        final stopSync = await _handleSyncFailure(item.sourceOps, error);
        if (stopSync) {
          _syncStatusController.add(SyncStatus.failed);
          return;
        }
      }
    }

    _syncStatusController.add(SyncStatus.idle);
  }

  Future<void> _applyCreate(OutboxOp op) async {
    final localRow = await _todosDao.getTodoRow(op.todoId);
    final title = (op.payload?['title'] as String?) ?? localRow?.title;
    final completed =
        (op.payload?['completed'] as bool?) ?? localRow?.completed ?? false;

    if (title == null) {
      await _outboxDao.deleteOpsForTodo(op.todoId);
      return;
    }

    final created = await _todoApiClient.addTodo(
      Todo(id: 0, title: title, completed: completed),
    );

    final db = await _database.database;
    await db.transaction((txn) async {
      if (op.todoId < 0) {
        await _todosDao.replaceLocalIdWithServerId(
          localId: op.todoId,
          serverId: created.id,
          executor: txn,
        );
        await _outboxDao.rewriteTodoIdInOps(
          oldId: op.todoId,
          newId: created.id,
          executor: txn,
        );
        await txn.insert(
          'id_map',
          {
            'local_id': op.todoId,
            'server_id': created.id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await _todosDao.upsertTodo(
        Todo(
          id: created.id,
          title: created.title,
          completed: created.completed,
          pendingSync: false,
        ),
        pendingSync: false,
        executor: txn,
      );
      await _outboxDao.deleteOpsForTodo(created.id, executor: txn);
    });
    await _todosDao.notifyListeners();
  }

  Future<void> _applyUpdate(OutboxOp op) async {
    final row = await _todosDao.getTodoRow(op.todoId);
    if (row == null) {
      await _outboxDao.deleteOpsForTodo(op.todoId);
      return;
    }

    final title = (op.payload?['title'] as String?) ?? row.title;
    final completed = (op.payload?['completed'] as bool?) ?? row.completed;

    Todo updated;
    if (op.payload?.containsKey('title') == true &&
        op.payload?.containsKey('completed') == true) {
      updated = await _todoApiClient.updateTodo(
        Todo(id: row.id, title: title, completed: completed),
      );
    } else if (op.payload?.containsKey('title') == true) {
      updated = await _todoApiClient.updateTodoTitle(
        id: row.id,
        title: title,
      );
    } else {
      updated = await _todoApiClient.updateTodoCompletion(
        id: row.id,
        completed: completed,
      );
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      await _todosDao.upsertTodo(
        Todo(
          id: updated.id,
          title: updated.title,
          completed: updated.completed,
          pendingSync: false,
        ),
        pendingSync: false,
        executor: txn,
      );
      await _outboxDao.deleteOpsForTodo(updated.id, executor: txn);
    });
    await _todosDao.notifyListeners();
  }

  Future<void> _applyDelete(OutboxOp op) async {
    await _todoApiClient.deleteTodo(op.todoId);

    final db = await _database.database;
    await db.transaction((txn) async {
      await _todosDao.hardDelete(op.todoId, executor: txn);
      await _outboxDao.deleteOpsForTodo(op.todoId, executor: txn);
    });
    await _todosDao.notifyListeners();
  }

  Future<bool> _handleSyncFailure(
    List<OutboxOp> sourceOps,
    Object error,
  ) async {
    if (_isNetworkError(error)) {
      return true;
    }

    for (final op in sourceOps) {
      if (op.opId == null) {
        continue;
      }
      await _outboxDao.updateOpFailure(
        opId: op.opId!,
        retryCount: op.retryCount + 1,
        error: error.toString(),
      );
    }
    return false;
  }

  Future<void> _triggerSyncIfOnline() async {
    if (!await isOnline()) {
      return;
    }
    unawaited(syncOutbox());
  }

  List<_CoalescedOp> _coalesceOps(List<OutboxOp> ops) {
    final grouped = <int, List<OutboxOp>>{};
    for (final op in ops) {
      grouped.putIfAbsent(op.todoId, () => []).add(op);
    }

    final results = <_CoalescedOp>[];
    for (final entry in grouped.entries) {
      final group = entry.value
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final firstCreatedAt = group.first.createdAt;
      var sawCreate = false;
      var sawDelete = false;
      String? title;
      bool? completed;

      for (final op in group) {
        switch (op.type) {
          case OutboxOpType.create:
            sawCreate = true;
            title = op.payload?['title'] as String? ?? title;
            completed = op.payload?['completed'] as bool? ?? completed;
            break;
          case OutboxOpType.updateTitle:
            title = op.payload?['title'] as String? ?? title;
            completed = op.payload?['completed'] as bool? ?? completed;
            break;
          case OutboxOpType.toggle:
            completed = op.payload?['completed'] as bool? ?? completed;
            title = op.payload?['title'] as String? ?? title;
            break;
          case OutboxOpType.delete:
            sawDelete = true;
            break;
        }
      }

      if (sawCreate && sawDelete) {
        results.add(
          _CoalescedOp(
            todoId: entry.key,
            firstCreatedAt: firstCreatedAt,
            sourceOps: group,
            dropTodo: true,
          ),
        );
        continue;
      }

      if (sawDelete) {
        results.add(
          _CoalescedOp(
            todoId: entry.key,
            firstCreatedAt: firstCreatedAt,
            sourceOps: group,
            op: OutboxOp(
              todoId: entry.key,
              type: OutboxOpType.delete,
              createdAt: firstCreatedAt,
            ),
          ),
        );
        continue;
      }

      final payload = <String, dynamic>{};
      if (title != null) {
        payload['title'] = title;
      }
      if (completed != null) {
        payload['completed'] = completed;
      }

      if (sawCreate) {
        results.add(
          _CoalescedOp(
            todoId: entry.key,
            firstCreatedAt: firstCreatedAt,
            sourceOps: group,
            op: OutboxOp(
              todoId: entry.key,
              type: OutboxOpType.create,
              payload: payload,
              createdAt: firstCreatedAt,
            ),
          ),
        );
        continue;
      }

      if (payload.isEmpty) {
        continue;
      }

      final type = payload.containsKey('title')
          ? OutboxOpType.updateTitle
          : OutboxOpType.toggle;
      results.add(
        _CoalescedOp(
          todoId: entry.key,
          firstCreatedAt: firstCreatedAt,
          sourceOps: group,
          op: OutboxOp(
            todoId: entry.key,
            type: type,
            payload: payload,
            createdAt: firstCreatedAt,
          ),
        ),
      );
    }

    results.sort((a, b) => a.firstCreatedAt.compareTo(b.firstCreatedAt));
    return results;
  }

  TodosRepositoryFailure _mapFailure(Object error) {
    if (error is TodosRepositoryFailure) {
      return error;
    }
    return TodosRepositoryFailure(error.toString());
  }

  int _generateLocalId() => -DateTime.now().millisecondsSinceEpoch;

  bool _isNetworkError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException;
  }
}

class _CoalescedOp {
  const _CoalescedOp({
    required this.todoId,
    required this.firstCreatedAt,
    required this.sourceOps,
    this.op,
    this.dropTodo = false,
  });

  final int todoId;
  final int firstCreatedAt;
  final List<OutboxOp> sourceOps;
  final OutboxOp? op;
  final bool dropTodo;
}
