import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_permission.dart';

/// On the very first launch, ask for every hardcore permission once so the
/// alarm can actually do its job. A marker file records that onboarding ran, so
/// later launches don't nag — the user can still change any permission anytime
/// from the Settings screen.
Future<void> runFirstLaunchPermissionOnboarding() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final marker = File('${dir.path}/.permissions_onboarded');
    if (marker.existsSync()) return;

    // Sequentially so each system dialog / settings screen is handled in turn.
    for (final permission in AppPermission.values) {
      try {
        await permission.request();
      } catch (_) {
        // A permission that isn't requestable on this device shouldn't block
        // the rest.
      }
    }

    marker.createSync(recursive: true);
  } catch (_) {
    // Non-Android host / storage issue — onboarding is best-effort.
  }
}
