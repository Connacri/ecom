import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'AuthProvider.dart';

class ForgotPasswordForm extends StatefulWidget {
  final AuthService authService;
  const ForgotPasswordForm({super.key, required this.authService});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _resetPassword() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(
            _loading ? 'Envoi...' : 'Envoyer le lien de réinitialisation',
          ),
        ),
      ],
    );
  }
}
