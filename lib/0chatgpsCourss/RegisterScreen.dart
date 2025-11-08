import 'package:flutter/material.dart';

import '../0chatgpsCourss/services/auth_service.dart';
import '../activities/modèles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _selectedRole = lesRoles.first;
  bool _loading = false;

  final AuthService _auth = AuthService();

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        role: _selectedRole,
        name: _nameCtrl.text.trim(),
      );
      if (user != null) {
        // navigation gérée par main.dart stream
        Navigator.of(context).pop();
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items:
                  lesRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
              onChanged:
                  (v) => setState(() => _selectedRole = v ?? lesRoles.first),
              decoration: const InputDecoration(labelText: 'Rôle'),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text('S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
