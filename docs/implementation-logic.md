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

*(Phase 2 — sẽ cập nhật khi triển khai)*

## 4. Nhiệm vụ tắt báo thức

*(Phase 3 — sẽ cập nhật khi triển khai)*

**Đã có:** `DismissTaskConfig` (type + difficulty/shakeCount/qrPayload/photoTag),
lưu JSON trong cột `dismiss_task`. UI chọn ở `DismissTaskSelector`
(ChoiceChip + field điều kiện theo type). `TaskRunnerPage` dispatch theo type,
mỗi task page pop `TaskResult(completed: bool)`.

## 5. Hardcore (volume lock / overlay / foreground service)

*(Phase 4 — sẽ cập nhật khi triển khai)*

**Đã có:** wrapper Dart `VolumeLockChannel` (MethodChannel `wakelock/volume`,
native chưa viết), `OverlayService`, `ForegroundServiceController`.

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
