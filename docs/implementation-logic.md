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

**Code (native ring):** `android/.../AlarmSoundService.kt`, `AlarmReceiver.kt`,
`SystemRingtones.kt`; `features/alarm_ringing/data/alarm_fire_handler.dart`;
`AlarmRingingPage`; `app/app.dart`.

Luồng end-to-end khi tới giờ:
1. AndroidAlarmManager chạy `alarmFireHandler(firedIntId)` trong **isolate nền**.
   Đọc alarm từ SQLite; map id bằng `findByFiredId`.
2. One-shot → tự tắt; lặp → schedule occurrence kế tiếp ngay.
3. **Broadcast** intent `...action.RING` (kèm soundUri/escalate/label/alarmId) tới
   `AlarmReceiver` bằng `android_intent_plus` (isolate nền gửi broadcast được;
   không start service trực tiếp được).
4. `AlarmReceiver` → `startForegroundService(AlarmSoundService)`.
5. **`AlarmSoundService` (foreground service native) PHÁT NHẠC LẶP** bằng
   `SystemRingtones.startAlarm` (`Ringtone.isLooping = true`, STREAM_ALARM,
   escalate volume). Đây là mấu chốt: lặp bền vững, độc lập UI → tự kêu + kêu
   mãi tới khi tắt. Service post thông báo `ongoing` + full-screen intent.
6. Full-screen intent → `MainActivity` (kèm `alarmId` extra). `app.dart` đọc
   `consumeLaunchAlarmId` (lúc mở + mỗi khi resumed) → push `AlarmRingingPage`.
7. `AlarmRingingPage` là UI dismiss: `PopScope(canPop:false)`, volume lock + giữ
   màn sáng/đè keyguard (window flags qua kênh volume). Hoàn thành nhiệm vụ →
   `stopRinging` (dừng service) + unlock. Rời màn hình mà chưa xong → service VẪN
   kêu (escape-proof, không phụ thuộc UI).

Nhạc hệ thống (content://) VÀ file tùy chỉnh (đường dẫn app-private) đều phát
được vì service chạy trong process app (đọc được file riêng). `'default'` resolve
sang URI cụ thể lúc LƯU (`defaultAlarmUri`).

**Tại sao không dùng notification sound / FLAG_INSISTENT:** INSISTENT lặp không
đáng tin (dừng khi full-screen intent mở activity → "kêu 1 lần"). Foreground
service + `Ringtone.isLooping` lặp chắc chắn. `flutter_local_notifications` đã gỡ.

**Quyết định/gotcha:**
- **Callback truyền từ ngoài vào scheduler:** `AlarmScheduler.scheduleOneShot`
  nhận `callback` param thay vì import handler — giữ `core/` không phụ thuộc
  `features/`. Callback phải là top-level + `@pragma('vm:entry-point')`.
- **android_intent_plus** là pub plugin → tự đăng ký ở engine isolate nền (kênh
  native tự viết thì KHÔNG), nên là cách gọi sang native từ isolate nền.
- **Teardown fire-and-forget:** `_attemptDismiss` pop màn hình NGAY, không
  `await` teardown (stop nhạc/unlock/cancel notif). Lý do: (1) UX đóng tức thì;
  (2) trong widget test các Future MethodChannel không resolve trong
  `pumpAndSettle` → nếu await sẽ không bao giờ pop. `ref` được đọc trước khi pop
  (còn valid), phần async chạy sau. `dispose()` cũng dispose player.
- Mọi lời gọi platform (audio/notif/volume) đều bọc try/catch — thiếu plugin
  (test host) hoặc native lỗi không được làm kẹt người dùng trên màn hình reo.
- flutter_local_notifications v22 dùng **named params** (`initialize(settings:)`,
  `show(id:title:body:notificationDetails:)`, `cancel(id:)`) — khác v9 cũ.

## Nhạc chuông (hệ thống + tự tải lên)

**Code:** `android/.../SystemRingtones.kt`, `core/platform/system_ringtone_channel.dart`,
`features/ringtone/*`

KHÔNG nhúng audio nào trong app (tránh bản quyền). Hai nguồn:
1. **Nhạc hệ thống Android thật:** native `SystemRingtones` (RingtoneManager,
   TYPE_ALARM) liệt kê âm báo thức có sẵn trên máy (Argon, Cesium, ...).
   `"default"` là sentinel = âm báo thức mặc định hệ thống. Channel
   `wakelock/ringtones`: `list` / `preview(uri)` / `stopPreview` /
   `startAlarm(uri,escalate)` / `stopAlarm`.
2. **Nhạc người dùng tự tải:** nút "Thêm nhạc" trong picker → `file_picker`
   (SAF audio) → copy file vào `<appDocs>/ringtones/` (path_provider) → lưu
   metadata bảng SQLite `custom_ringtones` (schema v2). `uri` = đường dẫn file
   tuyệt đối. Xóa được (xóa row + file).

`alarm.ringtoneId` lưu chính `uri` (content:// hoặc đường dẫn file hoặc
`"default"`). Native `resolve()`: `"default"`/rỗng → default alarm URI; bắt đầu
`/` → `Uri.fromFile`; còn lại → `Uri.parse`.

**Phát khi reo:** `AlarmRingingPage` gọi `startAlarm(uri, escalate)` — native
`Ringtone` loop trên STREAM_ALARM; escalate = ramp volume 30%→max mỗi 3s.
Không dùng audioplayers nữa (đã gỡ dependency).

**Nghe thử (preview):** picker gọi native `preview`/`stopPreview`. Channel
reference được capture ở initState (`late final _channel`) để `dispose()` gọi
được mà không đụng `ref` lúc widget bị finalize (Riverpod cấm — từng gây
StateError). Nhận `selectedId` qua route argument để hiện dấu ✓ (nhạc hệ thống)
hoặc nút xóa (nhạc tự tải).

**Gotcha build:** `file_picker` compile với android-34 nhưng dependency khác cần
36 → override `compileSdk=36` cho mọi library subproject trong
`android/build.gradle.kts` (đăng ký `afterEvaluate` TRƯỚC block
`evaluationDependsOn` để không lỗi "already evaluated").

## 4. Nhiệm vụ tắt báo thức

**Code:** `features/task/presentation/tasks/*`, `features/task/domain/*`

`DismissTaskConfig` (type + difficulty/shakeCount/photoTag) lưu JSON cột
`dismiss_task`. UI chọn ở `DismissTaskSelector`. `TaskRunnerPage` dispatch theo
type; mỗi task page pop `TaskResult(completed: bool)`. Toàn bộ task page có
`automaticallyImplyLeading: false` (không cho thoát bằng nút back của AppBar).

3 nhiệm vụ: toán / lắc / ảnh (QR đã gỡ theo yêu cầu 2026-07-12 — bỏ luôn
`mobile_scanner`).

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
- **Ảnh (`photo_task_page`):** `image_picker` `pickImage(source: camera)` →
  nhận diện vật thể bằng Gemini (xem mục 8). Hủy/không có camera → chụp lại.

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
- **Foreground service (chống-kill + phát nhạc):** giờ là `AlarmSoundService`
  native (mục 3) — vừa giữ process sống vừa phát nhạc lặp, chạy khi báo thức reo.
  (`flutter_foreground_task`/`ForegroundServiceController` còn init trong bootstrap
  nhưng không còn dùng cho luồng reo — `AlarmSoundService` thay thế.)
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

## 8. Nhận diện vật thể (Gemini) cho nhiệm vụ chụp ảnh

**Code:** `features/task/data/gemini_vision_service.dart`,
`features/task/presentation/tasks/photo_task_page.dart`, `core/config/env.dart`

- Chụp ảnh (`image_picker`) → đọc bytes → `GeminiVisionService.matchesLabel`
  gửi ảnh (base64 inline) + prompt tới Gemini REST
  (`v1beta/models/gemini-3.1-flash-lite:generateContent`), hỏi ảnh có `photoTag`
  không, ép trả lời YES/NO. Chứa "yes" → đạt; "no" → hiện lỗi + chụp lại.
- **API key:** đọc từ `.env` (`GEMINI_API_KEY`) qua `flutter_dotenv` — file
  `.env` GIT-IGNORED, KHÔNG commit key. `.env.example` là template. Model id để
  ở 1 hằng `_defaultModel`, đổi 1 chỗ nếu API từ chối.
- **Fail-open:** không có key / lỗi mạng / HTTP != 200 → coi như đạt (accept),
  để sự cố hạ tầng không nhốt người dùng lúc 6h sáng. Chỉ "NO" rõ ràng mới chặn.
- Không có `photoTag` → bỏ qua kiểm tra, ảnh nào cũng đạt.
- Cần quyền INTERNET (đã khai báo trong Manifest).

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
