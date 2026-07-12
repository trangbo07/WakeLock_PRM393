# WakeLock (PRM393)

Ứng dụng báo thức "không thể trốn tránh" — báo thức cứng đầu buộc bạn phải hoàn thành nhiệm vụ mới tắt được.

> Trạng thái: **Phase 1 hoàn thành** — tạo/sửa/xóa/bật-tắt báo thức hoạt động, lưu SQLite, lập lịch exact alarm thật. Luồng reo chuông (overlay + nhạc + nhiệm vụ) là Phase 2.

## Tech stack

| Lớp | Lựa chọn |
|-----|----------|
| Ngôn ngữ / Framework | Dart + Flutter 3.44 |
| State management | Riverpod 3.x |
| Database | SQLite (`sqflite`) — lưu 100% trên máy, offline-first, không cần backend |
| Nền tảng | **Android only** (tính năng hardcore yêu cầu quyền chỉ Android có) |
| Kiến trúc | Feature-first + Clean Architecture (data / domain / presentation) |

## Nhóm tính năng

**Quản lý báo thức (chuẩn)**
- Đặt giờ, chọn ngày lặp trong tuần, đặt tên → `features/alarm_management`
- Kho nhạc chuông "khủng bố" (tần số cao, tăng dần âm lượng, chặn giảm volume) → `features/ringtone` + `core/platform/volume_lock_channel.dart`
- Kho nhiệm vụ tắt báo thức: làm toán / lắc máy / quét QR / chụp ảnh → `features/task`

**Báo thức cứng đầu (hardcore)**
- Đè màn hình khóa (overlay) → `core/platform/overlay_service.dart` + `features/alarm_ringing`
- Chống tắt ngầm (foreground service) → `core/platform/foreground_service.dart`
- Lên lịch chính xác, kêu cả khi app bị kill → `core/platform/alarm_scheduler.dart`

## Cấu trúc thư mục

```
lib/
├── main.dart                     # entry point -> bootstrap() + ProviderScope
├── app/                          # MaterialApp, theme, router
│   ├── app.dart
│   ├── router/app_router.dart
│   └── theme/
├── core/                         # dùng chung toàn app
│   ├── bootstrap.dart            # mở SQLite + (TODO) init services
│   ├── database/app_database.dart # singleton SQLite (bảng alarms + seed demo)
│   ├── constants/
│   ├── error/failures.dart
│   ├── providers/core_providers.dart   # database + platform services
│   ├── platform/                 # cầu nối native cho tính năng hardcore
│   │   ├── alarm_scheduler.dart
│   │   ├── overlay_service.dart
│   │   ├── foreground_service.dart
│   │   └── volume_lock_channel.dart
│   └── utils/
└── features/                     # mỗi feature: data / domain / presentation
    ├── alarm_management/         # danh sách + tạo/sửa báo thức
    ├── ringtone/                 # kho nhạc chuông
    ├── task/                     # nhiệm vụ tắt báo thức (math/shake/qr/photo)
    ├── alarm_ringing/            # màn hình reo + overlay entry point
    └── settings/                 # cấp quyền, cấu hình
```

Xem thêm: [`docs/system-architecture.md`](docs/system-architecture.md), [`docs/development-roadmap.md`](docs/development-roadmap.md).

## Chạy dự án

1. Cài dependencies:
   ```bash
   flutter pub get
   ```
2. Chạy trên thiết bị/emulator Android:
   ```bash
   flutter run
   ```
   > Không cần cấu hình gì thêm — database SQLite tự tạo trên máy. Máy Android 12+ sẽ hỏi quyền "Báo thức và lời nhắc" ở lần lưu báo thức đầu tiên.

## Kiểm tra chất lượng

```bash
dart analyze lib test     # phân tích tĩnh (dùng dart, không dùng flutter analyze do bug LSP với đường dẫn Unicode)
flutter test              # unit + widget test
```

## Việc cần làm tiếp (kick-off → MVP)

Xem checklist chi tiết trong [`docs/development-roadmap.md`](docs/development-roadmap.md). Tóm tắt bước kế tiếp:
- Viết body `alarmCallback` (foreground service + overlay + phát nhạc khi reo).
- Viết native MethodChannel `wakelock/volume` trong `MainActivity.kt`.
- Cấu hình `FlutterForegroundTask.init(...)` trong `bootstrap()`.
