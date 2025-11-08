import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleSignInButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      icon: Image.asset('assets/google_logo.png', height: 24, width: 24),
      label: const Text('Se connecter avec Google'),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
    );
  }
}
