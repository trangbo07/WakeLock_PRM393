import 'dart:math';

/// A single arithmetic question plus its correct answer.
class MathProblem {
  const MathProblem(this.question, this.answer);

  final String question;
  final int answer;
}

/// Generates arithmetic problems whose hardness scales with `difficulty`
/// (1–5). Pure/deterministic when given a seeded [Random] so it can be tested.
///
/// - difficulty 1–2: addition/subtraction of small numbers
/// - difficulty 3+: adds multiplication and larger operands
class MathProblemGenerator {
  MathProblemGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;

  MathProblem next(int difficulty) {
    final d = difficulty.clamp(1, 5);
    final useMultiply = d >= 3 && _random.nextBool();

    if (useMultiply) {
      final maxFactor = 2 + d; // d3 -> up to 5, d5 -> up to 7
      final a = _random.nextInt(maxFactor) + 2;
      final b = _random.nextInt(maxFactor) + 2;
      return MathProblem('$a × $b', a * b);
    }

    final maxOperand = d * 12; // d1 -> 12, d5 -> 60
    final a = _random.nextInt(maxOperand) + 1;
    final b = _random.nextInt(maxOperand) + 1;
    if (_random.nextBool()) {
      return MathProblem('$a + $b', a + b);
    }
    // Keep subtraction non-negative.
    final hi = max(a, b);
    final lo = min(a, b);
    return MathProblem('$hi − $lo', hi - lo);
  }

  /// [count] distinct problems to solve in a row.
  List<MathProblem> generate(int count, int difficulty) =>
      List.generate(count, (_) => next(difficulty));
}
