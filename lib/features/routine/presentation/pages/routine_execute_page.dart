import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/routine.dart';
import '../providers/routine_providers.dart';

/// Runs a routine's steps in order after a successful alarm dismiss. Each
/// step either has a countdown (if `durationSeconds > 0`) or a manual "Xong"
/// button. Pops `true` if all steps were completed, `false` if the user
/// backed out early — either way this is a bonus flow, never blocking.
class RoutineExecutePage extends ConsumerStatefulWidget {
  const RoutineExecutePage({super.key, required this.routineId});

  final String routineId;

  @override
  ConsumerState<RoutineExecutePage> createState() => _RoutineExecutePageState();
}

class _RoutineExecutePageState extends ConsumerState<RoutineExecutePage> {
  final DateTime _startedAt = DateTime.now();
  int _index = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  MorningRoutine? _routine;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final routine = await ref.read(routineRepositoryProvider).getRoutineById(widget.routineId);
    if (!mounted) return;
    if (routine == null || routine.steps.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      _routine = routine;
      _loading = false;
    });
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    final step = _routine?.steps[_index];
    if (step == null || step.durationSeconds <= 0) return;
    _remainingSeconds = step.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        _nextStep();
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  Future<void> _nextStep() async {
    final routine = _routine;
    if (routine == null) return;
    if (_index + 1 >= routine.steps.length) {
      await ref.read(routineRepositoryProvider).logRun(
            routine.id,
            stepsDone: routine.steps.length,
            stepsTotal: routine.steps.length,
            startedAt: _startedAt,
            completedAt: DateTime.now(),
          );
      if (mounted) Navigator.pop(context, true);
      return;
    }
    setState(() => _index += 1);
    _startTimerIfNeeded();
  }

  Future<void> _skipAll() async {
    final routine = _routine;
    if (routine != null) {
      await ref.read(routineRepositoryProvider).logRun(
            routine.id,
            stepsDone: _index,
            stepsTotal: routine.steps.length,
            startedAt: _startedAt,
          );
    }
    if (mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _routine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final routine = _routine!;
    final step = routine.steps[_index];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name.isEmpty ? 'Routine' : routine.name),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(onPressed: _skipAll, child: const Text('Bỏ qua')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bước ${_index + 1}/${routine.steps.length}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(step.type.label, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            if (step.durationSeconds > 0)
              Text('$_remainingSeconds s', style: theme.textTheme.displaySmall)
            else
              FilledButton(onPressed: _nextStep, child: const Text('Xong')),
          ],
        ),
      ),
    );
  }
}
