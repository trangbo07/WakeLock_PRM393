# System Architecture — WakeLock

## Tổng quan

Feature-first + Clean Architecture. Mỗi feature tự chứa 3 lớp:

- **domain** — entity thuần Dart + interface repository (không phụ thuộc Flutter/sqflite).
- **data** — model (map SQLite row), datasource (SQLite CRUD), impl repository.
- **presentation** — Riverpod provider + page + widget.

`core/` giữ code dùng chung; `app/` giữ MaterialApp/theme/router.

## Luồng dữ liệu báo thức

```
AlarmEditPage → alarmRepositoryProvider (Riverpod)
             → LocalAlarmRepository
                 └─ AlarmLocalDataSource → SQLite `wakelock.db` (bảng alarms)  [nguồn sự thật duy nhất]
             → AlarmScheduler.scheduleOneShot()  (android_alarm_manager_plus)
```

Toàn bộ dữ liệu nằm trên máy (`AppDatabase` — core/database/app_database.dart).
Không có backend/sync: báo thức gắn với thiết bị, và bộ lập lịch chạy trong
**isolate nền** lúc báo thức kêu (thường không có mạng) đọc thẳng SQLite —
sqflite mở được từ isolate nền an toàn.

DB được seed 3 báo thức demo khi tạo lần đầu (gỡ khi `AlarmEditPage` có form thật).

## Luồng báo thức kêu (hardcore)

```
[Đến giờ] AndroidAlarmManager → alarmCallback(id)  (isolate nền)
   1. ForegroundServiceController.start()   → notification bền, chống bị kill
   2. OverlayService.showRinging()          → overlay đè lên màn hình khóa
   3. RingtonePlayerService.play(escalate)  → phát nhạc, tăng dần âm lượng
   4. VolumeLockChannel.lockToMax()         → chặn phím giảm âm lượng (native)
[Người dùng] AlarmRingingPage (PopScope chặn Back)
   → TaskRunnerPage(config) → math/shake/qr/photo
   → TaskResult.success → dừng nhạc + service + overlay
```

## Ranh giới native (cần code Kotlin trong `MainActivity.kt`)

| Kênh / API | Mục đích | Trạng thái |
|-----------|----------|-----------|
| `wakelock/volume` (MethodChannel) | Ghim max volume + nuốt phím volume-down | **Chưa viết native** |
| `flutter_overlay_window` | Vẽ overlay trên lock screen | Plugin có sẵn, cần cấp quyền SYSTEM_ALERT_WINDOW |
| `flutter_foreground_task` | Service chống tắt ngầm | Cần `init(...)` config trong bootstrap |
| `android_alarm_manager_plus` | Lập lịch chính xác | Cần gọi `AndroidAlarmManager.initialize()` |

## Schema SQLite (bảng `alarms` — tạo trong `AppDatabase._onCreate`)

```sql
CREATE TABLE alarms (
  id              TEXT PRIMARY KEY,                    -- UUID string
  label           TEXT NOT NULL DEFAULT '',
  hour            INTEGER NOT NULL,                    -- 0..23
  minute          INTEGER NOT NULL,                    -- 0..59
  repeat_days     TEXT NOT NULL DEFAULT '[]',          -- JSON int list, 1=T2 .. 7=CN
  is_enabled      INTEGER NOT NULL DEFAULT 1,          -- bool 0/1
  ringtone_id     TEXT NOT NULL DEFAULT 'default',
  vibrate         INTEGER NOT NULL DEFAULT 1,
  volume_lock     INTEGER NOT NULL DEFAULT 1,
  escalate_volume INTEGER NOT NULL DEFAULT 1,
  dismiss_task    TEXT NOT NULL                        -- JSON DismissTaskConfig
);
```

Mapping row ↔ entity nằm ở `AlarmModel.fromDbRow/toDbRow` (bool ↔ INTEGER,
list/object ↔ JSON TEXT). Nâng version + migration trong `openDatabase` khi đổi schema.

## Quyền Android (đã khai báo trong AndroidManifest.xml)

Exact alarm, wake lock, boot completed, foreground service (special use + media
playback), ignore battery optimization, system alert window, full-screen intent,
disable keyguard, post notifications, vibrate, modify audio settings, camera.

`MainActivity` đặt `showWhenLocked=true` + `turnScreenOn=true`. `minSdk = 23`,
bật core library desugaring cho `flutter_local_notifications`.
