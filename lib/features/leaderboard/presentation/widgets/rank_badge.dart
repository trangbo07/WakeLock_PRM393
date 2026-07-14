import 'package:flutter/material.dart';

/// Metallic gradient per podium rank (gold / silver / bronze), slate otherwise.
List<Color> rankGradient(int rank) => switch (rank) {
      1 => const [Color(0xFFFDE68A), Color(0xFFF59E0B)],
      2 => const [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
      3 => const [Color(0xFFFCD9A8), Color(0xFFC77B30)],
      _ => const [Color(0xFF334155), Color(0xFF1E293B)],
    };

/// Circular rank badge with a metallic gradient and the rank number.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.size = 30});

  final int rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = rankGradient(rank);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          color: rank <= 3 ? const Color(0xFF1E293B) : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
