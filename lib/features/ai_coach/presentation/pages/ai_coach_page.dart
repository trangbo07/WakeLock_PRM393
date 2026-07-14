import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_coach_providers.dart';

/// A single coaching tip card, generated from the user's recent wake/habit
/// stats. "Làm mới" regenerates it — no chat history is kept.
class AiCoachPage extends ConsumerWidget {
  const AiCoachPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(aiCoachTipProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology, size: 48),
                  const SizedBox(height: 16),
                  tipAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const Text('Không tải được gợi ý, thử lại nhé.'),
                    data: (tip) => Text(
                      tip,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(aiCoachTipProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Làm mới'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
