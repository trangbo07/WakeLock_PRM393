import 'package:flutter/material.dart';

import '../../../profile/presentation/widgets/avatar_image.dart';

/// The six reactions offered on a post (matches the reaction-picker mockup).
const List<String> kReactionEmojis = ['❤️', '😍', '🔥', '💪', '😮', '😂'];

/// Rose-red used for the heart reaction (the app's Inter font ships a
/// monochrome U+2764 glyph, so the emoji would otherwise render white).
const Color kHeartColor = Color(0xFFF43F5E);

/// Renders a reaction glyph. The heart is drawn as a filled red icon (Inter
/// would otherwise paint it monochrome white); every other reaction is a
/// normal color emoji.
Widget reactionGlyph(String emoji, {double size = 18}) {
  if (emoji == '❤️' || emoji == '❤') {
    return Icon(Icons.favorite, size: size + 2, color: kHeartColor);
  }
  return Text(emoji, style: TextStyle(fontSize: size));
}

/// Short Vietnamese "time ago" label for feed timestamps.
String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
  if (diff.inHours < 24) return '${diff.inHours} giờ';
  if (diff.inDays < 7) return '${diff.inDays} ngày';
  return '${d.day}/${d.month}';
}

/// Image provider for a post photo (base64 preferred, then URL). Reuses the
/// same base64/URL resolution as avatars.
ImageProvider? postImageProvider({String? base64Data, String? url}) =>
    avatarImageProvider(base64Data: base64Data, url: url);

/// First letter for an initials fallback.
String initialOf(String s) =>
    s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();
