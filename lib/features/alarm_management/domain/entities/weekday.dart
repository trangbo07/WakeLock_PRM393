/// Days of the week for alarm repetition.
///
/// [value] matches Dart's `DateTime.weekday` (Mon=1 .. Sun=7) so scheduling
/// math can compare directly.
enum Weekday {
  monday(1, 'T2'),
  tuesday(2, 'T3'),
  wednesday(3, 'T4'),
  thursday(4, 'T5'),
  friday(5, 'T6'),
  saturday(6, 'T7'),
  sunday(7, 'CN');

  const Weekday(this.value, this.shortLabel);

  final int value;
  final String shortLabel;

  static Weekday fromValue(int v) =>
      Weekday.values.firstWhere((w) => w.value == v);
}
