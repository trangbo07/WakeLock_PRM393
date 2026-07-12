import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Lazily-opened singleton SQLite database — the single source of truth for
/// alarms. Everything lives on-device so the background alarm isolate can read
/// alarm config with no network (critical at 6 AM with WiFi off).
///
/// sqflite is safe to open from both the main app and the background isolate;
/// each isolate gets its own connection to the same file.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), AppConstants.databaseFile);
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Booleans are stored as INTEGER 0/1; list/object fields as JSON TEXT.
    // repeat_days: JSON int list, 1=Mon .. 7=Sun (DateTime.weekday values).
    await db.execute('''
      CREATE TABLE ${AppConstants.alarmsTable} (
        id              TEXT PRIMARY KEY,
        label           TEXT NOT NULL DEFAULT '',
        hour            INTEGER NOT NULL,
        minute          INTEGER NOT NULL,
        repeat_days     TEXT NOT NULL DEFAULT '[]',
        is_enabled      INTEGER NOT NULL DEFAULT 1,
        ringtone_id     TEXT NOT NULL DEFAULT 'default',
        vibrate         INTEGER NOT NULL DEFAULT 1,
        volume_lock     INTEGER NOT NULL DEFAULT 1,
        escalate_volume INTEGER NOT NULL DEFAULT 1,
        dismiss_task    TEXT NOT NULL
      )
    ''');
    await _seedDemoAlarms(db);
  }

  /// Seed data so the alarm list is viewable before AlarmEditPage has a real
  /// form. Remove once creating alarms in-app works.
  Future<void> _seedDemoAlarms(Database db) async {
    final rows = <Map<String, Object?>>[
      {
        'id': '1',
        'label': 'Dậy đi học',
        'hour': 6,
        'minute': 30,
        'repeat_days': jsonEncode([1, 2, 3, 4, 5]),
        'is_enabled': 1,
        'ringtone_id': 'siren',
        'dismiss_task': jsonEncode({'type': 'math', 'difficulty': 3}),
      },
      {
        'id': '2',
        'label': 'Uống nước',
        'hour': 9,
        'minute': 0,
        'repeat_days': jsonEncode(<int>[]),
        'is_enabled': 0,
        'ringtone_id': 'default',
        'dismiss_task': jsonEncode({'type': 'shake', 'shake_count': 50}),
      },
      {
        'id': '3',
        'label': 'Ngủ trưa dậy',
        'hour': 13,
        'minute': 15,
        'repeat_days': jsonEncode([6, 7]),
        'is_enabled': 1,
        'ringtone_id': 'nuclear',
        'dismiss_task': jsonEncode({'type': 'qrScan', 'qr_payload': 'bathroom'}),
      },
    ];
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(AppConstants.alarmsTable, row);
    }
    await batch.commit(noResult: true);
  }

  /// Close and reset the connection (tests / teardown).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
