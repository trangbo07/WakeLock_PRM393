import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

/// Profile tab root — profile, achievements, calendar, settings. Owned by Dev 2.
/// Replace the body with the real screen when building the Profile feature.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonView(
        title: 'Hồ sơ',
        icon: Icons.person_outline,
        message: 'Thành tích, lịch, huy hiệu và cài đặt của bạn.',
      );
}
