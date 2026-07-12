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

## Phase 2 — Lên lịch & báo thức kêu

- [x] `AndroidAlarmManager.initialize()` trong bootstrap + map id ổn định (đã làm trong Phase 1)
- [ ] `alarmCallback` khởi động foreground service + overlay + phát nhạc
- [ ] `AlarmRingingPage` hiển thị full-screen qua full-screen intent
- [ ] Reschedule sau reboot; xử lý báo thức lặp (next occurrence)

## Phase 3 — Nhiệm vụ tắt báo thức

- [ ] Toán: sinh đề theo độ khó, kiểm tra đáp án, đếm số câu đúng
- [ ] Lắc máy: đọc accelerometer (sensors_plus), đếm N lần lắc
- [ ] Quét QR: MobileScanner, so khớp payload
- [ ] Chụp ảnh: image_picker/camera, (tùy chọn) nhận diện vật thể

## Phase 4 — Tính năng hardcore

- [ ] Native MethodChannel `wakelock/volume` trong MainActivity.kt (ghim volume + nuốt phím)
- [ ] Overlay đè lock screen hoàn chỉnh (cấp quyền + UI đếm/nhiệm vụ trong overlay)
- [ ] Foreground service cấu hình đầy đủ + xin bỏ tối ưu pin
- [ ] Tăng dần âm lượng + chặn giảm khi đang reo

## Phase 5 — Hoàn thiện

- [ ] Onboarding cấp quyền (settings page)
- [ ] Kho nhạc chuông thật (assets/ringtones/)
- [ ] Test tích hợp luồng báo thức
- [ ] Đánh bóng UI/UX, dark theme

## Ghi chú kỹ thuật

- Dùng `dart analyze` thay `flutter analyze` (LSP server crash với đường dẫn Unicode "Máy tính").
- iOS đã loại bỏ — tính năng hardcore không khả thi trên iOS.
- 2026-07-12: bỏ Supabase, chuyển sang SQLite local-only (`sqflite`) — báo thức là dữ liệu per-device, isolate nền phải đọc offline; xem `plans/260712-1659-migrate-supabase-to-sqlite/plan.md`.
