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

  /// Wrap an already-open [Database] (integration tests use an in-memory ffi
  /// database created with [createSchema]).
  factory AppDatabase.withDatabase(Database db) => AppDatabase._().._db = db;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), AppConstants.databaseFile);
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, _) => createSchema(db),
      onUpgrade: (db, oldV, _) async {
        // v2 added the custom_ringtones table.
        if (oldV < 2) await _createCustomRingtones(db);
        // v3 added the flashlight (flashbang) column.
        if (oldV < 3) {
          await db.execute(
            'ALTER TABLE ${AppConstants.alarmsTable} '
            'ADD COLUMN flashlight INTEGER NOT NULL DEFAULT 1',
          );
        }
      },
    );
  }

  /// Create all tables. Single source of the schema — reused by tests.
  /// Booleans are stored as INTEGER 0/1; list/object fields as JSON TEXT.
  /// repeat_days: JSON int list, 1=Mon .. 7=Sun (DateTime.weekday values).
  static Future<void> createSchema(Database db) async {
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
        flashlight      INTEGER NOT NULL DEFAULT 1,
        dismiss_task    TEXT NOT NULL
      )
    ''');
    await _createCustomRingtones(db);
  }

  /// User-added ringtones: `uri` is the absolute path of the copied audio file.
  static Future<void> _createCustomRingtones(Database db) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.customRingtonesTable} (
        uri  TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  /// Close and reset the connection (tests / teardown).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
