# Design Guidelines — WakeLock

Nguồn: skill `ui-ux-pro-max` (product type **Alarm & World Clock**, style **Dark Mode OLED** + **Modern Dark Cinema Mobile**). Đã dịch sang Flutter/Material 3.

> Token đã code sẵn: `lib/app/theme/app_colors.dart`, `app_theme.dart`, `design_tokens.dart`.

## 1. Định hướng

- **Nền tảng:** Flutter (Android), Material 3, **dark-only**.
- **Tính cách:** ban đêm, tối giản, tương phản cao, "precision utility". Amber = thời gian/báo thức; indigo = đêm.
- **Nguyên tắc:** một CTA chính mỗi màn hình; tránh trang trí thừa; **không dùng pure black** (#000000) để tránh smear trên OLED.

## 2. Màu (Alarm & World Clock)

| Vai trò | Hex | Dùng cho |
|---------|-----|----------|
| Primary | `#D97706` amber | CTA chính, nút tắt báo thức, giờ |
| Secondary | `#F59E0B` | trạng thái phụ, highlight |
| Accent | `#6366F1` indigo | nhấn đêm, liên kết, icon phụ |
| Background | `#0F172A` navy sâu | nền màn hình |
| Surface (card) | `#192134` | thẻ báo thức, sheet |
| Muted | `#1F1E27` / fg `#94A3B8` | nền phụ, text phụ |
| Border | `rgba(255,255,255,0.08)` | đường hairline |
| Destructive | `#DC2626` | xóa, cảnh báo |

Text chính `#FFFFFF` trên surface đạt tương phản WCAG AA+. Kiểm tra riêng từng cặp khi thêm màu mới (≥4.5:1 body, ≥3:1 text lớn/icon).

## 3. Typography

- **Font:** Inter (heading + body) qua `google_fonts` → `GoogleFonts.interTextTheme`.
- **Chữ số đồng hồ:** dùng **tabular figures** (số cùng bề rộng) để giờ không nhảy layout. Với digit lớn (màn hình reo) set `fontFeatures: [FontFeature.tabularFigures()]`.
- **Cân nặng:** heading 600–700, body 400, label 500.
- **Type scale gợi ý:** 12 · 14 · 16 · 24 · 32 · 64 (digit đồng hồ). Body tối thiểu 16.

## 4. Spacing / Radius / Elevation

- **Spacing:** nhịp 4/8 — `AppSpacing` (xs4, sm8, md16, lg24, xl32, xxl48).
- **Radius:** card/button = **16** (`AppRadius.lg`); chip nhỏ 8–12; pill cho toggle.
- **Elevation:** phẳng + hairline border thay vì shadow nặng. Card `elevation:0` + border 0.08.

## 5. Motion (`AppMotion`)

- Micro-interaction **150–300ms**; transition phức tạp ≤400ms.
- Easing **Bezier(0.16, 1, 0.3, 1)** (expo-out) cho enter; exit ngắn hơn (~60–70%).
- Press: scale **0.97 → 1.0**; ripple/opacity feedback trong <100ms.
- Modal/sheet: animate từ nguồn (scale+fade / slide-in), spring cảm giác.
- **Tôn trọng `MediaQuery.disableAnimations` / reduced-motion** — giảm hoặc tắt.

## 6. Icon & tài nguyên

- **SVG / icon vector** (Material Icons hoặc `lucide_icons`) — **tuyệt đối không emoji làm icon**.
- Một bộ icon, đồng nhất stroke; kích thước token 24 (md).
- Touch target **≥44×44** (dùng padding/`hitSlop` nếu icon nhỏ).

## 7. Điểm nhấn UX theo màn hình

- **Danh sách báo thức:** digit giờ to (amber khi bật, muted khi tắt), Switch rõ trạng thái, empty state có hướng dẫn.
- **Màn hình reo (hardcore):** full-screen nền navy, digit khổng lồ, 1 CTA "Tắt báo thức", chặn Back (`PopScope`), không cho thao tác lệch.
- **Nhiệm vụ:** progress rõ ràng (đếm lắc, số câu toán), nút hoàn thành chỉ bật khi đủ điều kiện.
- **Form đặt báo thức:** label hiện rõ (không chỉ placeholder), validate on-blur, lỗi ngay dưới field.

## 8. Chống anti-pattern

- ❌ Pure white/black background · ❌ trang trí thừa · ❌ emoji icon · ❌ text < 12px · ❌ gray-on-gray · ❌ animate width/height (dùng transform/opacity) · ❌ tap target < 44pt.

## 9. Checklist trước khi giao UI

- [ ] Tương phản text ≥4.5:1 (đã test trên dark)
- [ ] Mọi phần tử chạm được có feedback <100ms + ≥44pt
- [ ] Icon SVG đồng nhất, không emoji
- [ ] Reduced-motion + Dynamic Type không vỡ layout
- [ ] Safe area (notch, gesture bar) cho header/CTA cố định
- [ ] Một CTA chính mỗi màn hình
