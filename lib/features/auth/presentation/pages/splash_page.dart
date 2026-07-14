import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';

/// Branded launch screen. Purely visual — routing is handled by RootGate
/// (it swaps to MainShell after a beat, without touching the navigator, so the
/// alarm ring-launch flow is unaffected).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<double> _scale =
      Tween<double>(begin: 0.9, end: 1).animate(
    CurvedAnimation(parent: _c, curve: AppMotion.easeOutExpo),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Respect reduced-motion: show the final frame with no animation.
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg + 8),
          ),
          child: const Icon(Icons.alarm, size: 52, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'WakeLock',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Báo thức không thể trốn',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );

    if (!reduceMotion) {
      content = FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _scale, child: content),
      );
    }

    return Scaffold(
      body: Center(child: content),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: SizedBox(
          height: 24,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
