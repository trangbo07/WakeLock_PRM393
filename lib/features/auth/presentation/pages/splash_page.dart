import 'package:flutter/material.dart';

/// Splash (STARTER SCAFFOLD for Dev 2).
///
/// Entry screen shown while deciding where to route (session-aware onboarding).
/// Replace with the real splash design; then route: signed-in → MainShell,
/// first launch → Onboarding, else → LoginPage.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm, size: 88, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('WakeLock', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Splash scaffold — thay bằng thiết kế thật',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
