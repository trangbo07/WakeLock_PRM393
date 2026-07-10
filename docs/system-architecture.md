# System Architecture — WakeLock

## Tổng quan

Feature-first + Clean Architecture. Mỗi feature tự chứa 3 lớp:

- **domain** — entity thuần Dart + interface repository (không phụ thuộc Flutter/Supabase).
- **data** — model (JSON), datasource (Supabase remote + local cache), impl repository.
- **presentation** — Riverpod provider + page + widget.

`core/` giữ code dùng chung; `app/` giữ MaterialApp/theme/router.

## Luồng dữ liệu báo thức

```
AlarmEditPage → alarmRepositoryProvider (Riverpod)
             → AlarmRepositoryImpl
                 ├─ AlarmRemoteDataSource   → Supabase (bảng alarms)  [nguồn sự thật]
                 └─ AlarmLocalCacheDataSource → SharedPreferences      [mirror offline]
             → AlarmScheduler.scheduleOneShot()  (android_alarm_manager_plus)
```

Cache local là bắt buộc: bộ lập lịch chạy trong **isolate nền** lúc báo thức kêu,
thường không có mạng — phải đọc được cấu hình báo thức offline.

## Luồng báo thức kêu (hardcore)

```
[Đến giờ] AndroidAlarmManager → alarmCallback(id)  (isolate nền)
   1. ForegroundServiceController.start()   → notification bền, chống bị kill
   2. OverlayService.showRinging()          → overlay đè lên màn hình khóa
   3. RingtonePlayerService.play(escalate)  → phát nhạc, tăng dần âm lượng
   4. VolumeLockChannel.lockToMax()         → chặn phím giảm âm lượng (native)
[Người dùng] AlarmRingingPage (PopScope chặn Back)
   → TaskRunnerPage(config) → math/shake/qr/photo
   → TaskResult.success → dừng nhạc + service + overlay
```

## Ranh giới native (cần code Kotlin trong `MainActivity.kt`)

| Kênh / API | Mục đích | Trạng thái |
|-----------|----------|-----------|
| `wakelock/volume` (MethodChannel) | Ghim max volume + nuốt phím volume-down | **Chưa viết native** |
| `flutter_overlay_window` | Vẽ overlay trên lock screen | Plugin có sẵn, cần cấp quyền SYSTEM_ALERT_WINDOW |
| `flutter_foreground_task` | Service chống tắt ngầm | Cần `init(...)` config trong bootstrap |
| `android_alarm_manager_plus` | Lập lịch chính xác | Cần gọi `AndroidAlarmManager.initialize()` |

## Schema Supabase (đề xuất — bảng `alarms`)

```sql
create table public.alarms (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references auth.users(id),
  label          text not null default '',
  hour           int  not null check (hour between 0 and 23),
  minute         int  not null check (minute between 0 and 59),
  repeat_days    int[] not null default '{}',      -- 1=T2 .. 7=CN
  is_enabled     bool not null default true,
  ringtone_id    text not null default 'default',
  vibrate        bool not null default true,
  volume_lock    bool not null default true,
  escalate_volume bool not null default true,
  dismiss_task   jsonb not null default '{"type":"math","difficulty":3,"shake_count":50}',
  created_at     timestamptz not null default now()
);

alter table public.alarms enable row level security;
create policy "own alarms" on public.alarms
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

## Quyền Android (đã khai báo trong AndroidManifest.xml)

Exact alarm, wake lock, boot completed, foreground service (special use + media
playback), ignore battery optimization, system alert window, full-screen intent,
disable keyguard, post notifications, vibrate, modify audio settings, camera.

`MainActivity` đặt `showWhenLocked=true` + `turnScreenOn=true`. `minSdk = 23`,
bật core library desugaring cho `flutter_local_notifications`.
