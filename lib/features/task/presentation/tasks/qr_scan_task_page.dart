import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

/// Scan a specific QR code (e.g. taped in the bathroom) to dismiss. Success
/// only when the decoded value equals [DismissTaskConfig.qrPayload]; any other
/// code shows a hint and keeps scanning.
class QrScanTaskPage extends StatefulWidget {
  const QrScanTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  State<QrScanTaskPage> createState() => _QrScanTaskPageState();
}

class _QrScanTaskPageState extends State<QrScanTaskPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _done = false;
  bool _mismatch = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final expected = widget.config.qrPayload;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;
      if (expected == null || expected.isEmpty || value == expected) {
        _done = true;
        _controller.dispose();
        Navigator.pop(context, const TaskResult.success());
        return;
      }
    }
    if (!_mismatch) setState(() => _mismatch = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR để tắt'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.all(16),
            child: Text(
              _mismatch
                  ? 'Sai mã QR — tìm đúng mã đã dán'
                  : 'Đưa camera vào mã QR đã dán sẵn',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
