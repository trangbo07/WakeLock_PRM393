# Changelog — WakeLock

Ghi các thay đổi quan trọng. Mới nhất ở trên. (Định dạng ngày: YYYY-MM-DD.)

## 2026-07-12 (bổ sung tối)

### Hiệu ứng hardcore + chống gian lận đồng hồ + icon
- **Đèn flash "flashbang"**: khi reo, `AlarmSoundService` chớp đèn flash camera
  (native `AlarmEffects`, ~3 nháy/giây) + màn hình reo chớp amber↔đen. Toggle
  per-báo-thức `flashlight` (cột DB mới, **schema v3**, migration `ALTER TABLE`).
- **Rung dồn dập tăng dần**: rung theo `alarm.vibrate`, on-time tăng/gap giảm
  dần theo thời gian (VibratorManager/Vibrator).
- **Chống chỉnh đồng hồ né báo thức**: `rescheduleAllEnabled()` chạy khi mở app
  + mỗi lần resume → re-anchor mọi báo thức bật về đúng "lần kế tiếp" theo giờ
  thực. Đổi đồng hồ thì lần mở app kế các báo thức tự khớp lại.
- **Icon + tên app**: icon đồng hồ báo thức hổ phách trên navy (adaptive), nhãn
  "WakeLock".
- **Xin quyền lần đầu**: `runFirstLaunchPermissionOnboarding()` hỏi tất cả quyền
  hardcore 1 lần khi mở app đầu tiên; đổi lại được trong Cài đặt.

## 2026-07-12

### Kiến trúc lưu trữ
- **Bỏ Supabase, chuyển sang SQLite local-only** (`sqflite`). Báo thức là dữ liệu
  per-device, isolate nền phải đọc offline → SQLite là nguồn sự thật duy nhất.
  Gỡ `supabase_flutter`, `flutter_dotenv` (giai đoạn này), `shared_preferences`,
  feature `auth/`, remote datasource, in-memory demo repo.
- **SQLite version 2**: thêm bảng `custom_ringtones` cho nhạc người dùng tự tải
  (migration `onUpgrade` v1→v2 giữ nguyên bảng `alarms`).

### Tính năng (Phase 1–5)
- **Phase 1 — CRUD báo thức**: form `AlarmEditPage` đầy đủ (giờ, ngày lặp, tên,
  nhạc, nhiệm vụ, toggle rung/khóa-volume/tăng-âm); lập lịch exact alarm thật
  (`android_alarm_manager_plus`); id ổn định FNV-1a; xin quyền exact alarm khi lưu.
- **Phase 2 — luồng reo**: isolate nền đọc SQLite khi tới giờ; báo thức lặp tự
  schedule occurrence kế; one-shot tự tắt.
- **Phase 3 — 4→3 nhiệm vụ tắt**: toán (`MathProblemGenerator`), lắc
  (`ShakeDetector`), chụp ảnh; **QR đã gỡ** theo yêu cầu người dùng.
- **Phase 4 — hardcore**: khóa/ghim âm lượng + nuốt phím volume (native Kotlin),
  giữ màn sáng + đè keyguard; màn cấp quyền (`SettingsPage`).
- **Phase 5 — hoàn thiện**: test tích hợp (SQLite ffi in-memory), đánh bóng UI
  (list dạng card, empty state, dim khi tắt).

### Nhạc chuông
- Kho nhạc chuông dùng **âm báo thức hệ thống Android thật** (RingtoneManager) +
  **cho người dùng tự tải file nhạc** (`file_picker`, copy vào app storage).
  Không nhúng audio bản quyền. Có **nghe thử** trong kho.
- (Đã thay bộ tone .wav tự tổng hợp trước đó bằng nhạc hệ thống.)

### Nhận diện vật thể (chụp ảnh)
- Nhiệm vụ chụp ảnh dùng **Gemini** (`gemini-3.1-flash-lite`) kiểm tra ảnh có
  đúng vật thể không (fail-open khi lỗi/không key). Key đọc từ `.env` git-ignore.

### Sửa lỗi luồng reo (quan trọng)
- **Tự kêu**: trước đây nhạc gắn với UI nên chỉ kêu khi bấm thông báo. Chuyển
  phát nhạc sang **foreground service native `AlarmSoundService`** (broadcast từ
  isolate nền qua `android_intent_plus`) → reo tự động đúng giờ, dù khóa/mở máy.
- **Lặp bền**: dùng `Ringtone.setLooping(true)` thay `FLAG_INSISTENT` (chập chờn,
  chỉ kêu 1 lần) → chuông lặp liên tục tới khi tắt.
- **Chống thoát / không mất đường vào**: mở lại app lúc đang reo (kể cả đã xóa
  thông báo) luôn quay về màn "Tắt báo thức" (`currentRingingAlarmId`). Bấm thông
  báo lúc app đang chạy cũng mở đúng màn (`launchRinging` push).
- **Refresh danh sách** khi resume/đóng màn reo → toggle báo thức một-lần hiển
  thị đúng (đã tắt) sau khi reo.

### Build / hạ tầng
- Pin `compileSdk = 36`; ép library subproject lên 36 (do `file_picker` compile
  ở 34 trong khi dependency khác cần 36).
- Thêm quyền INTERNET; gỡ `flutter_local_notifications` (service tự post thông báo).
- Ngừng theo dõi `android/build/` artifacts.

### Tài liệu
- Thêm `docs/implementation-logic.md` (sổ tay logic từng mảng, để debug).
- Cập nhật `README`, `system-architecture.md`, `development-roadmap.md`.

### Kiểm thử
- `dart analyze` sạch, **28 test** (unit + widget + integration) xanh.
- Đã verify trên emulator Android API 36: tạo/lưu/lập lịch thật, tự reo + lặp,
  mở lại app lúc reo → màn tắt, hoàn thành nhiệm vụ → dừng service, dữ liệu persist.

---

## Kick-off (trước 2026-07-12)
- Khởi tạo scaffold Flutter Android-only, tích hợp dependencies, cấu trúc
  feature-first + Clean Architecture (commit `e8ead34`, `1c10aad`).
