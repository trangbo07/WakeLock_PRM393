import 'package:flutter/material.dart';

/// A cosmetic the user can buy with coins (themes, sounds, effects, frames).
class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int price;
}

/// The shop catalog.
const List<ShopItem> kShopItems = [
  ShopItem(
    id: 'theme_galaxy',
    name: 'Chủ đề Galaxy',
    description: 'Giao diện tối màu thiên hà',
    icon: Icons.auto_awesome,
    color: Color(0xFF8B5CF6),
    price: 500,
  ),
  ShopItem(
    id: 'sound_ocean',
    name: 'Âm báo Ocean',
    description: 'Tiếng sóng biển dịu nhẹ',
    icon: Icons.water,
    color: Color(0xFF0EA5E9),
    price: 300,
  ),
  ShopItem(
    id: 'effect_confetti',
    name: 'Hiệu ứng Confetti',
    description: 'Pháo giấy khi tắt báo thức',
    icon: Icons.celebration,
    color: Color(0xFFF59E0B),
    price: 300,
  ),
  ShopItem(
    id: 'avatar_robot',
    name: 'Avatar Robot',
    description: 'Khung avatar robot ngộ nghĩnh',
    icon: Icons.smart_toy,
    color: Color(0xFF22C55E),
    price: 400,
  ),
  ShopItem(
    id: 'frame_gold',
    name: 'Khung vàng',
    description: 'Viền avatar mạ vàng sang trọng',
    icon: Icons.workspace_premium,
    color: Color(0xFFF5C542),
    price: 600,
  ),
];
