// Math dismiss task: must answer all problems correctly to pop success.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/task/domain/entities/dismiss_task.dart';
import 'package:wakelock_prm393/features/task/domain/entities/task_result.dart';
import 'package:wakelock_prm393/features/task/presentation/tasks/math_task_page.dart';

void main() {
  // Read the currently displayed problem "a OP b = ?" and compute its answer.
  int currentAnswer(WidgetTester tester) {
    final text =
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).firstWhere(
              (d) => d != null && d.contains('= ?'),
            )!;
    final expr = text.replaceAll('= ?', '').trim();
    for (final op in ['×', '−', '+']) {
      if (expr.contains(op)) {
        final p = expr.split(op).map((s) => int.parse(s.trim())).toList();
        if (op == '×') return p[0] * p[1];
        if (op == '−') return p[0] - p[1];
        return p[0] + p[1];
      }
    }
    throw StateError('no problem shown');
  }

  testWidgets('wrong answer shows error and does not advance', (tester) async {
    TaskResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.push<TaskResult>(
              context,
              MaterialPageRoute(
                builder: (_) => const MathTaskPage(
                  config: DismissTaskConfig(
                    type: DismissTaskType.math,
                    difficulty: 1,
                  ),
                ),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final answer = currentAnswer(tester);
    await tester.enterText(find.byType(TextField), '${answer + 1}');
    await tester.tap(find.text('Kiểm tra'));
    await tester.pumpAndSettle();

    expect(find.text('Sai rồi, thử lại'), findsOneWidget);
    expect(result, isNull); // still on the task
  });

  testWidgets('answering all problems correctly pops success', (tester) async {
    TaskResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.push<TaskResult>(
              context,
              MaterialPageRoute(
                builder: (_) => const MathTaskPage(
                  config: DismissTaskConfig(
                    type: DismissTaskType.math,
                    difficulty: 2, // 2 problems
                  ),
                ),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // difficulty 2 -> 2 problems in a row.
    for (var i = 0; i < 2; i++) {
      await tester.enterText(find.byType(TextField), '${currentAnswer(tester)}');
      await tester.tap(find.text('Kiểm tra'));
      await tester.pumpAndSettle();
    }

    expect(result?.completed, isTrue);
  });
}
