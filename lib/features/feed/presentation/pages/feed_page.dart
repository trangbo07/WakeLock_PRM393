import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

/// Feed tab root — Locket-style morning-photo feed. Owned by Dev 2.
/// Replace the body with the real feed when building the Feed feature.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonView(
        title: 'Feed',
        icon: Icons.photo_library_outlined,
        message: 'Ảnh buổi sáng của bạn bè (kiểu Locket) sẽ xuất hiện ở đây.',
      );
}
