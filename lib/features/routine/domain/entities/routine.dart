import 'package:equatable/equatable.dart';

/// A step type in a morning routine. Stored as the enum name in
/// routine_steps.type (SQLite). Add new kinds here as UIs are built.
enum RoutineStepType { water, teeth, stretch, meditate, journal, tasks, pomodoro }

/// One step of a routine (e.g. "drink water", "meditate 5 min").
class RoutineStep extends Equatable {
  const RoutineStep({
    required this.id,
    required this.type,
    this.position = 0,
    this.durationSeconds = 0,
    this.config = const {},
  });

  final String id;
  final RoutineStepType type;

  /// Display order within the routine (0-based).
  final int position;

  /// Optional per-step duration (0 = no timer). Pomodoro/meditation use this.
  final int durationSeconds;

  /// Free-form per-step config (JSON in SQLite), e.g. water amount, journal prompt.
  final Map<String, dynamic> config;

  RoutineStep copyWith({
    RoutineStepType? type,
    int? position,
    int? durationSeconds,
    Map<String, dynamic>? config,
  }) =>
      RoutineStep(
        id: id,
        type: type ?? this.type,
        position: position ?? this.position,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        config: config ?? this.config,
      );

  @override
  List<Object?> get props => [id, type, position, durationSeconds, config];
}

/// A named, reorderable list of steps run after the alarm is dismissed.
class MorningRoutine extends Equatable {
  const MorningRoutine({
    required this.id,
    required this.createdAt,
    this.name = '',
    this.isEnabled = true,
    this.steps = const [],
  });

  final String id;
  final String name;
  final bool isEnabled;
  final List<RoutineStep> steps;
  final DateTime createdAt;

  MorningRoutine copyWith({
    String? name,
    bool? isEnabled,
    List<RoutineStep>? steps,
  }) =>
      MorningRoutine(
        id: id,
        createdAt: createdAt,
        name: name ?? this.name,
        isEnabled: isEnabled ?? this.isEnabled,
        steps: steps ?? this.steps,
      );

  @override
  List<Object?> get props => [id, name, isEnabled, steps, createdAt];
}
