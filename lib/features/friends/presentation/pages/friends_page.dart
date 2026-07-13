import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

/// Friends tab root — friends, streak sharing, challenges. Owned by Dev 2.
/// Replace the body with the real screen when building the Friends feature.
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonView(
        title: 'Bạn bè',
        icon: Icons.group_outlined,
        message: 'Kết bạn, xem streak chung và rủ nhau tham gia thử thách.',
      );
}
