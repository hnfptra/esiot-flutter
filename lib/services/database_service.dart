import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/sensor_data.dart';

class DatabaseService {
  Database? _database;

  Future<void> initialize() async {
    if (_database != null) return;
    final databasePath = path.join(await getDatabasesPath(), 'iot_monitor.db');
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sensor_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            temperature REAL NOT NULL,
            humidity REAL NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_sensor_history_timestamp ON sensor_history(timestamp)',
        );
      },
    );
    await _database!.delete(
      'sensor_history',
      where: 'timestamp < ?',
      whereArgs: [
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String()
      ],
    );
  }

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('DatabaseService.initialize() must be called first.');
    }
    return database;
  }

  Future<void> insert(SensorData data) async {
    await _db.insert('sensor_history', data.toMap());
  }

  Future<List<SensorData>> latest({int limit = 100}) async {
    final rows = await _db.query(
      'sensor_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(SensorData.fromMap).toList().reversed.toList();
  }

  Future<List<SensorData>> since(DateTime start) async {
    final rows = await _db.query(
      'sensor_history',
      where: 'timestamp >= ?',
      whereArgs: [start.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return rows.map(SensorData.fromMap).toList();
  }

  Future<void> clear() async {
    await _db.delete('sensor_history');
  }
}
