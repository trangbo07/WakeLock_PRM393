import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/task/domain/math_problem_generator.dart';

void main() {
  test('generate returns `count` problems', () {
    final gen = MathProblemGenerator(Random(1));
    expect(gen.generate(3, 3), hasLength(3));
    expect(gen.generate(5, 5), hasLength(5));
  });

  test('every generated answer matches its expression', () {
    final gen = MathProblemGenerator(Random(42));
    for (var d = 1; d <= 5; d++) {
      for (final p in gen.generate(20, d)) {
        expect(_eval(p.question), p.answer, reason: p.question);
      }
    }
  });

  test('subtraction never goes negative', () {
    final gen = MathProblemGenerator(Random(7));
    for (final p in gen.generate(50, 4)) {
      expect(p.answer, greaterThanOrEqualTo(0), reason: p.question);
    }
  });
}

/// Evaluate the tiny "a OP b" strings the generator produces (× − +).
int _eval(String q) {
  for (final op in ['×', '−', '+']) {
    if (q.contains(op)) {
      final parts = q.split(op).map((s) => int.parse(s.trim())).toList();
      switch (op) {
        case '×':
          return parts[0] * parts[1];
        case '−':
          return parts[0] - parts[1];
        case '+':
          return parts[0] + parts[1];
      }
    }
  }
  throw ArgumentError('no operator in "$q"');
}
