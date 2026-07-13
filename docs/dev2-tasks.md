# Dev 2 — Social & Account (Firebase / Firestore)

Bạn phụ trách **tài khoản + mạng xã hội**. Dùng **Firebase Auth + Firestore + Storage**.
Dữ liệu chia sẻ nằm trên Firestore (không dùng SQLite). Xem luật chung ở `docs/team-work-split.md`.

- **Tab sở hữu:** Feed (`feed_page.dart`), Bạn bè (`friends_page.dart`), Hồ sơ (`profile_page.dart`).
- **File dùng chung bạn sở hữu:** `core/bootstrap.dart` (bước Firebase/FCM), tầng Firestore.
- Firebase đã setup xong (project `wakelock-89bc7`), init đã guard trong bootstrap.

## Feature queue (thứ tự đề xuất)

- [x] **auth** 🆕 — *đã scaffold sẵn* (xem dưới): Splash, Login (email/pw), `sessionProvider`
- [ ] **auth (còn lại)** — Register, Forgot Password, **Google Sign-In** (TODO trong datasource), Complete Profile, Onboarding
- [x] **profile** 🆕 — *đã scaffold* (entity + Firestore repo + `myProfileProvider`); wire vào `profile_page.dart` (tab Hồ sơ), thêm avatar Storage + username unique
- [ ] **friends** — search username, QR add, request/accept/reject, friend profile
- [ ] **feed** — Locket feed + **đăng Morning Photo** (upload Storage + `posts/{id}`), comment/reaction
- [ ] **challenge** — 7/14/30-day, weekend, first-wake, group
- [ ] **leaderboard** — daily/weekly/monthly/friend
- [ ] **gamification** — XP/level/badge/reward
- [ ] **notifications** — center + FCM
- [ ] **settings** — theme/language/backup (mở rộng `features/settings/` có sẵn)

## Đã scaffold sẵn: `features/auth/` (dùng làm TEMPLATE Firebase)

```
auth/
  domain/entities/app_user.dart                  # AppUser (map từ Firebase User)
  domain/repositories/auth_repository.dart        # interface (email/register/reset/google/signOut)
  data/datasources/firebase_auth_datasource.dart  # wrap FirebaseAuth (Google = TODO của bạn)
  data/repositories/firebase_auth_repository.dart  # impl, map User → AppUser
  presentation/providers/auth_providers.dart       # authRepositoryProvider, sessionProvider
  presentation/pages/splash_page.dart              # stub
  presentation/pages/login_page.dart               # form email/pw đã wire repo — thay UI thật
```
- **`sessionProvider`** = `StreamProvider<AppUser?>` (null = guest). Mọi feature social **gate** theo nó.
- **Google Sign-In**: điền `signInWithGoogle()` trong `firebase_auth_datasource.dart` (có sẵn TODO + hướng dẫn google_sign_in 7.x). Web client id nằm trong `google-services.json`.
- **Firestore pattern** cho các feature sau: tạo `data/datasources/xxx_firestore_datasource.dart` dùng
  `FirebaseFirestore.instance.collection('...')`, entity + `toMap/fromMap`, repository interface + impl, providers — **cùng cấu trúc như auth**.

## Firestore collections (tham khảo plan)
`users/{uid}`, `usernames/{username}`, `friend_requests`/`friendships`, `posts/{id}` (+`comments`,`reactions`),
`challenges/{id}`, `leaderboards`. Storage: `users/{uid}/avatar.jpg`, `users/{uid}/posts/{id}.jpg`.
> Nhớ cấu hình **Firestore Security Rules** trước khi có dữ liệu thật.

## Điểm giao (bạn nhận từ Dev 1)
- Đọc `MorningPhoto` (Dev 1 lưu local) → làm màn share → upload + set posted=1.
- Đọc `streakProvider` → sync lên `users/{uid}` cho leaderboard.
- Đọc read-only bảng `wake_events` (SQLite) để cộng XP.

## Luật chống đụng code
- Dùng Firestore; **không** sửa `app_database.dart` (cần bảng local → nhờ Dev 1).
- Push màn con bằng `Navigator.push(MaterialPageRoute(...))` — **không** sửa `app_router.dart`.
- Provider để trong `features/<x>/presentation/providers/`.
- Branch: `feat/social-auth`; pull `main` trước khi push.

## Bắt đầu
`features/auth/` → hoàn thiện Login/Register/Forgot + Google → wire Splash routing (session-aware) → sang `profile/`.

---

## Lộ trình chi tiết (theo thứ tự làm)

Phụ thuộc: **Auth → Profile → Friends → Feed/Challenge/Leaderboard → Gamification/Notification → Settings**.

### Bước 0 — Chuẩn bị
- [ ] `git checkout -b feat/social-auth`; đọc `docs/team-work-split.md`.
- [ ] Firebase đã setup (project `wakelock-89bc7`); auth/profile đã scaffold.
- [ ] Bật **Firestore + Auth (Email/Password + Google)** trên console nếu chưa.

### Bước 1 — Auth (nền cho mọi thứ)
- [ ] **Login**: hoàn thiện `login_page.dart` (validation, lỗi inline, nút sang Register/Forgot).
- [ ] **Register**: `register_page.dart` → `authRepository.registerWithEmail`.
- [ ] **Forgot Password**: `forgot_password_page.dart` → `sendPasswordReset`.
- [ ] **Google Sign-In**: điền `signInWithGoogle()` trong `firebase_auth_datasource.dart`
  (google_sign_in 7.x → lấy idToken → `GoogleAuthProvider.credential(idToken:)` → `signInWithCredential`).
- [ ] **Onboarding**: gộp xin quyền — dùng lại `permission_onboarding.dart` + `AppPermission`.
- [ ] **Complete Profile**: sau đăng ký → tạo `users/{uid}` + đặt username (unique qua `usernames/{username}`) + avatar.
- [ ] **Splash routing** (session-aware): signed-in → `MainShell`; first launch → Onboarding; else → Login.
  ⚠️ Sửa entry (`app.dart`/`app_router.dart`) — **file chung của lead**, phối hợp trước khi đổi.
- [ ] **Firestore Security Rules**: viết rules cơ bản (chỉ chủ sở hữu ghi doc của mình) — làm SỚM.

### Bước 2 — Profile
- [ ] Wire tab `profile_page.dart` với `myProfileProvider`.
- [ ] **Edit Profile**: upload avatar lên Storage (`users/{uid}/avatar.jpg`), sửa bio/displayName.
- [ ] **Username unique**: kiểm tra + reserve `usernames/{username}` (transaction).
- [ ] **Statistics**: hiển thị streak/xp/wakeRate (số do Dev 1 sync lên `users/{uid}`).
- [ ] **Privacy**: cài đặt ai xem được gì.

### Bước 3 — Friends (cần Auth + Profile)
- [ ] Entity `Friendship`/`FriendRequest` + Firestore datasource (`friend_requests`, `friendships`).
- [ ] **Search** theo username (query `users`).
- [ ] **QR add**: tạo mã (`qr_flutter`) + quét (`mobile_scanner`).
- [ ] Gửi / **accept / reject / remove** lời mời.
- [ ] **Friend Profile**: đọc `users/{uid}` + ảnh & streak chung.
- [ ] Wire tab `friends_page.dart`.

### Bước 4 — Feed Locket (cần Friends + Morning Photo của Dev 1)
- [ ] Tab `feed_page.dart`: infinite scroll `posts` của bạn bè (theo `visibility`).
- [ ] **Đăng Morning Photo**: đọc `morningPhotoRepository.getUnposted()` (Dev 1) → upload Storage
  (`users/{uid}/posts/{id}.jpg`) → tạo `posts/{id}` → gọi `markPosted(id, remoteId)`.
- [ ] **Post Detail**, **Comment** (subcol `comments`), **Reaction/Like** (subcol `reactions`).
- [ ] Close-friend feed, save, share.

### Bước 5 — Challenge (cần Friends)
- [ ] `challenges/{id}` + subcol `progress`. Create (7/14/30-day, weekend, first-wake, group).
- [ ] Invite bạn bè, trạng thái running, ranking, màn Result.

### Bước 6 — Leaderboard
- [ ] Query `users` docs của bạn bè → xếp theo wakeTime / streak / XP / challenge.
- [ ] Tabs Daily / Weekly / Monthly / Friend.

### Bước 7 — Gamification
- [ ] XP/level (đọc read-only `wake_events` của Dev 1 + luật cộng XP), lưu ở `users/{uid}`.
- [ ] Badge/Achievement, Daily/Weekly reward, unlock theme + avatar frame.

### Bước 8 — Notification Center + FCM
- [ ] Init FCM trong `bootstrap.dart` (bạn sở hữu), lưu token vào `users/{uid}`.
- [ ] Màn Notification Center: friend posted/comment/like, challenge invite, achievement unlock.

### Bước 9 — Settings mở rộng
- [ ] Theme, **language (i18n → ARB/l10n)**, backup/restore/export, permission manager (dùng lại `SettingsPage`).

### Điểm giao nhớ chờ Dev 1
- **Feed** cần `MorningPhoto` (getUnposted/markPosted) — có sẵn interface, chỉ chờ Dev 1 làm màn chụp.
- **Leaderboard/Gamification** cần `streakProvider` + bảng `wake_events` — thống nhất field sớm.
