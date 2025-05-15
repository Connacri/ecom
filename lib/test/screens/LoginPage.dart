// login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import 'RoleSelectionPage.dart';

// login_page.dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) {
    final auth = ctx.read<AuthService>();
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Image.asset('assets/google_logo.png', height: 24),
          label: const Text('Se connecter avec Google'),
          onPressed: () async {
            final result = await auth.signInWithGoogle();
            if (result?.user != null) {
              // 🔥 Navigation manuelle immédiate
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
              );
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text("Échec de la connexion Google")),
              );
            }
          },
        ),
      ),
    );
  }
}
