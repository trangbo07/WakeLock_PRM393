# Implementation Logic — WakeLock

Sổ tay logic xử lý cho từng mảng tính năng. Mục đích: khi có bug, đọc mục tương
ứng để hiểu luồng + các quyết định/gotcha trước khi sửa. Cập nhật file này mỗi
khi thay đổi logic.

## 1. Lưu trữ (SQLite)

**Code:** `core/database/app_database.dart`, `features/alarm_management/data/*`

- `AppDatabase` singleton, lazy-open `wakelock.db`, 1 bảng `alarms`.
- Mapping ở `AlarmModel.fromDbRow/toDbRow`: bool ↔ INTEGER 0/1; `repeat_days`
  (Set<Weekday>) và `dismiss_task` (DismissTaskConfig) ↔ JSON TEXT.
- `repeat_days` dùng giá trị `DateTime.weekday` (1=T2 .. 7=CN) — so sánh trực
  tiếp được với `DateTime.now().weekday`, không cần convert.
- sqflite mở được từ isolate nền (mỗi isolate 1 connection riêng tới cùng file)
  — đây là lý do chọn SQLite thay SharedPreferences (cache cross-isolate stale).
- **Gotcha:** đổi schema phải tăng `version` trong `openDatabase` + viết
  `onUpgrade`; không có migration tool.

## 2. Lập lịch (exact alarm)

**Code:** `core/platform/alarm_scheduler.dart`,
`features/alarm_management/data/repositories/local_alarm_repository.dart`,
`core/utils/date_time_utils.dart`

- **Id ổn định:** AndroidAlarmManager cần int id; alarm dùng UUID string →
  `AlarmScheduler.stableId()` hash FNV-1a 32-bit, mask 31-bit dương.
  KHÔNG dùng `String.hashCode` (không đảm bảo ổn định giữa các phiên bản
  Dart VM → sau khi update app sẽ không cancel được alarm cũ).
- **Đồng bộ persist ↔ schedule:** mọi write đổi thời điểm/trạng thái reo đều đi
  qua `LocalAlarmRepository` → `_syncSchedule()`: enabled → `scheduleOneShot`
  occurrence kế tiếp (tính bằng `DateTimeUtils.nextOccurrence`); disabled/xóa
  → `cancel`. UI không bao giờ gọi scheduler trực tiếp.
- **Chỉ schedule 1 occurrence kế tiếp** (kể cả alarm lặp). Sau khi reo,
  `alarmCallback` chịu trách nhiệm schedule lần kế (xem mục 3).
- `nextOccurrence`: one-shot đã qua giờ → ngày mai; repeat → quét tối đa 8 ngày
  tìm ngày khớp `repeatDays` mà thời điểm còn ở tương lai.
- **Quyền:** Android 12+ cần SCHEDULE_EXACT_ALARM. `ensureExactAlarmPermission()`
  (`core/platform/exact_alarm_permission.dart`) check + request khi bấm Lưu;
  thiếu quyền thì chặn lưu (không lưu alarm sẽ không bao giờ reo đúng giờ).
  Trên non-Android (test host) trả `true` để test không đụng plugin.
- **Manifest:** `AlarmService` + `AlarmBroadcastReceiver` +
  `RebootBroadcastReceiver` bắt buộc khai báo trong AndroidManifest — thiếu là
  plugin âm thầm không chạy.
- **Gotcha:** `oneShotAt(..., rescheduleOnReboot: true)` chỉ hoạt động khi
  `RebootBroadcastReceiver` có `android:enabled="true"` trong manifest.

## 3. Luồng báo thức reo

**Code:** `features/alarm_ringing/data/alarm_fire_handler.dart`,
`core/platform/alarm_notification_service.dart`,
`features/alarm_ringing/presentation/pages/alarm_ringing_page.dart`,
`app/app.dart`

Luồng end-to-end khi tới giờ:
1. AndroidAlarmManager chạy `alarmFireHandler(firedIntId)` trong **isolate nền**
   (không có widget tree/Riverpod). Handler đọc alarm từ SQLite trực tiếp.
2. Map `firedIntId` → alarm bằng `findByFiredId` (quét `stableId` từng row —
   scheduler chỉ biết int id, không biết UUID).
3. One-shot → tự tắt (`setEnabled(false)`); lặp → schedule occurrence kế tiếp
   ngay (vì mỗi lần chỉ schedule 1 lần — xem mục 2).
4. Post notification full-screen intent (`AlarmNotificationService.showRinging`).
   Notification KHÔNG phát tiếng (`playSound: false`) — âm thanh do
   `RingtonePlayerService` ở isolate chính quản để task hoàn thành mới stop được.
5. Full-screen intent + `showWhenLocked`/`turnScreenOn` (MainActivity) mở app
   đè lên màn hình khóa. `app.dart` đọc `launchAlarmId()` lúc khởi động (hoặc
   `onAlarmTapped` khi app đang chạy) → push `AlarmRingingPage`.
6. `AlarmRingingPage` (isolate chính): phát nhạc + escalate + volume lock,
   `PopScope(canPop:false)` chặn Back. Chỉ đóng khi `TaskRunnerPage` trả
   `TaskResult.completed == true`.

**Quyết định/gotcha:**
- **Callback truyền từ ngoài vào scheduler:** `AlarmScheduler.scheduleOneShot`
  nhận `callback` param thay vì import handler — giữ `core/` không phụ thuộc
  `features/`. Callback phải là top-level + `@pragma('vm:entry-point')`.
- **Teardown fire-and-forget:** `_attemptDismiss` pop màn hình NGAY, không
  `await` teardown (stop nhạc/unlock/cancel notif). Lý do: (1) UX đóng tức thì;
  (2) trong widget test các Future MethodChannel không resolve trong
  `pumpAndSettle` → nếu await sẽ không bao giờ pop. `ref` được đọc trước khi pop
  (còn valid), phần async chạy sau. `dispose()` cũng dispose player.
- Mọi lời gọi platform (audio/notif/volume) đều bọc try/catch — thiếu plugin
  (test host) hoặc native lỗi không được làm kẹt người dùng trên màn hình reo.
- flutter_local_notifications v22 dùng **named params** (`initialize(settings:)`,
  `show(id:title:body:notificationDetails:)`, `cancel(id:)`) — khác v9 cũ.

## Nhạc chuông (assets)

**Code:** `features/ringtone/data/repositories/ringtone_repository_impl.dart`,
`assets/ringtones/*.wav`

14 file .wav tự sinh (22050Hz mono), loop liền mạch bằng `ReleaseMode.loop`.
Tất cả là giai điệu tổng hợp gốc (KHÔNG dùng nhạc bản quyền):
- Hiện đại/melodic: `marimba`, `melody`, `edm_pluck`, `lofi`, `arcade`,
  `bass_drop` — dùng envelope ADSR + harmonic decay (pluck/marimba/EDM).
- Cổ điển: `default` (beep 1kHz), `beep_slow`, `digital`, `chime`.
- Hardcore tần số cao (khó ngủ tiếp, `highFrequency: true`): `siren`,
  `nuclear`, `buzzer`, `pulse`.
`RingtonePlayerService` strip prefix `assets/` vì `AssetSource` tính path từ
gốc `assets/`. Script sinh lại (không commit — chỉ .wav commit):
`scratchpad/generate_alarm_ringtones.py` (tone cơ bản),
`scratchpad/generate_modern_ringtones.py` (tone hiện đại).

**Nghe thử (preview):** `RingtonePickerPage` (ConsumerStatefulWidget) giữ 1
`AudioPlayer` riêng cho preview; nút play/stop mỗi dòng toggle `_playingId`;
`onPlayerComplete` tự reset icon; chọn dòng → stop preview → pop id. Nhận
`selectedId` qua route argument để hiện dấu ✓.

## 4. Nhiệm vụ tắt báo thức

**Code:** `features/task/presentation/tasks/*`, `features/task/domain/*`

`DismissTaskConfig` (type + difficulty/shakeCount/qrPayload/photoTag) lưu JSON
cột `dismiss_task`. UI chọn ở `DismissTaskSelector`. `TaskRunnerPage` dispatch
theo type; mỗi task page pop `TaskResult(completed: bool)`. Toàn bộ task page có
`automaticallyImplyLeading: false` (không cho thoát bằng nút back của AppBar).

- **Toán (`math_task_page`):** giải `difficulty` phép liên tiếp (difficulty vừa
  là số câu vừa là độ khó). Logic sinh đề tách ra `MathProblemGenerator`
  (`domain/math_problem_generator.dart`) — nhận `Random` seed để test được;
  d1-2 cộng/trừ số nhỏ, d3+ thêm nhân + số lớn, trừ luôn ≥ 0. Sai đáp án chỉ
  hiện lỗi + không tiến, không fail báo thức.
- **Lắc (`shake_task_page`):** đếm shake qua `sensors_plus`
  `accelerometerEventStream`. Logic đếm tách ra `ShakeDetector`
  (`domain/shake_detector.dart`, pure, test bằng sample tổng hợp): 1 shake =
  magnitude vượt threshold 18 m/s² SAU khi đã lắng xuống dưới 60% threshold
  (re-arm) — tránh đếm nhiều lần cho 1 cú lắc. Đạt count → auto pop success.
- **QR (`qr_scan_task_page`):** `mobile_scanner` v7 (`MobileScanner(onDetect:)`,
  `capture.barcodes[].rawValue`). So khớp `qrPayload`; payload rỗng/null → mã
  bất kỳ cũng đạt. Sai mã → hiện hint, tiếp tục quét.
- **Ảnh (`photo_task_page`):** `image_picker` `pickImage(source: camera)`.
  Chụp được ảnh bất kỳ = đạt; `photoTag` chỉ là gợi ý (nhận diện vật thể
  on-device để tương lai). Hủy/không có camera → cho chụp lại.

## 5. Hardcore (volume lock / overlay / foreground service)

**Code:** `android/.../MainActivity.kt`, `core/platform/volume_lock_channel.dart`,
`core/platform/foreground_service.dart`, `features/settings/*`

- **Volume lock (native Kotlin):** `MainActivity` đăng ký MethodChannel
  `wakelock/volume`. `lockToMax` → set STREAM_ALARM về max + bật cờ
  `volumeLocked`. `unlock` → tắt cờ. `dispatchKeyEvent` nuốt phím VOLUME_UP/DOWN
  khi cờ bật (return true) và set lại max mỗi lần nhấn → không thể vặn nhỏ khi
  reo. Dart wrapper `VolumeLockChannel` gọi từ `AlarmRingingPage`.
- **Tăng dần âm lượng:** `RingtonePlayerService` (mục 3) — timer 5s tăng volume
  player 0.2→1.0. Kết hợp volume lock: người dùng không hạ được STREAM_ALARM.
- **Foreground service (chống-kill):** `ForegroundServiceController.init()` gọi
  1 lần trong `bootstrap()`; `start()` khi vào `AlarmRingingPage`, `stop()` lúc
  teardown. Chạy ở **isolate chính** (nơi có UI + nhạc), không phải isolate nền
  — vì đây là process cần giữ sống. serviceTypes: mediaPlayback + specialUse.
  Manifest phải khai báo `com.pravera.flutter_foreground_task.service.ForegroundService`
  (đúng tên) + `<property PROPERTY_SPECIAL_USE_FGS_SUBTYPE>` cho Android 14+.
- **Overlay:** quyết định KHÔNG dùng overlay window song song. "Đè màn hình khóa"
  đã đạt bằng full-screen intent + `showWhenLocked`/`turnScreenOn` (mục 3) —
  overlay engine riêng + message channel để đồng bộ task state là thừa (YAGNI).
  Quyền SYSTEM_ALERT_WINDOW vẫn xin trong Settings để dự phòng. `OverlayService`
  giữ nguyên nhưng chưa dùng trong luồng chính.
- **Settings/permissions:** `AppPermission` enum (title + mô tả +
  `permission_handler` Permission) là nguồn duy nhất danh sách quyền hardcore.
  `SettingsPage` hiện trạng thái grant trực tiếp + nút cấp quyền, tự re-check khi
  app resume (quay lại từ màn hình system settings).

## 6. Form sửa báo thức (AlarmEditPage)

**Code:** `features/alarm_management/presentation/pages/alarm_edit_page.dart`,
`widgets/dismiss_task_selector.dart`

- State là 1 `Alarm _draft` immutable, mọi thay đổi qua `copyWith` — alarm mới
  tạo id bằng `Uuid().v4()` ngay từ đầu, save/update đều là `upsertAlarm`
  (INSERT OR REPLACE), không phân nhánh create/update.
- Router: mở qua route `/alarm-edit`, truyền `Alarm` qua `settings.arguments`
  để sửa, `null` để tạo mới.
- Nhạc chuông: mở `RingtonePickerPage` (route `/ringtones`), nhận ringtone id
  từ `Navigator.pop(context, r.id)`.
- Sau save/delete pop `true`; list page `await` push xong luôn
  `ref.invalidate(alarmListProvider)` để refresh.
- **Gotcha test:** form dài hơn viewport mặc định của widget test (600px) —
  test phải set `tester.view.physicalSize` cao hoặc `ensureVisible` trước khi
  tap nút Lưu.

## 7. Test tích hợp

**Code:** `test/alarm_repository_integration_test.dart`

- Dùng `sqflite_common_ffi` (dev dependency) chạy SQLite **thật in-memory** trên
  máy dev, không cần emulator. `sqfliteFfiInit()` + `databaseFactoryFfi`.
- Schema dùng chung qua `AppDatabase.createSchema(db)` (single source) +
  `AppDatabase.withDatabase(db)` bọc DB đã mở cho `AlarmLocalDataSource`.
- Scheduler được fake bằng subclass `AlarmScheduler` override
  `scheduleOneShot`/`cancel` (ghi lại call, không đụng AndroidAlarmManager) —
  không cần tách interface.
- Cover: upsert persist + schedule; disable → cancel giữ row; re-enable →
  schedule lại; delete → xóa + cancel; upsert 2 lần → update in-place (không
  nhân đôi row, nhờ `ConflictAlgorithm.replace`).
