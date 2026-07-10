// Backend-free smoke tests. The home screen depends on Supabase (initialized
// in bootstrap), so these exercise pure widgets/logic that need no backend.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/core/utils/date_time_utils.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/entities/weekday.dart';
import 'package:wakelock_prm393/shared/widgets/app_primary_button.dart';

void main() {
  testWidgets('AppPrimaryButton renders its label and fires onPressed',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Tắt báo thức',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Tắt báo thức'), findsOneWidget);
    await tester.tap(find.byType(AppPrimaryButton));
    expect(tapped, isTrue);
  });

  test('nextOccurrence rolls a passed one-shot time to tomorrow', () {
    final from = DateTime(2026, 7, 10, 8, 0); // 08:00
    final next = DateTimeUtils.nextOccurrence(7, 0, const {}, from: from);
    expect(next, DateTime(2026, 7, 11, 7, 0));
  });

  test('nextOccurrence respects repeat days', () {
    // From Friday 2026-07-10, next Monday alarm at 06:30.
    final from = DateTime(2026, 7, 10, 8, 0);
    final next = DateTimeUtils.nextOccurrence(
      6,
      30,
      const {Weekday.monday},
      from: from,
    );
    expect(next, DateTime(2026, 7, 13, 6, 30));
  });
}
