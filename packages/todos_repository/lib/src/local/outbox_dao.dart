import 'package:sqflite/sqflite.dart';

import '../models/outbox_op.dart';
import 'todos_database.dart';

class OutboxDao {
  OutboxDao({required TodosDatabase database}) : _database = database;

  final TodosDatabase _database;

  Future<Database> get _db async => _database.database;

  Future<List<OutboxOp>> getPendingOps() async {
    final db = await _db;
    final rows = await db.query(
      'outbox',
      orderBy: 'created_at ASC',
    );
    return rows.map(OutboxOp.fromMap).toList();
  }

  Future<void> insertOp(OutboxOp op, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db;
    await db.insert(
      'outbox',
      op.toMap()..remove('op_id'),
    );
  }

  Future<void> deleteOp(int opId, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db;
    await db.delete(
      'outbox',
      where: 'op_id = ?',
      whereArgs: [opId],
    );
  }

  Future<void> updateOpFailure({
    required int opId,
    required int retryCount,
    required String error,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _db;
    await db.update(
      'outbox',
      {
        'retry_count': retryCount,
        'last_error': error,
      },
      where: 'op_id = ?',
      whereArgs: [opId],
    );
  }

  Future<void> deleteOpsForTodo(int todoId, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db;
    await db.delete(
      'outbox',
      where: 'todo_id = ?',
      whereArgs: [todoId],
    );
  }

  Future<void> rewriteTodoIdInOps({
    required int oldId,
    required int newId,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _db;
    await db.update(
      'outbox',
      {'todo_id': newId},
      where: 'todo_id = ?',
      whereArgs: [oldId],
    );
  }
}
