import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/bootstrap.dart';

/// App entry point. All heavy platform/service initialization lives in
/// [bootstrap] so this stays trivial and testable.
Future<void> main() async {
  await bootstrap();
  runApp(const ProviderScope(child: WakeLockApp()));
}
