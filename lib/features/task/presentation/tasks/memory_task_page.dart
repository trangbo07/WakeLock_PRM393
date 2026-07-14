import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

/// Flip cards to find all [DismissTaskConfig.memoryPairs] matching pairs.
/// A mismatch just flips back — no fail state, only takes longer.
class MemoryTaskPage extends StatefulWidget {
  const MemoryTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  State<MemoryTaskPage> createState() => _MemoryTaskPageState();
}

class _MemoryTaskPageState extends State<MemoryTaskPage> {
  static const _icons = [
    Icons.star,
    Icons.favorite,
    Icons.pets,
    Icons.anchor,
    Icons.cake,
    Icons.beach_access,
    Icons.bolt,
    Icons.brush,
    Icons.eco,
    Icons.emoji_emotions,
    Icons.umbrella,
    Icons.wb_sunny,
  ];

  late final List<IconData> _cards;
  late final List<bool> _revealed;
  late final List<bool> _matched;
  int? _firstIndex;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final pairs = widget.config.memoryPairs.clamp(2, _icons.length);
    final chosenIcons = (_icons.toList()..shuffle(Random())).take(pairs).toList();
    final deck = <IconData>[for (final icon in chosenIcons) ...[icon, icon]]..shuffle(Random());
    _cards = deck;
    _revealed = List.filled(deck.length, false);
    _matched = List.filled(deck.length, false);
  }

  void _tap(int index) {
    if (_busy || _revealed[index] || _matched[index]) return;
    setState(() => _revealed[index] = true);

    final first = _firstIndex;
    if (first == null) {
      _firstIndex = index;
      return;
    }
    _firstIndex = null;

    if (_cards[first] == _cards[index]) {
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
      });
      if (_matched.every((m) => m)) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.pop(context, const TaskResult.success());
        });
      }
      return;
    }

    setState(() => _busy = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _revealed[first] = false;
        _revealed[index] = false;
        _busy = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchedCount = _matched.where((m) => m).length ~/ 2;
    final totalPairs = _cards.length ~/ 2;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ghi nhớ ($matchedCount/$totalPairs cặp)'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _cards.length,
          itemBuilder: (_, i) {
            final show = _revealed[i] || _matched[i];
            return GestureDetector(
              onTap: () => _tap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _matched[i]
                      ? Colors.green.withValues(alpha: 0.35)
                      : (show ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: show ? Icon(_cards[i], size: 28) : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
