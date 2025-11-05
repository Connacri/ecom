import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'AuthProvider.dart';

class LoginForm extends StatefulWidget {
  final AuthService authService;
  const LoginForm({super.key, required this.authService});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await widget.authService.signInWithGoogle(); // Option Google
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: _loading ? null : _login,
          icon: const Icon(FontAwesomeIcons.google),
          label: Text(_loading ? 'Connexion...' : 'Connexion avec Google'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: Colors.redAccent,
          ),
        ),
      ],
    );
  }
}
