import 'package:flutter/material.dart';

import '../0chatgpsCourss/services/auth_service.dart';
import 'verify_code_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final phoneCtrl = TextEditingController();
  final authService = AuthService();

  bool loading = false;

  Future<void> _sendCode() async {
    if (phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer votre numéro de téléphone."),
        ),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await authService.verifyPhoneNumber(phoneCtrl.text, (verificationId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(verificationId: verificationId),
          ),
        );
      });
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
      appBar: AppBar(title: const Text("Connexion par téléphone")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Numéro de téléphone (+213...)",
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _sendCode,
              child:
                  loading
                      ? const CircularProgressIndicator()
                      : const Text("Envoyer le code"),
            ),
          ],
        ),
      ),
    );
  }
}
