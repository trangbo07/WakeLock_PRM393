# Firebase Setup — WakeLock

Lớp xã hội của app (Auth, Feed, Friends, Challenge, Leaderboard) chạy trên **Firebase**
(Authentication + Firestore). Lõi báo thức vẫn **offline-first** — app chạy bình thường kể cả
khi chưa cấu hình Firebase (chỉ các tính năng xã hội bị tắt).

> Firebase project: **`99613734125`** · Android applicationId: **`com.prm393.wakelock_prm393`**

## Phần codebase đã wire sẵn (không cần làm lại)

- Dependencies: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`,
  `firebase_messaging`, `google_sign_in` (trong `pubspec.yaml`).
- Gradle: plugin `com.google.gms.google-services` khai báo ở `android/settings.gradle.kts`, và
  **áp dụng có điều kiện** trong `android/app/build.gradle.kts` — chỉ bật khi có
  `android/app/google-services.json` (nên project vẫn build được trước khi cấu hình Firebase).
- `minSdk` nâng lên **≥ 23** (yêu cầu của Firebase).
- Khởi tạo: `Firebase.initializeApp()` trong `lib/core/bootstrap.dart`, **bọc try/catch** — thiếu
  cấu hình thì log cảnh báo, không chặn app offline.

## Việc BẠN phải làm trên Firebase Console (cần tài khoản Google của bạn)

1. **Đăng ký app Android** trong project `99613734125`:
   Console → Project settings → *Your apps* → **Add app → Android**.
   - Android package name: `com.prm393.wakelock_prm393`
   - (App nickname tùy ý)
   - **Debug signing certificate SHA-1** (cần cho Google Sign-In) — lấy bằng:
     ```bash
     cd android && ./gradlew signingReport
     ```
     Copy dòng `SHA1` của variant **debug** → dán vào ô "SHA-1" (có thể thêm sau ở
     Project settings → SHA certificate fingerprints).
2. **Tải `google-services.json`** → đặt vào **`android/app/google-services.json`**.
3. **Authentication** → *Sign-in method* → bật **Email/Password** và **Google**.
4. **Firestore Database** → *Create database* (chọn location gần VN, ví dụ `asia-southeast1`).
   - Dev: có thể bắt đầu ở *test mode*; **siết Security Rules trước khi dùng thật**.
5. **Commit `google-services.json`** rồi push để cả nhóm build được (xem lưu ý bảo mật bên dưới).

## Kiểm tra

```bash
flutter run
```
Log phải hiện `Firebase initialized`. Nếu thấy `Firebase not configured — social features
disabled` → chưa có `google-services.json` (hoặc đặt sai chỗ).

## Lưu ý cho cả nhóm (teammates)

- **SHA-1 debug khác nhau theo từng máy.** Mỗi thành viên chạy `./gradlew signingReport` và thêm
  SHA-1 của mình vào Firebase console (Project settings → SHA fingerprints). *Hoặc* dùng chung 1
  `debug.keystore` commit vào repo + khai báo `signingConfig` — tiện hơn cho nhóm.
- `google-services.json` là **client config** (không phải secret key máy chủ). Với đồ án, commit
  vào repo để mọi người build được là chấp nhận được. Thứ thực sự bảo vệ dữ liệu là **Firestore
  Security Rules** — nhớ cấu hình rules trước khi có dữ liệu thật.
- `.env` (Gemini key) vẫn git-ignored — **không** commit.

## (Tùy chọn) Firebase agent skill / FlutterFire CLI

- Skill Firebase mà bạn muốn: chạy trong Claude Code:
  `claude plugin marketplace add firebase/agent-skills` → `claude plugin install firebase@firebase`,
  rồi **reload session** để skill được nạp.
- Cách thay thế console là FlutterFire CLI (tự đăng ký app + sinh `firebase_options.dart` + tải
  `google-services.json`): `firebase login` → `dart pub global activate flutterfire_cli` →
  `flutterfire configure --platforms=android`. Nếu dùng cách này thì **bỏ** bước tải json thủ công.
