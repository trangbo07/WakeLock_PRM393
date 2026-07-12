# Migrate Supabase → SQLite (local-only storage)

## Context
- User decision (2026-07-12): alarms lưu hoàn toàn trên máy bằng SQLite (`sqflite`), bỏ Supabase/auth/.env.
- Rationale: alarm app là offline-first; isolate nền phải đọc config không mạng; cloud sync không có giá trị thật cho báo thức; đổi lúc này rẻ nhất (bảng Supabase chưa tạo, UI chỉ gọi qua `AlarmRepository` interface).
- Giữ demo data (3 alarm mẫu) bằng seed khi tạo DB lần đầu — vì `AlarmEditPage` chưa có form, cần data để xem UI (bảo toàn ý định "offline demo mode" từ commit 1c10aad).

## Status: ✅ Done

## Changes

### Dependencies (pubspec.yaml)
- Remove: `supabase_flutter`, `flutter_dotenv`, `shared_preferences` (hết chỗ dùng)
- Add: `sqflite`, `path`
- Remove asset `- .env`

### New files
- `lib/core/database/app_database.dart` — singleton mở `wakelock.db`, DDL bảng `alarms`, seed 3 demo alarm khi onCreate
- `lib/features/alarm_management/data/datasources/alarm_local_datasource.dart` — CRUD SQLite
- `lib/features/alarm_management/data/repositories/local_alarm_repository.dart` — impl `AlarmRepository`, giữ TODO nối AlarmScheduler

### Deleted
- `lib/features/auth/**` (3 file — auth ẩn danh chỉ phục vụ RLS Supabase)
- `lib/features/alarm_management/data/datasources/alarm_remote_datasource.dart`
- `lib/features/alarm_management/data/datasources/alarm_local_cache_datasource.dart`
- `lib/features/alarm_management/data/repositories/alarm_repository_impl.dart`
- `lib/features/alarm_management/data/repositories/in_memory_alarm_repository.dart` (thay bằng DB seed)
- `lib/core/config/env.dart`, `.env.example` (`.env` local để nguyên — user tự xóa)

### Updated
- `alarm_model.dart`: `fromJson/toJson` → `fromDbRow/toDbRow` (bool↔INTEGER, list/map↔JSON TEXT)
- `core_providers.dart`: `supabaseClientProvider` → `appDatabaseProvider`
- `alarm_providers.dart`: bỏ nhánh Env/in-memory, wire `LocalAlarmRepository`
- `bootstrap.dart`: bỏ dotenv+Supabase, pre-open DB (fail-fast + log)
- `failures.dart`: bỏ `RemoteFailure`, `CacheFailure` → `DatabaseFailure` (chưa nơi nào dùng)
- `app_constants.dart`: bỏ `cachedAlarmsKey`, thêm `databaseFile`
- Comment refs Supabase: `alarm_repository.dart`, `settings_page.dart`, `ringtone_repository_impl.dart`, `widget_test.dart`
- Docs: README.md (stack, run steps, tree), `docs/system-architecture.md` (data flow + SQLite DDL), `docs/development-roadmap.md` (Phase 1 bỏ Supabase items)

## Success criteria
- `flutter pub get` OK, `dart analyze lib test` sạch, `flutter test` xanh
- App chạy không cần cấu hình gì, list hiện 3 demo alarm, toggle persist qua restart

## Unresolved questions
- PRM393 rubric có yêu cầu backend/cloud không? User đã quyết local SQLite — nếu sau này rubric yêu cầu, thêm layer sync riêng, không đảo lại kiến trúc này.
