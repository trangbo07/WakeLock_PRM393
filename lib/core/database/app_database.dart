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
      version: 4,
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
        // v4 added the wake-flow tables (routine / photo / streak backbone).
        if (oldV < 4) await _createWakeFlowTables(db);
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
    await _createWakeFlowTables(db);
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

  /// Tables backing the wake-flow (Ring → Mission → Routine → Photo → Streak).
  /// Timestamps are epoch milliseconds (INTEGER); booleans are INTEGER 0/1;
  /// per-item config is JSON TEXT. No cross-table FKs are enforced (an alarm or
  /// routine may be deleted while its history rows remain, by design).
  static Future<void> _createWakeFlowTables(Database db) async {
    // One row per alarm firing — the source of truth for streak/stats.
    // wake_success = mission_completed && routine_completed && photo_posted
    // within the allowed window (computed by the streak feature, stored here).
    await db.execute('''
      CREATE TABLE ${AppConstants.wakeEventsTable} (
        id                TEXT PRIMARY KEY,
        alarm_id          TEXT,
        fired_at          INTEGER NOT NULL,
        dismissed_at      INTEGER,
        mission_completed INTEGER NOT NULL DEFAULT 0,
        routine_completed INTEGER NOT NULL DEFAULT 0,
        photo_posted      INTEGER NOT NULL DEFAULT 0,
        wake_success      INTEGER NOT NULL DEFAULT 0,
        snooze_count      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // A named, reorderable list of steps run after the alarm is dismissed.
    await db.execute('''
      CREATE TABLE ${AppConstants.morningRoutinesTable} (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL DEFAULT '',
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    // type: water/teeth/stretch/meditate/journal/tasks/pomodoro.
    // `position` = display order (avoid the SQL reserved word `order`).
    await db.execute('''
      CREATE TABLE ${AppConstants.routineStepsTable} (
        id               TEXT PRIMARY KEY,
        routine_id       TEXT NOT NULL,
        type             TEXT NOT NULL,
        position         INTEGER NOT NULL DEFAULT 0,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        config           TEXT NOT NULL DEFAULT '{}'
      )
    ''');

    // Execution history of a routine run (for completion statistics).
    await db.execute('''
      CREATE TABLE ${AppConstants.routineRunsTable} (
        id           TEXT PRIMARY KEY,
        routine_id   TEXT NOT NULL,
        started_at   INTEGER NOT NULL,
        completed_at INTEGER,
        steps_done   INTEGER NOT NULL DEFAULT 0,
        steps_total  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Locally-captured morning photos. `posted`/`remote_id` track upload to the
    // cloud feed later; privacy: private/friends/close/selected.
    await db.execute('''
      CREATE TABLE ${AppConstants.morningPhotosTable} (
        id         TEXT PRIMARY KEY,
        path       TEXT NOT NULL,
        caption    TEXT NOT NULL DEFAULT '',
        mood       TEXT,
        weather    TEXT,
        wake_time  INTEGER,
        alarm_time INTEGER,
        privacy    TEXT NOT NULL DEFAULT 'private',
        posted     INTEGER NOT NULL DEFAULT 0,
        remote_id  TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  /// Close and reset the connection (tests / teardown).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
