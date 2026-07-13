# WakeLock — Tính năng & Điểm mạnh

> Ứng dụng báo thức **"không thể trốn tránh"** — báo thức cứng đầu buộc bạn phải
> hoàn thành một nhiệm vụ thực sự (giải toán, đi bộ, chụp đúng vật thể...) mới tắt
> được. Xây bằng Flutter, Android-only, 100% offline.

**Tech stack:** Dart + Flutter 3.44 · Riverpod 3.x · SQLite (`sqflite`) · Kotlin
native (Kênh MethodChannel) · Clean Architecture (feature-first).

---

## 1. Nhóm tính năng

### 1.1. Quản lý báo thức (chuẩn)

| Tính năng | Mô tả |
|-----------|-------|
| Đặt báo thức | Chọn giờ/phút, đặt tên, chọn ngày lặp trong tuần (T2–CN) |
| Báo thức một lần / lặp | One-shot tự tắt sau khi reo; lặp tự lên lịch lần kế tiếp |
| Bật/tắt nhanh | Toggle từng báo thức ngay trên danh sách (dạng card, dim khi tắt) |
| Sửa/xóa | Chỉnh sửa toàn bộ cấu hình; xóa đồng bộ hủy lịch |
| Lập lịch chính xác | `android_alarm_manager_plus` — kêu **đúng giây**, kể cả khi app bị kill |
| Sống sót sau reboot | Tự lên lịch lại sau khi khởi động lại máy |

### 1.2. Kho nhạc chuông

- **Nhạc hệ thống Android thật** — liệt kê âm báo thức có sẵn trên máy (Argon,
  Cesium, ...) qua `RingtoneManager`.
- **Nhạc tự tải lên** — người dùng chọn file audio riêng (`file_picker`), copy vào
  bộ nhớ app; thêm/xóa tùy ý.
- **Nghe thử ngay trong kho** trước khi chọn.
- **Không nhúng audio bản quyền** trong app → sạch về pháp lý.

### 1.3. Nhiệm vụ tắt báo thức (5 lựa chọn)

Mỗi báo thức gắn 1 nhiệm vụ; muốn tắt phải **hoàn thành nhiệm vụ**, không có nút
thoát tắt (chặn cả nút Back).

| Nhiệm vụ | Cách hoạt động |
|----------|----------------|
| **Chạm tắt** | Chế độ dễ — chạm để tắt |
| **Giải toán** | Giải liên tiếp N phép tính, độ khó tăng dần (cộng/trừ → nhân, số lớn) |
| **Lắc máy** | Lắc đủ N lần (đo bằng cảm biến gia tốc, có anti double-count) |
| **Đi bộ N mét** | Phải đứng dậy đi/chạy đủ số mét (đếm bước từ gia tốc); nằm yên không tăng |
| **Chụp ảnh vật thể** | Chụp đúng vật thể yêu cầu; xác thực bằng AI (Gemini) |

### 1.4. Tính năng "hardcore" (chống trốn báo thức)

| Tính năng | Mô tả |
|-----------|-------|
| **Đè màn hình khóa** | Màn reo bật lên full-screen ngay trên lock screen, tự sáng màn hình |
| **Chống tắt ngầm** | Foreground service native giữ tiến trình sống — không bị hệ thống kill |
| **Nhạc lặp bền vững** | Service native phát nhạc LOOP, độc lập UI → reo mãi tới khi hoàn thành nhiệm vụ |
| **Khóa âm lượng** | Ghim STREAM_ALARM ở max + **nuốt phím Volume Up/Down** → không thể vặn nhỏ |
| **Tăng dần âm lượng** | Ramp âm lượng từ 30% → max để càng lúc càng chói tai |
| **Flashbang** | Chớp đèn flash camera (~3 nháy/giây) + màn hình strobe amber↔đen |
| **Rung dồn dập** | Rung theo cường độ tăng dần (on-time dài ra, gap ngắn lại) |
| **Chống chỉnh đồng hồ** | Re-anchor mọi báo thức về giờ thực khi mở/resume app → đổi đồng hồ né không thoát được |

### 1.5. Cài đặt & cấp quyền

- **Onboarding cấp quyền lần đầu**: hỏi tất cả quyền hardcore một lần khi mở app.
- **Màn hình Cài đặt**: hiển thị trạng thái từng quyền + nút cấp; tự re-check khi
  quay lại từ system settings.
- **Xin quyền exact alarm khi lưu** (Android 12+) — chặn lưu nếu chưa cấp (vì báo
  thức thiếu quyền sẽ không reo đúng giờ).

---

## 2. Điểm mạnh

### 2.1. Kiến trúc "escape-proof" — điểm mạnh cốt lõi

Nhạc reo do **foreground service native** phát, **không** phụ thuộc UI Flutter.
Hệ quả:

- Reo **tự động** đúng giờ dù app đang bị kill hoặc máy đang khóa.
- Rời khỏi màn hình reo → **service vẫn kêu** (không thể tắt bằng cách thoát app).
- Xóa thông báo cũng **không mất đường vào**: mở lại app luôn quay về màn tắt báo
  thức khi service còn reo (`currentRingingAlarmId`).
- Dùng `Ringtone.setLooping(true)` thay `FLAG_INSISTENT` (chập chờn) → lặp chắc chắn.

> Đây là khác biệt lớn so với app báo thức thường: hầu hết chỉ kêu khi app còn
> sống hoặc dừng khi user thoát. WakeLock được thiết kế để **không có cách thoát dễ**.

### 2.2. Offline-first, local-only

- 100% dữ liệu nằm trên máy (SQLite `wakelock.db`) — **không cần backend, không cần
  mạng, không cần đăng nhập**.
- Isolate nền lúc reo đọc thẳng SQLite (thường không có mạng) → luôn có dữ liệu.
- **Riêng tư**: báo thức không rời khỏi thiết bị.

### 2.3. Chống gian lận nhiều lớp (anti-cheat)

Không chỉ khó tắt, mà chặn cả các "mẹo" trốn báo thức:

- **Nuốt phím volume** — không vặn nhỏ được khi đang reo.
- **Chặn nút Back** (`PopScope(canPop:false)`) — không thoát màn nhiệm vụ.
- **Re-anchor chống chỉnh đồng hồ** — đổi giờ hệ thống để né cũng vô hiệu.
- **Nhiệm vụ vận động thật** — đi bộ/lắc máy buộc cơ thể tỉnh táo, không chỉ bấm màn.

### 2.4. Triết lý "fail-open" thông minh

Nơi có thể lỗi hạ tầng, app **luôn ưu tiên không nhốt người dùng** lúc 6h sáng:

- Nhiệm vụ chụp ảnh: không có API key / lỗi mạng / lỗi Gemini → **chấp nhận ảnh**
  (chỉ chặn khi AI trả lời "NO" rõ ràng).
- Mọi lời gọi platform (audio/notif/volume) bọc try/catch — thiếu plugin hoặc
  native lỗi không làm kẹt người dùng trên màn reo.

### 2.5. ID báo thức ổn định (FNV-1a)

Alarm dùng UUID string, nhưng AndroidAlarmManager cần int id → hash **FNV-1a
32-bit** (không dùng `String.hashCode` vốn không ổn định giữa các phiên bản Dart
VM). Nhờ vậy sau khi **update app vẫn cancel/reschedule đúng** báo thức cũ.

### 2.6. Kiến trúc sạch, dễ bảo trì & test

- **Feature-first + Clean Architecture**: mỗi feature tự chứa `domain` / `data` /
  `presentation`; `core/` chỉ chứa hạ tầng dùng chung, **không phụ thuộc `features/`**.
- **Logic thuần Dart tách riêng** (`MathProblemGenerator`, `ShakeDetector`,
  `WalkDetector`) — test được không cần emulator, nhận `Random` seed để reproducible.
- **Test tích hợp SQLite thật in-memory** (`sqflite_common_ffi`) — kiểm tra luồng
  persist ↔ schedule mà không cần thiết bị.
- Bộ test **28 test** (unit + widget + integration) xanh; `dart analyze` sạch.

### 2.7. Sạch về pháp lý & bảo mật

- **Không nhúng audio bản quyền** — chỉ dùng nhạc hệ thống hoặc file người dùng.
- **API key không commit** — `GEMINI_API_KEY` đọc từ `.env` (git-ignored),
  có `.env.example` làm template.

---

## 3. Bảng tóm tắt điểm mạnh

| Điểm mạnh | Vì sao quan trọng |
|-----------|-------------------|
| Reo escape-proof (service native) | Không thể tắt bằng cách thoát app / khóa máy |
| Offline-first (SQLite) | Không backend, riêng tư, luôn hoạt động |
| Anti-cheat đa lớp | Chặn volume/back/chỉnh-giờ, buộc vận động thật |
| Fail-open | Sự cố hạ tầng không nhốt người dùng lúc sáng sớm |
| ID ổn định FNV-1a | Update app không mất báo thức đã lên lịch |
| Clean Architecture + test | Dễ bảo trì, mở rộng, verify |
| Không audio bản quyền + key an toàn | Sạch pháp lý & bảo mật |

---

## 4. Hướng mở rộng (đã ghi nhận, chưa làm)

- Nhạc tự tải cũng tự kêu qua thông báo (đưa file ra MediaStore/vùng dùng chung).
- Snooze có giới hạn + thống kê thức dậy.
- Nhận diện vật thể **on-device** cho nhiệm vụ chụp ảnh (bỏ phụ thuộc Gemini/mạng).

---

*Tài liệu liên quan: [`README.md`](../README.md) · [`system-architecture.md`](system-architecture.md) · [`implementation-logic.md`](implementation-logic.md) · [`development-roadmap.md`](development-roadmap.md) · [`project-changelog.md`](project-changelog.md)*
