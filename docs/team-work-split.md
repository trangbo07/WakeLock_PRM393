# Phân công 2 Dev — Không đụng code

Mục tiêu: 2 dev làm song song, **không sửa cùng file** → không merge conflict.
Dựa trên kiến trúc feature-first: mỗi feature nằm gọn trong `lib/features/<feature>/`
(`domain` / `data` / `presentation`). Ai sở hữu feature nào thì toàn quyền trong thư mục đó.

## Nguyên tắc vàng (đọc trước khi code)

1. **Chỉ sửa file trong feature mình sở hữu.** Cần thứ của người kia → dùng qua
   provider/interface họ expose, **không** sửa file của họ.
2. **Data tách tầng:** Dev 1 dùng **SQLite** (`sqflite`), Dev 2 dùng **Firestore**
   (`cloud_firestore`). → hầu như không đụng nhau ở tầng dữ liệu.
3. **Provider để trong feature của mình**, KHÔNG thêm vào `core/providers/core_providers.dart`.
4. **Điều hướng màn con:** push trực tiếp
   `Navigator.push(context, MaterialPageRoute(builder: (_) => XyzPage()))` từ trong feature —
   **KHÔNG** thêm route vào `app_router.dart` (tránh tranh chấp file router).
5. **Mỗi tab 1 file riêng** (đã tách sẵn, xem dưới) — sửa tab của mình, không đụng `main_shell.dart`.
6. Mỗi người làm trên **branch riêng**, PR vào `main`, **pull main trước khi push**.

## Phân công feature

### 👤 Dev 1 — "Wake & Personal" (offline / SQLite · tab Home + Thói quen)
| Feature folder | Nội dung |
|---|---|
| `features/alarm_management/` | Thêm snooze, link routine/emergency vào Alarm (sở hữu `alarm.dart`) |
| `features/alarm_ringing/` | Nối chuỗi sau mission → routine → photo (⚠️ đụng native, cẩn thận) |
| `features/task/` | Mission mới (QR, memory, pattern, sudoku...) |
| `features/routine/` 🆕 | Morning Routine (list/detail/edit/execute/complete) |
| `features/morning_photo/` 🆕 | Chụp ảnh sáng + lưu local (`morning_photos`) — phần **đăng feed để Dev 2** |
| `features/streak/` 🆕 | Streak engine (đọc `wake_events`) + calendar/heatmap |
| `features/habit/` 🆕 | Habit tracker (tab Thói quen) |
| `features/dashboard/` 🆕 | Analytics/report (đọc `wake_events`, `habit_checkins`) |
| `features/ai_coach/` 🆕 | AI Coach (dùng lại pattern Gemini) |
| `features/emergency/` 🆕 | SOS contact/SMS/call |
**Sở hữu file dùng chung:** `core/database/app_database.dart`, `core/constants/app_constants.dart`
(tất cả bảng SQLite), `alarm.dart`. Tab: `alarm_list_page.dart` (Home), `habit_page.dart`.

### 👤 Dev 2 — "Social & Account" (Firebase / Firestore · tab Feed + Bạn bè + Hồ sơ)
| Feature folder | Nội dung |
|---|---|
| `features/auth/` 🆕 | Splash/Onboarding/Login/Register/Forgot/Complete Profile + `sessionProvider` |
| `features/profile/` 🆕 | Profile/Edit/Stats/Privacy |
| `features/friends/` 🆕 | Search/QR/Request/Accept/Friend profile |
| `features/feed/` 🆕 | Feed Locket + **đăng Morning Photo** lên Storage/Firestore |
| `features/challenge/` 🆕 | 7/14/30-day, weekend, first-wake, group |
| `features/leaderboard/` 🆕 | Daily/weekly/monthly/friend ranking |
| `features/gamification/` 🆕 | XP/level/badge/reward |
| `features/notifications/` 🆕 | Notification center + FCM |
| `features/settings/` | Mở rộng: theme/language/backup (sở hữu, có sẵn) |
**Sở hữu file dùng chung:** `core/bootstrap.dart` (bước Firebase/FCM), tầng Firestore.
Tab: `feed_page.dart`, `friends_page.dart`, `profile_page.dart`.

## File dùng chung — chủ sở hữu & luật

| File | Chủ | Luật |
|---|---|---|
| `pubspec.yaml` / `pubspec.lock` | cả 2 | Conflict pubspec dễ gộp; báo nhau khi thêm dep lớn |
| `core/database/app_database.dart` + `app_constants.dart` | **Dev 1** | Dev 2 cần bảng local (vd notif cache) → nhờ Dev 1 thêm |
| `core/bootstrap.dart` | **Dev 2** | Dev 1 cần init gì → nhờ Dev 2 (ít khi) |
| `app/shell/main_shell.dart` | **Dev 1 (lead)** | Chỉ đổi khi thêm/bớt tab; nội dung tab nằm ở file tab riêng |
| `app/router/app_router.dart` | **Dev 1 (lead)** | Hạn chế sửa — dùng `MaterialPageRoute` cho màn con |
| `app/theme/*` | **Dev 1 (lead)** | Token chung; thêm màu mới thì báo nhau |

> Khi buộc phải sửa file của người khác: nhắn 1 câu + giữ thay đổi nhỏ, commit riêng.

## Điểm giao (interface — thống nhất sớm để không chờ nhau)

1. **Morning Photo → Feed:** Dev 1 lưu ảnh vào `morning_photos` (posted=0) + expose entity
   `MorningPhoto`. Dev 2 làm màn "chia sẻ": upload Storage + tạo `posts/{id}`, set `posted=1`.
2. **Streak → Leaderboard/Challenge:** Dev 1 expose `streakProvider` (current/longest/wakeRate).
   Dev 2 đọc rồi đồng bộ lên `users/{uid}` để xếp hạng.
3. **Wake event → XP:** Dev 2 gamification **đọc** bảng `wake_events` (read-only) để cộng XP.
4. **Auth gating:** Dev 2 sở hữu `sessionProvider`; feature social gate theo nó. Dev 1 offline không cần.

## Git workflow

```
main (ổn định)
├── feat/wake-flow      (Dev 1)
└── feat/social-auth    (Dev 2)
```
- Pull `main` trước khi push; PR review chéo trước khi merge.
- Conventional commits: `feat:`, `fix:`, `refactor:`... (không đề cập AI).

## Bắt đầu từ đâu

- **Dev 1:** `features/routine/` (Morning Routine) → `morning_photo/` (chụp+lưu) → `streak/`.
- **Dev 2:** `features/auth/` (Splash→Login→Register, `sessionProvider`) → `profile/` → `friends/`.
