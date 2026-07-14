import 'package:flutter/material.dart';

/// A daily goal the user claims for an XP + coin reward (once per day).
class DailyMission {
  const DailyMission({
    required this.id,
    required this.title,
    required this.icon,
    required this.xp,
    required this.coins,
  });

  final String id;
  final String title;
  final IconData icon;
  final int xp;
  final int coins;
}

/// The daily mission catalog.
const List<DailyMission> kDailyMissions = [
  DailyMission(
    id: 'alarms3',
    title: 'Hoàn thành 3 báo thức',
    icon: Icons.alarm_on,
    xp: 10,
    coins: 5,
  ),
  DailyMission(
    id: 'nosnooze',
    title: 'Không snooze',
    icon: Icons.block,
    xp: 30,
    coins: 10,
  ),
  DailyMission(
    id: 'walk100',
    title: 'Đi bộ 100 bước',
    icon: Icons.directions_walk,
    xp: 40,
    coins: 15,
  ),
];
