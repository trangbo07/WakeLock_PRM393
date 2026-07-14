import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';

/// Compact pill-shaped button that sizes to its content. Unlike a Material
/// button, it lays out safely as a non-flex child of a Row (no infinite-width).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = AppColors.primary,
    this.foreground = AppColors.onPrimary,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground, size: 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
