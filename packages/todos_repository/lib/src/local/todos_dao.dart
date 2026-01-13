import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:todo_api/todo_api.dart';
import 'package:todos_repository/src/local/todo_row.dart';

import 'todos_database.dart';

class TodosDao {
  TodosDao({required TodosDatabase database}) : _database = database {
    _controller = StreamController<List<Todo>>.broadcast(
      onListen: () {
        unawaited(_emitTodos());
      },
    );
  }

  final TodosDatabase _database;
  late final StreamController<List<Todo>> _controller;

  Future<Database> get _db async => _database.database;

  Stream<List<Todo>> watchTodos() => _controller.stream;

  Future<List<Todo>> getTodos({bool includeDeleted = false}) async {
    final rows = await getTodoRows(includeDeleted: includeDeleted);
    return rows.map((row) => row.toTodo()).toList();
  }

  Future<List<TodoRow>> getTodoRows({bool includeDeleted = false}) async {
    final db = await _db;
    final rows = await db.query(
      'todos',
      where: includeDeleted ? null : 'deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return rows.map(TodoRow.fromMap).toList();
  }

  Future<TodoRow?> getTodoRow(int id) async {
    final db = await _db;
    final rows = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return TodoRow.fromMap(rows.first);
  }

  Future<void> upsertTodos(
    List<Todo> todos, {
    DatabaseExecutor? executor,
  }) async {
    if (todos.isEmpty) {
      return;
    }

    final db = executor ?? await _db;
    for (final todo in todos) {
      final existingUpdatedAt = await _getUpdatedAt(
        todo.id,
        executor: db,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'todos',
        {
          'id': todo.id,
          'title': todo.title,
          'completed': todo.completed ? 1 : 0,
          'pending_sync': todo.pendingSync ? 1 : 0,
          'deleted': 0,
          'updated_at': existingUpdatedAt ?? now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    if (executor == null) {
      await _emitTodos();
    }
  }

  Future<void> upsertTodo(
    Todo todo, {
    required bool pendingSync,
    bool deleted = false,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _db;
    final existingUpdatedAt = await _getUpdatedAt(
      todo.id,
      executor: db,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'todos',
      {
        'id': todo.id,
        'title': todo.title,
        'completed': todo.completed ? 1 : 0,
        'pending_sync': pendingSync ? 1 : 0,
        'deleted': deleted ? 1 : 0,
        'updated_at': existingUpdatedAt ?? now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (executor == null) {
      await _emitTodos();
    }
  }

  Future<void> markDeleted(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db;
    await db.update(
      'todos',
      {
        'deleted': 1,
        'pending_sync': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (executor == null) {
      await _emitTodos();
    }
  }

  Future<void> replaceLocalIdWithServerId({
    required int localId,
    required int serverId,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _db;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [serverId],
    );
    await db.update(
      'todos',
      {'id': serverId},
      where: 'id = ?',
      whereArgs: [localId],
    );
    if (executor == null) {
      await _emitTodos();
    }
  }

  Future<void> clearPendingSync(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db;
    await db.update(
      'todos',
      {
        'pending_sync': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (executor == null) {
      await _emitTodos();
    }
  }

  Future<void> hardDelete(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (executor == null) {
      await _emitTodos();
    }
  }

  Future<void> notifyListeners() async {
    await _emitTodos();
  }

  Future<int?> _getUpdatedAt(
    int id, {
    required DatabaseExecutor executor,
  }) async {
    final rows = await executor.query(
      'todos',
      columns: ['updated_at'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['updated_at'] as int?;
  }

  Future<void> _emitTodos() async {
    if (_controller.isClosed) {
      return;
    }
    final todos = await getTodos();
    if (!_controller.isClosed) {
      _controller.add(todos);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
