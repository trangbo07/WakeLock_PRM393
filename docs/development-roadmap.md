# Development Roadmap — WakeLock

## Phase 0 — Kick-off scaffold ✅ (hoàn thành)

- [x] Khởi tạo Flutter project (Android-only)
- [x] Tích hợp dependencies (Riverpod, Supabase, alarm manager, overlay, foreground task, audioplayers, scanner, sensors...)
- [x] Cấu trúc feature-first + Clean Architecture
- [x] Entity + repository + datasource + provider cho alarm
- [x] Skeleton page cho mọi màn hình (list, edit, ringtone, task×4, ringing, settings)
- [x] Platform bridge stub (scheduler, overlay, foreground, volume lock)
- [x] AndroidManifest permissions + minSdk 23 + desugaring
- [x] `dart analyze` sạch, `flutter test` xanh

## Phase 1 — Quản lý báo thức (MVP chuẩn)

- [ ] Tạo bảng `alarms` + RLS trên Supabase (schema trong system-architecture.md)
- [ ] Supabase auth ẩn danh khi mở app lần đầu
- [ ] Hoàn thiện `AlarmEditPage`: TimePicker, WeekdaySelector, tên, chọn nhạc chuông, chọn nhiệm vụ
- [ ] Nối realtime stream Supabase → `alarmListProvider`
- [ ] Bật/tắt + xóa báo thức đồng bộ với scheduler

## Phase 2 — Lên lịch & báo thức kêu

- [ ] `AndroidAlarmManager.initialize()` trong bootstrap + map id ổn định
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
- [ ] Kho nhạc chuông thật (assets/ringtones/ hoặc Supabase Storage)
- [ ] Test tích hợp luồng báo thức
- [ ] Đánh bóng UI/UX, dark theme

## Ghi chú kỹ thuật

- Dùng `dart analyze` thay `flutter analyze` (LSP server crash với đường dẫn Unicode "Máy tính").
- iOS đã loại bỏ — tính năng hardcore không khả thi trên iOS.
