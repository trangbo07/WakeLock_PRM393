// Ringing screen flow with an easy (tap-to-dismiss) task. Platform plugins
// (audio, notifications, volume lock) are absent on the test host — the page
// guards every call, so the UI flow must still work end-to-end.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/entities/alarm.dart';
import 'package:wakelock_prm393/features/alarm_ringing/presentation/pages/alarm_ringing_page.dart';
import 'package:wakelock_prm393/features/task/domain/entities/dismiss_task.dart';

void main() {
  testWidgets('completing the dismiss task pops the ringing screen',
      (tester) async {
    const alarm = Alarm(
      id: 'r1',
      label: 'Dậy!',
      hour: 6,
      minute: 30,
      volumeLock: false,
      dismissTask: DismissTaskConfig.easy,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AlarmRingingPage(alarm: alarm),
                  ),
                ),
                child: const Text('ring'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ring'));
    await tester.pumpAndSettle();

    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('Dậy!'), findsOneWidget);

    // Back button is blocked while ringing.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('06:30'), findsOneWidget);

    // Dismiss → TaskRunner (easy task) → tap → back past the ringing screen.
    await tester.tap(find.text('Tắt báo thức'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tắt báo thức')); // easy-task confirm button
    await tester.pumpAndSettle();

    expect(find.text('ring'), findsOneWidget);
    expect(find.text('06:30'), findsNothing);
  });
}
