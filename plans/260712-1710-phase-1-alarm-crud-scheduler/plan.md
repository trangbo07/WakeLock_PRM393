# Phase 1 — Quản lý báo thức (CRUD + lập lịch thật)

## Status: ✅ Done (2026-07-12) — `dart analyze` sạch, 11/11 test xanh, `flutter build apk --debug` OK

## Context

WakeLock (Flutter, Android-only) vừa chuyển xong sang SQLite local-only (commit `fd99bb4`). Phase 1 của roadmap còn 3 mục: hoàn thiện form `AlarmEditPage`, đồng bộ bật/tắt/xóa với scheduler, gỡ seed demo. Hiện `AlarmEditPage` là stub TODO, `alarmCallback` chưa được lập lịch, DB còn seed 3 alarm mẫu.

**Quyết định đã chốt với user:**
1. Wire scheduler đầy đủ trong Phase 1: `AndroidAlarmManager.initialize()` + schedule/cancel khi lưu/bật/tắt/xóa. Chuông reo (`alarmCallback` body) vẫn thuộc Phase 2.
2. Check + xin quyền exact alarm (Android 12+) ngay khi bấm Lưu (permission_handler đã có trong pubspec).
3. Test mức vừa: model round-trip + stable-id hash + widget test form với fake repository. Không thêm dependency.

**Tái sử dụng (đã có sẵn, không viết mới):** `WeekdaySelector`, `AlarmTile.onTap` (chưa được wire), `RingtonePickerPage` (pop trả ringtone id), `DateTimeUtils.nextOccurrence` (đã có test), `AlarmScheduler.scheduleOneShot/cancel`, package `uuid`.

## Các bước triển khai

### 1. AndroidManifest — khai báo service của android_alarm_manager_plus
`android/app/src/main/AndroidManifest.xml`, trong `<application>` (thiếu là plugin không chạy):
```xml
<service android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
    android:permission="android.permission.BIND_JOB_SERVICE" android:exported="false"/>
<receiver android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver" android:exported="false"/>
<receiver android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
    android:enabled="false" android:exported="false">
  <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/></intent-filter>
</receiver>
```

### 2. Bootstrap — init alarm manager
`lib/core/bootstrap.dart`: thay TODO đầu tiên bằng `await AndroidAlarmManager.initialize()` (try/catch + AppLogger, giống pattern DB init).

### 3. AlarmScheduler — stable int id từ UUID
`lib/core/platform/alarm_scheduler.dart`: thêm `static int stableId(String alarmId)` — hash FNV-1a 32-bit, mask 31-bit dương. KHÔNG dùng `String.hashCode` (không ổn định giữa các phiên bản VM — id phải sống qua reboot/upgrade để cancel đúng).

### 4. LocalAlarmRepository — đồng bộ persist ↔ schedule
`lib/features/alarm_management/data/repositories/local_alarm_repository.dart` (thay 2 TODO có sẵn):
- Inject thêm `AlarmScheduler` qua constructor.
- `upsertAlarm`: persist → nếu `isEnabled` thì `scheduleOneShot(stableId(id), DateTimeUtils.nextOccurrence(...))`, ngược lại `cancel`.
- `deleteAlarm`: xóa row → `cancel`.
- `setEnabled`: update → fetch lại alarm → schedule/cancel tương ứng.
- Ghi chú trong code: báo thức lặp chỉ được schedule occurrence kế tiếp; re-schedule sau khi reo là việc của `alarmCallback` (Phase 2).
- Cập nhật wiring `alarm_providers.dart`: truyền `ref.watch(alarmSchedulerProvider)` (provider đã có trong `core_providers.dart`).

### 5. Quyền exact alarm
File mới `lib/core/platform/exact_alarm_permission.dart`: `Future<bool> ensureExactAlarmPermission()` — trên Android check `Permission.scheduleExactAlarm`, thiếu thì `request()`; trả `true` khi OK. Trên host/test (`!Platform.isAndroid`) trả `true` luôn để widget test không đụng plugin.

### 6. AlarmEditPage — form đầy đủ
`lib/features/alarm_management/presentation/pages/alarm_edit_page.dart` (giữ <200 dòng bằng cách tách widget):
- Draft state từ `widget.existing` hoặc default mới (`uuid.v4()`, giờ hiện tại, `DismissTaskConfig()` mặc định).
- Form: giờ (tap → `showTimePicker`) · TextField tên · `WeekdaySelector` · chọn nhạc chuông (`Navigator.pushNamed(AppRouter.ringtonePicker)` nhận id trả về, hiển thị tên qua `ringtoneRepositoryProvider.getById`) · chọn nhiệm vụ tắt (widget mới, bước 7) · 3 switch: rung / khóa volume / tăng dần âm lượng.
- Lưu: `ensureExactAlarmPermission()` → `alarmRepositoryProvider.upsertAlarm(draft)` → pop `true`.
- Xóa (chỉ khi sửa alarm có sẵn): icon delete trên AppBar → dialog xác nhận → `deleteAlarm` → pop `true`.

### 7. Widget mới: DismissTaskSelector
`lib/features/alarm_management/presentation/widgets/dismiss_task_selector.dart`:
- ChoiceChip chọn `DismissTaskType` (none/math/shake/qrScan/photo — label tiếng Việt).
- Field điều kiện theo type: math → Slider độ khó 1–5; shake → Slider số lần lắc; qrScan → TextField payload; photo → TextField gợi ý vật thể. Callback `onChanged(DismissTaskConfig)`.

### 8. Router + List page — mở form sửa
- `app_router.dart`: case `alarmEdit` đọc `settings.arguments as Alarm?` → `AlarmEditPage(existing: ...)`.
- `alarm_list_page.dart`: truyền `onTap` cho `AlarmTile` → `pushNamed(alarmEdit, arguments: alarm)`; sau khi `await` pushNamed (cả FAB lẫn tile) → `ref.invalidate(alarmListProvider)` (hiện FAB không refresh — alarm mới tạo sẽ không hiện nếu thiếu).

### 9. Gỡ seed demo
`lib/core/database/app_database.dart`: xóa `_seedDemoAlarms` + lời gọi. Empty state đã có sẵn ("Chưa có báo thức nào"). Lưu ý dev: máy đã cài bản cũ cần xóa app data để bỏ seed cũ.

### 10. Tests (không thêm dependency)
- `test/alarm_model_test.dart`: round-trip `toDbRow` → `fromDbRow` bằng Equatable so sánh (đủ case: repeat rỗng/nhiều ngày, các loại dismiss task).
- `test/alarm_scheduler_test.dart`: `stableId` deterministic, dương, khác nhau với các UUID mẫu.
- `test/alarm_edit_page_test.dart`: `ProviderScope` override `alarmRepositoryProvider` bằng fake in-memory (viết fake ngay trong file test); nhập tên + bấm Lưu → fake nhận đúng alarm; mở với `existing` → hiện nút xóa.
- Giữ nguyên `test/widget_test.dart`.

### 11. Docs + plan copy
- Copy plan này vào `D:\WakeLock_PRM393\plans\260712-1710-phase-1-alarm-crud-scheduler\plan.md` (quy ước CK).
- `docs/development-roadmap.md`: tick các mục Phase 1; chuyển mục `AndroidAlarmManager.initialize()` của Phase 2 thành done-in-Phase-1.
- `docs/system-architecture.md`: bảng "Ranh giới native" — cập nhật trạng thái android_alarm_manager_plus.

## Verification
1. `dart analyze lib test` sạch; `flutter test` xanh (dùng `dart analyze`, không dùng `flutter analyze` — bug LSP đường dẫn Unicode).
2. Chạy emulator Android: tạo báo thức mới (đủ giờ/ngày/nhạc/nhiệm vụ) → hiện trong list; sửa; toggle off/on; xóa; restart app → data persist.
3. Xác nhận lập lịch thật: `adb shell dumpsys alarm | findstr wakelock` thấy alarm đã đăng ký; toggle off → biến mất.
4. Máy Android 12+: lần lưu đầu hiện dialog xin quyền exact alarm.

## Ngoài phạm vi (Phase 2+)
- Body của `alarmCallback` (foreground service + overlay + phát nhạc khi reo).
- Reschedule sau reboot và sau mỗi lần báo thức lặp reo.
- Onboarding cấp quyền tổng hợp ở Settings (Phase 5).
