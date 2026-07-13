# Dev 1 — Wake & Personal (offline / SQLite)

Bạn phụ trách **lõi thức dậy + dữ liệu cá nhân offline**. Tất cả dùng **SQLite**
(`sqflite`), không đụng Firebase. Xem luật chung ở `docs/team-work-split.md`.

- **Tab sở hữu:** Home (báo thức), Thói quen (`habit_page.dart`).
- **File dùng chung bạn sở hữu:** `core/database/app_database.dart`,
  `core/constants/app_constants.dart` (mọi bảng SQLite), `alarm.dart`,
  `main_shell.dart`/`app_router.dart`/`theme` (lead).

## Feature queue (thứ tự đề xuất)

- [x] **routine** 🆕 — *đã scaffold sẵn* (xem dưới)
- [x] **morning_photo** 🆕 — *đã scaffold* (data layer + `morning_photo_page.dart` stub); dựng flow Camera→Preview→Caption→Privacy theo UI, lưu qua `morningPhotoRepositoryProvider`
- [ ] **streak** — tính streak từ `wake_events` (Alarm+Mission+Photo trong khung giờ = +1), calendar/heatmap
- [ ] **alarm_management / alarm_ringing** — thêm snooze, link routine/emergency; nối chuỗi sau mission → routine → photo (⚠️ đụng native, cẩn thận)
- [ ] **habit** — habit tracker (tab Thói quen)
- [ ] **dashboard** — analytics (đọc `wake_events`, `habit_checkins`)
- [ ] **ai_coach** — dùng lại pattern `gemini_vision_service.dart` → `gemini_coach_service.dart`
- [ ] **emergency** — SOS contact/SMS/call
- [ ] **task** — mission mới (QR, memory, pattern, sudoku...) khi có UI

## Đã scaffold sẵn: `features/routine/` (dùng làm TEMPLATE)

Data layer đã chạy end-to-end (bảng `morning_routines`/`routine_steps` có sẵn ở DB v4):
```
routine/
  domain/entities/routine.dart                 # MorningRoutine + RoutineStep + enum
  domain/repositories/routine_repository.dart   # interface
  data/datasources/routine_local_datasource.dart# sqflite CRUD + mapping
  data/repositories/local_routine_repository.dart# impl
  presentation/providers/routine_providers.dart # routineListProvider, routineRepositoryProvider
  presentation/pages/routine_list_page.dart      # UI stub (đọc routineListProvider) — thay bằng UI thật
```
→ Khi có ảnh UI: chỉ sửa `routine_list_page.dart` (+ thêm detail/edit/execute page trong `pages/`),
đọc `routineListProvider`, ghi qua `routineRepositoryProvider`. **Copy đúng cấu trúc này** cho các feature sau.

## Thêm bảng SQLite mới
Bạn sở hữu `app_database.dart`: bump `version`, thêm `if (oldV < N) await _createXxx(db);` trong
`onUpgrade`, và gọi trong `createSchema`. Thêm tên bảng vào `app_constants.dart`.
(Các bảng `wake_events`, `morning_photos`, `habits`... phần lớn đã tạo ở v4 — kiểm tra trước khi thêm.)

## Điểm giao (bạn cung cấp cho Dev 2)
- Expose `MorningPhoto` entity + lưu local; Dev 2 làm phần đăng feed.
- Expose `streakProvider` (current/longest/wakeRate); Dev 2 sync lên Firestore.
- Ghi bảng `wake_events`; Dev 2 đọc read-only để cộng XP.

## Luật chống đụng code
- Chỉ SQLite; **không** import `cloud_firestore`.
- Push màn con bằng `Navigator.push(MaterialPageRoute(builder: (_) => XxxPage()))` — **không** sửa `app_router.dart`.
- Provider để trong `features/<x>/presentation/providers/`, **không** thêm vào `core_providers.dart`.
- Branch: `feat/wake-flow`; pull `main` trước khi push.

## Bắt đầu
`features/routine/` → làm màn Routine (list/detail/edit) theo ảnh UI → sang `morning_photo/`.
