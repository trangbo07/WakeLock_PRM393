import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

/// Habit tab root — habit tracker, dashboard, AI coach. Owned by Dev 1.
/// Replace the body with the real screen when building the Habit feature.
class HabitPage extends StatelessWidget {
  const HabitPage({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonView(
        title: 'Thói quen',
        icon: Icons.check_circle_outline,
        message: 'Theo dõi thói quen, dashboard thống kê và AI Coach.',
      );
}
