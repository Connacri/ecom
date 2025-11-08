import 'package:flutter/material.dart';

import '../0chatgpsCourss/services/auth_service.dart';
import 'screens.dart';
import 'services/firestore_service.dart'; // Importer vos écrans d'accueil

class VerifyCodeScreen extends StatefulWidget {
  final String verificationId;
  const VerifyCodeScreen({super.key, required this.verificationId});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final codeCtrl = TextEditingController();
  final authService = AuthService();
  final firestoreService = FirestoreService();

  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    // Validation du code
    if (codeCtrl.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Veuillez entrer le code';
      });
      return;
    }

    if (codeCtrl.text.trim().length != 6) {
      setState(() {
        errorMessage = 'Le code doit contenir 6 chiffres';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // Vérifier le code SMS
      final user = await authService.verifySmsCode(
        widget.verificationId,
        codeCtrl.text.trim(),
      );

      if (user != null && mounted) {
        // Récupérer les informations utilisateur depuis Firestore
        final appUser = await firestoreService.getUser(user.uid);

        if (appUser != null && mounted) {
          // Navigation selon le rôle
          Widget homeScreen;

          switch (appUser.role) {
            case 'admin':
              homeScreen = const AdminHome();
              break;
            case 'club':
            case 'association':
            case 'ecole':
              homeScreen = const HomeClub();
              break;
            case 'professeur':
            case 'coach':
            case 'animateur':
              homeScreen = const HomeProf();
              break;
            case 'parent':
            default:
              homeScreen = const HomeParent();
              break;
          }

          // Navigation avec suppression de toutes les routes précédentes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => homeScreen),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('invalid-verification-code')) {
      return 'Code de vérification invalide';
    } else if (error.contains('session-expired')) {
      return 'La session a expiré. Veuillez recommencer';
    } else if (error.contains('network')) {
      return 'Erreur réseau. Vérifiez votre connexion';
    } else {
      return 'Erreur: $error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérifier le code"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sms_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 24),

            const Text(
              'Entrez le code à 6 chiffres',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Un code de vérification a été envoyé par SMS',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: "Code SMS",
                prefixIcon: const Icon(Icons.pin),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "",
                errorText: errorMessage,
              ),
              enabled: !loading,
              onSubmitted: (_) => _verifyCode(),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: loading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  loading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        "Vérifier et continuer",
                        style: TextStyle(fontSize: 16),
                      ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed:
                  loading
                      ? null
                      : () {
                        Navigator.pop(context);
                      },
              child: const Text("Renvoyer le code"),
            ),
          ],
        ),
      ),
    );
  }
}
