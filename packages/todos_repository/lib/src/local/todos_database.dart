import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class TodosDatabase {
  TodosDatabase({String? databaseName})
    : _databaseName = databaseName ?? 'taskflow_todos.db';

  final String _databaseName;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);

    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
    );

    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE outbox (
        op_id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE id_map (
        local_id INTEGER PRIMARY KEY,
        server_id INTEGER NOT NULL
      );
    ''');
  }
}
