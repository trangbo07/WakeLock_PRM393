# System Architecture — WakeLock

## Tổng quan

Feature-first + Clean Architecture. Mỗi feature tự chứa 3 lớp:

- **domain** — entity thuần Dart + interface repository (không phụ thuộc Flutter/sqflite).
- **data** — model (map SQLite row), datasource (SQLite CRUD / kênh native), impl repository.
- **presentation** — Riverpod provider + page + widget.

`core/` giữ code dùng chung; `app/` giữ MaterialApp/theme/router. Toàn bộ dữ liệu
nằm trên máy (SQLite), không backend/sync.

## Luồng dữ liệu báo thức

```
AlarmEditPage → alarmRepositoryProvider (Riverpod)
             → LocalAlarmRepository
                 └─ AlarmLocalDataSource → SQLite `wakelock.db` (bảng alarms)  [nguồn sự thật duy nhất]
             → AlarmScheduler.scheduleOneShot()  (android_alarm_manager_plus)
```

Repository đồng bộ persist ↔ schedule: mỗi lần lưu/bật/tắt/xóa đều (re)schedule
occurrence kế tiếp hoặc cancel. Id int cho AlarmManager = FNV-1a từ UUID
(`AlarmScheduler.stableId`, ổn định qua restart/update). Lưu bị chặn nếu thiếu
quyền exact alarm Android 12+ (`core/platform/exact_alarm_permission.dart`).
`ringtoneId` được resolve 'default' → URI hệ thống cụ thể lúc lưu.

Bộ lập lịch chạy trong **isolate nền** lúc báo thức kêu (thường không có mạng)
đọc thẳng SQLite — sqflite mở được từ isolate nền an toàn.

## Luồng báo thức kêu (hardcore) — service native

```
[Đến giờ] AndroidAlarmManager → alarmFireHandler(id)  (isolate nền)
   1. đọc alarm từ SQLite; one-shot → tự tắt; lặp → schedule occurrence kế
   2. broadcast RING (android_intent_plus) → AlarmReceiver           [native]
[Native] AlarmReceiver → startForegroundService(AlarmSoundService)
   AlarmSoundService: phát nhạc LOOP (Ringtone.isLooping, STREAM_ALARM,
     tăng dần âm lượng) + thông báo ongoing full-screen intent → MainActivity
[App]  app.dart hỏi `currentRingingAlarmId` (lúc mở + resume) → mở AlarmRingingPage
   AlarmRingingPage: PopScope chặn Back + khóa volume + giữ màn sáng/đè keyguard
     → TaskRunnerPage(config) → math / shake / photo
     → TaskResult.success → stopRinging (stopService) → dừng nhạc
```

Nhạc do **service native** phát (không phải UI) nên reo tự động + lặp bền +
tiếp tục kêu dù rời app; chỉ dừng khi hoàn thành nhiệm vụ. Xóa thông báo cũng
không mất đường vào: mở lại app luôn quay về màn tắt báo thức khi service còn reo.

## Ranh giới native (Kotlin trong `android/.../`)

| Kênh / thành phần | Mục đích | Trạng thái |
|-----------|----------|-----------|
| `wakelock/volume` (MethodChannel) | Ghim max volume + nuốt phím volume + window flags (giữ màn/đè keyguard) | ✓ `MainActivity.kt` |
| `wakelock/ringtones` (MethodChannel) | Liệt kê/nghe thử nhạc hệ thống, `defaultAlarmUri`, `currentRingingAlarmId`, `stopRinging`, push `launchRinging` | ✓ `MainActivity` + `SystemRingtones.kt` |
| `AlarmReceiver` + `AlarmSoundService` | Nhận broadcast → foreground service phát nhạc loop + full-screen notification | ✓ |
| `android_alarm_manager_plus` | Lập lịch exact + reschedule sau reboot | ✓ |
| `android_intent_plus` | Cầu isolate-nền → broadcast tới `AlarmReceiver` | ✓ |
| `flutter_overlay_window` | KHÔNG dùng — full-screen intent đã đủ "đè màn khóa" | bỏ (YAGNI) |
| `flutter_foreground_task` | Init trong bootstrap nhưng không dùng cho reo (AlarmSoundService thay) | legacy |

## Nhạc chuông

Không nhúng audio (tránh bản quyền). Hai nguồn, cả hai phát bằng service native:

- **Nhạc hệ thống Android thật** — `SystemRingtones` (RingtoneManager, TYPE_ALARM)
  liệt kê âm báo thức có sẵn (Argon, Cesium, ...). `'default'` = âm mặc định hệ thống.
- **Nhạc người dùng tự tải** — nút "Thêm nhạc" → `file_picker` (audio) → copy vào
  `<appDocs>/ringtones/` (path_provider) → lưu bảng `custom_ringtones`.

Nghe thử ngay trong `RingtonePickerPage` (native preview). `alarm.ringtoneId` lưu
content:// URI, đường dẫn file, hoặc 'default'.

## Nhận diện vật thể (nhiệm vụ chụp ảnh)

`GeminiVisionService` gửi ảnh + tên vật thể tới Gemini
(`gemini-3.1-flash-lite`), chỉ tắt được khi ảnh đúng có vật thể. Fail-open (không
key / lỗi mạng → chấp nhận, tránh nhốt người dùng). Key đọc từ `.env`
(GEMINI_API_KEY, git-ignore, KHÔNG commit; xem `.env.example`).

## Schema SQLite (`AppDatabase`, version 2)

```sql
CREATE TABLE alarms (
  id              TEXT PRIMARY KEY,                    -- UUID string
  label           TEXT NOT NULL DEFAULT '',
  hour            INTEGER NOT NULL,                    -- 0..23
  minute          INTEGER NOT NULL,                    -- 0..59
  repeat_days     TEXT NOT NULL DEFAULT '[]',          -- JSON int list, 1=T2 .. 7=CN
  is_enabled      INTEGER NOT NULL DEFAULT 1,          -- bool 0/1
  ringtone_id     TEXT NOT NULL DEFAULT 'default',     -- content:// | file path | 'default'
  vibrate         INTEGER NOT NULL DEFAULT 1,
  volume_lock     INTEGER NOT NULL DEFAULT 1,
  escalate_volume INTEGER NOT NULL DEFAULT 1,
  dismiss_task    TEXT NOT NULL                        -- JSON DismissTaskConfig
);

-- version 2: nhạc người dùng tự tải (uri = đường dẫn file trong app storage)
CREATE TABLE custom_ringtones (
  uri  TEXT PRIMARY KEY,
  name TEXT NOT NULL
);
```

Mapping row ↔ entity ở `AlarmModel.fromDbRow/toDbRow`. Đổi schema → tăng version +
`onUpgrade` (v1→v2 tạo `custom_ringtones`, giữ nguyên alarms).

## Quyền Android (AndroidManifest.xml)

Exact alarm, wake lock, boot completed, foreground service (special use + media
playback), ignore battery optimization, system alert window, full-screen intent,
disable keyguard, post notifications, vibrate, modify audio settings, camera,
**INTERNET** (Gemini).

`MainActivity` đặt `showWhenLocked=true` + `turnScreenOn=true`; thêm window flags
khi reo. `minSdk = 23`, `compileSdk = 36` (pin, do dependency mới), core library
desugaring bật.
