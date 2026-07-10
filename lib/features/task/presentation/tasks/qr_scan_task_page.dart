import 'package:flutter/material.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

/// Scan a specific QR code (e.g. taped in the bathroom) to dismiss.
/// TODO: embed a MobileScanner view; compare the decoded value against
/// [DismissTaskConfig.qrPayload]; pop success only on a match.
class QrScanTaskPage extends StatelessWidget {
  const QrScanTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR để tắt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TODO: quét mã "${config.qrPayload ?? 'chưa đặt'}"'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, const TaskResult.success()),
              child: const Text('(tạm) Hoàn thành'),
            ),
          ],
        ),
      ),
    );
  }
}
