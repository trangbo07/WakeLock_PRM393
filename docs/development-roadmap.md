# Development Roadmap — WakeLock

## Phase 0 — Kick-off scaffold ✅ (hoàn thành)

- [x] Khởi tạo Flutter project (Android-only)
- [x] Tích hợp dependencies (Riverpod, sqflite, alarm manager, overlay, foreground task, audioplayers, scanner, sensors...)
- [x] Cấu trúc feature-first + Clean Architecture
- [x] Entity + repository + datasource + provider cho alarm
- [x] Skeleton page cho mọi màn hình (list, edit, ringtone, task×4, ringing, settings)
- [x] Platform bridge stub (scheduler, overlay, foreground, volume lock)
- [x] AndroidManifest permissions + minSdk 23 + desugaring
- [x] `dart analyze` sạch, `flutter test` xanh

## Phase 1 — Quản lý báo thức (MVP chuẩn) ✅ (hoàn thành 2026-07-12)

- [x] Database SQLite local (`AppDatabase`, bảng `alarms` — schema trong system-architecture.md; thay Supabase 2026-07-12)
- [x] Hoàn thiện `AlarmEditPage`: TimePicker, WeekdaySelector, tên, chọn nhạc chuông, chọn nhiệm vụ + toggle rung/khóa volume/tăng âm
- [x] Bật/tắt + xóa báo thức đồng bộ với scheduler (`LocalAlarmRepository._syncSchedule`, id ổn định FNV-1a)
- [x] Check + xin quyền exact alarm khi lưu (`ensureExactAlarmPermission`)
- [x] Gỡ seed demo trong `AppDatabase`

## Phase 2 — Lên lịch & báo thức kêu ✅ (hoàn thành 2026-07-12)

- [x] `AndroidAlarmManager.initialize()` trong bootstrap + map id ổn định (đã làm trong Phase 1)
- [x] `alarmFireHandler` (isolate nền) đọc SQLite + post notification full-screen + phát nhạc ở isolate chính
- [x] `AlarmRingingPage` hiển thị full-screen qua full-screen intent (wire trong `app.dart`)
- [x] Reschedule sau reboot (`rescheduleOnReboot` + receiver enabled); báo thức lặp tự schedule occurrence kế tiếp khi reo; one-shot tự tắt
- [x] Nhạc chuông thật (.wav) trong `assets/ringtones/`
- Ghi chú: foreground service chống-kill để Phase 4 (notification full-screen intent đã đủ để reo ở Phase 2)

## Phase 3 — Nhiệm vụ tắt báo thức ✅ (hoàn thành 2026-07-12)

- [x] Toán: `MathProblemGenerator` sinh đề theo độ khó, giải liên tiếp N câu
- [x] Lắc máy: `ShakeDetector` + accelerometer (sensors_plus), đếm N lần lắc có progress
- [x] Quét QR: MobileScanner v7, so khớp payload
- [x] Chụp ảnh: image_picker/camera (nhận diện vật thể để tương lai)

## Phase 4 — Tính năng hardcore ✅ (hoàn thành 2026-07-12)

- [x] Native MethodChannel `wakelock/volume` trong MainActivity.kt (ghim volume + nuốt phím VOLUME_UP/DOWN)
- [x] Đè lock screen bằng full-screen intent + showWhenLocked (overlay window riêng: bỏ, YAGNI — xem implementation-logic.md §5)
- [x] Foreground service cấu hình đầy đủ (init bootstrap + start/stop quanh lúc reo) + xin bỏ tối ưu pin trong Settings
- [x] Tăng dần âm lượng + chặn giảm khi đang reo

## Phase 5 — Hoàn thiện

- [ ] Onboarding cấp quyền (settings page)
- [x] Kho nhạc chuông thật (assets/ringtones/ — .wav tự sinh, làm ở Phase 2)
- [ ] Test tích hợp luồng báo thức
- [ ] Đánh bóng UI/UX, dark theme

## Ghi chú kỹ thuật

- Dùng `dart analyze` thay `flutter analyze` (LSP server crash với đường dẫn Unicode "Máy tính").
- iOS đã loại bỏ — tính năng hardcore không khả thi trên iOS.
- 2026-07-12: bỏ Supabase, chuyển sang SQLite local-only (`sqflite`) — báo thức là dữ liệu per-device, isolate nền phải đọc offline; xem `plans/260712-1659-migrate-supabase-to-sqlite/plan.md`.
