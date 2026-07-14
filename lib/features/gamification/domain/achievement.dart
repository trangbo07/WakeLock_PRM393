import 'package:flutter/material.dart';

import '../../profile/domain/entities/user_profile.dart';

/// Which profile stat an achievement is measured against.
enum AchvMetric { streak, xp, photos }

/// A badge the user unlocks by reaching a stat threshold (computed live from
/// the profile — no separate "unlocked" storage needed).
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.metric,
    required this.threshold,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchvMetric metric;
  final num threshold;

  num valueOf(UserProfile p) => switch (metric) {
        AchvMetric.streak => p.longestStreak,
        AchvMetric.xp => p.xp,
        AchvMetric.photos => p.photosShared,
      };

  bool unlockedBy(UserProfile p) => valueOf(p) >= threshold;
}

/// The badge catalog. Order = display order.
const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_wake',
    title: 'Khởi đầu',
    description: 'Dậy sớm ngày đầu tiên',
    icon: Icons.wb_twilight,
    color: Color(0xFFF59E0B),
    metric: AchvMetric.streak,
    threshold: 1,
  ),
  Achievement(
    id: 'streak_7',
    title: '7 ngày liên tiếp',
    description: 'Giữ chuỗi 7 ngày',
    icon: Icons.local_fire_department,
    color: Color(0xFFEF4444),
    metric: AchvMetric.streak,
    threshold: 7,
  ),
  Achievement(
    id: 'streak_30',
    title: '30 ngày liên tiếp',
    description: 'Giữ chuỗi 30 ngày',
    icon: Icons.whatshot,
    color: Color(0xFFDC2626),
    metric: AchvMetric.streak,
    threshold: 30,
  ),
  Achievement(
    id: 'photos_10',
    title: 'Nhiếp ảnh gia',
    description: 'Chia sẻ 10 ảnh buổi sáng',
    icon: Icons.photo_camera,
    color: Color(0xFF6366F1),
    metric: AchvMetric.photos,
    threshold: 10,
  ),
  Achievement(
    id: 'photos_50',
    title: 'Người kể chuyện',
    description: 'Chia sẻ 50 ảnh buổi sáng',
    icon: Icons.collections,
    color: Color(0xFF8B5CF6),
    metric: AchvMetric.photos,
    threshold: 50,
  ),
  Achievement(
    id: 'xp_500',
    title: 'Tân binh',
    description: 'Tích luỹ 500 XP',
    icon: Icons.bolt,
    color: Color(0xFF22C55E),
    metric: AchvMetric.xp,
    threshold: 500,
  ),
  Achievement(
    id: 'xp_1500',
    title: 'Kỳ cựu',
    description: 'Tích luỹ 1.500 XP',
    icon: Icons.military_tech,
    color: Color(0xFF14B8A6),
    metric: AchvMetric.xp,
    threshold: 1500,
  ),
  Achievement(
    id: 'xp_3000',
    title: 'Huyền thoại',
    description: 'Tích luỹ 3.000 XP',
    icon: Icons.stars,
    color: Color(0xFFF5C542),
    metric: AchvMetric.xp,
    threshold: 3000,
  ),
];
