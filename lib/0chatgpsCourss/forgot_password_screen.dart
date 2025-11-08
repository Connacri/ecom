import 'package:flutter/material.dart';

import '../0chatgpsCourss/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  final authService = AuthService();
  bool loading = false;

  Future<void> _resetPassword() async {
    if (emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer votre adresse e-mail.")),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await authService.resetPassword(emailCtrl.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de réinitialisation envoyé !")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mot de passe oublié")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Adresse e-mail",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _resetPassword,
              child:
                  loading
                      ? const CircularProgressIndicator()
                      : const Text("Envoyer le lien"),
            ),
          ],
        ),
      ),
    );
  }
}
