import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import '../models/helmet_event_record.dart';
import 'database_service.dart';

/// SQLite storage adapter using the official sqflite plugin for Android / iOS.
class SqfliteStorageAdapter implements DatabaseStorageAdapter {
  static const String _dbName = 'smart_helmet_events.db';
  static const int _dbVersion = 1;
  static const String tableEvents = 'helmet_events';

  sqflite.Database? _db;

  @override
  Future<bool> init() async {
    try {
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = p.join(dbPath, _dbName);

      _db = await sqflite.openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableEvents (
              id TEXT PRIMARY KEY,
              timestamp TEXT NOT NULL,
              event_type TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              severity TEXT NOT NULL,
              is_demo INTEGER NOT NULL DEFAULT 0,
              latitude REAL,
              longitude REAL,
              speed_kmh REAL,
              alcohol_ppm REAL,
              g_force REAL,
              status TEXT,
              metadata TEXT
            )
          ''');
          await db.execute('CREATE INDEX idx_events_timestamp ON $tableEvents (timestamp DESC)');
          await db.execute('CREATE INDEX idx_events_type ON $tableEvents (event_type)');
          await db.execute('CREATE INDEX idx_events_demo ON $tableEvents (is_demo)');
        },
      );
      return true;
    } catch (e) {
      print('[SqfliteAdapter] Initialization failed: $e');
      return false;
    }
  }

  @override
  Future<int> insert(HelmetEventRecord event) async {
    if (_db == null) return 0;
    return await _db!.insert(
      tableEvents,
      event.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<HelmetEventRecord>> query({
    HelmetEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDemoOnly,
    String? searchQuery,
    int limit = 200,
    int offset = 0,
  }) async {
    if (_db == null) return [];

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (eventType != null) {
      whereClauses.add('event_type = ?');
      whereArgs.add(eventType.name);
    }
    if (startDate != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (isDemoOnly != null) {
      whereClauses.add('is_demo = ?');
      whereArgs.add(isDemoOnly ? 1 : 0);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR description LIKE ? OR status LIKE ?)');
      final queryPattern = '%${searchQuery.trim()}%';
      whereArgs.addAll([queryPattern, queryPattern, queryPattern]);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await _db!.query(
      tableEvents,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((row) => HelmetEventRecord.fromMap(row)).toList();
  }

  @override
  Future<int> count() async {
    if (_db == null) return 0;
    final result = await _db!.rawQuery('SELECT COUNT(*) as count FROM $tableEvents');
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> delete(String id) async {
    if (_db == null) return 0;
    return await _db!.delete(
      tableEvents,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> clear({bool demoOnly = false}) async {
    if (_db == null) return 0;
    if (demoOnly) {
      return await _db!.delete(
        tableEvents,
        where: 'is_demo = ?',
        whereArgs: [1],
      );
    } else {
      return await _db!.delete(tableEvents);
    }
  }

  @override
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
