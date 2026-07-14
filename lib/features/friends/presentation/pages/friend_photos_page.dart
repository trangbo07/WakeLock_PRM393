import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';

/// Grid of a friend's shared morning photos. Uses placeholder imagery until
/// Dev 1's Morning Photo feed is integrated (photos keyed by uid + index).
class FriendPhotosPage extends StatelessWidget {
  const FriendPhotosPage({
    super.key,
    required this.uid,
    required this.count,
    required this.title,
  });

  final String uid;
  final int count;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = count > 60 ? 60 : count; // cap for display
    return Scaffold(
      appBar: AppBar(title: Text('Ảnh buổi sáng · $title')),
      body: n == 0
          ? Center(
              child: Text('Chưa có ảnh',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
              ),
              itemCount: n,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(
                  'https://picsum.photos/seed/$uid$i/300',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceMuted,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.mutedForeground),
                  ),
                ),
              ),
            ),
    );
  }
}
