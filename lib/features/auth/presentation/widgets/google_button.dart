import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

/// Full-width "Continue with Google" outlined button. Uses the Material "G"
/// glyph (no emoji) to stay on-style; wire [onPressed] to the Google flow.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.g_mobiledata, size: 30),
        label: const Text('Tiếp tục với Google'),
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
