import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';
import '../../domain/math_problem_generator.dart';

/// Solve [DismissTaskConfig.difficulty] math problems in a row to dismiss.
/// A wrong answer does not fail the alarm — it just doesn't advance, so the
/// user is stuck until every problem is answered correctly.
class MathTaskPage extends StatefulWidget {
  const MathTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  State<MathTaskPage> createState() => _MathTaskPageState();
}

class _MathTaskPageState extends State<MathTaskPage> {
  late final List<MathProblem> _problems;
  final TextEditingController _controller = TextEditingController();
  int _index = 0;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _problems =
        MathProblemGenerator().generate(widget.config.difficulty, widget.config.difficulty);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final entered = int.tryParse(_controller.text.trim());
    if (entered == null) return;
    if (entered != _problems[_index].answer) {
      setState(() => _wrong = true);
      _controller.clear();
      return;
    }
    if (_index + 1 >= _problems.length) {
      Navigator.pop(context, const TaskResult.success());
      return;
    }
    setState(() {
      _index++;
      _wrong = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problems[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('Giải toán (${_index + 1}/${_problems.length})'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${problem.question} = ?',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Đáp án',
                errorText: _wrong ? 'Sai rồi, thử lại' : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Kiểm tra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
