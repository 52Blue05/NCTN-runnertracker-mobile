import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../features/tracking/model/run_session_model.dart';

class LocalRunDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'runner_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            json_data TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Lưu buổi chạy vào local DB khi không có mạng
  Future<void> savePendingRun(RunSessionModel session) async {
    final db = await database;
    await db.insert('pending_runs', {
      'json_data': jsonEncode(session.toJson()),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Lấy tất cả buổi chạy chưa sync
  Future<List<RunSessionModel>> getPendingRuns() async {
    final db = await database;
    final rows = await db.query('pending_runs', orderBy: 'created_at ASC');
    return rows.map((row) {
      final json = jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
      return RunSessionModel.fromJson(json);
    }).toList();
  }

  /// Lấy danh sách ID + Model (để xóa sau khi sync)
  Future<List<Map<String, dynamic>>> getPendingRunsWithId() async {
    final db = await database;
    final rows = await db.query('pending_runs', orderBy: 'created_at ASC');
    return rows.map((row) {
      final json = jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
      return {
        'localId': row['id'],
        'model': RunSessionModel.fromJson(json),
      };
    }).toList();
  }

  /// Xóa buổi chạy đã sync thành công
  Future<void> deletePendingRun(int localId) async {
    final db = await database;
    await db.delete('pending_runs', where: 'id = ?', whereArgs: [localId]);
  }

  /// Đếm số buổi chạy chưa sync
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_runs');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
