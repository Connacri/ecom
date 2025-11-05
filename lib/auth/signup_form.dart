import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'AuthProvider.dart';

class SignupForm extends StatefulWidget {
  final AuthService authService;
  const SignupForm({super.key, required this.authService});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );
      await credential.user?.updateDisplayName(_nameCtrl.text);
      await createUserInSupabase(credential.user!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé avec succès !')),
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
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Nom complet'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mot de passe'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _signUp,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(_loading ? 'Création...' : 'Créer un compte'),
        ),
      ],
    );
  }
}
