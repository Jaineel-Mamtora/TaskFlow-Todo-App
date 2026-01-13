import 'package:todo_api/todo_api.dart';

/// TodoRow is the DB-facing model that represents a raw row from the
/// todos table, including fields the domain Todo doesn’t carry (like
/// pending_sync, deleted, updated_at). It exists so the DAO can:
///
/// Parse SQLite rows into a structured object, then map to Todo with toTodo().
/// Preserve local-only metadata (pending/deleted) when deciding what to upsert
/// or skip during refresh/sync.

class TodoRow {
  const TodoRow({
    required this.id,
    required this.title,
    required this.completed,
    required this.pendingSync,
    required this.deleted,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final bool completed;
  final bool pendingSync;
  final bool deleted;
  final int updatedAt;

  Todo toTodo() {
    return Todo(
      id: id,
      title: title,
      completed: completed,
      pendingSync: pendingSync,
    );
  }

  static TodoRow fromMap(Map<String, Object?> map) {
    return TodoRow(
      id: map['id'] as int,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
      pendingSync: (map['pending_sync'] as int) == 1,
      deleted: (map['deleted'] as int) == 1,
      updatedAt: map['updated_at'] as int,
    );
  }
}
