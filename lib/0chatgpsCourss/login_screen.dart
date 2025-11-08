import 'package:flutter/material.dart';

import '../0chatgpsCourss/services/auth_service.dart';
import '../PlatformUtils.dart';
import 'RegisterScreen.dart';
import 'forgot_password_screen.dart';
import 'phone_auth_screen.dart';
import 'screens.dart';
import 'services/firestore_service.dart';
import 'widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final authService = AuthService();
  final firestoreService = FirestoreService();

  bool loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validation du formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      final user = await authService.loginWithEmail(
        emailCtrl.text.trim(),
        passCtrl.text,
      );

      if (user != null && mounted) {
        final appUser = await firestoreService.getUser(user.uid);

        if (appUser != null && mounted) {
          // Navigation selon le rôle
          _navigateToHome(appUser.role);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => loading = true);

    try {
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        final appUser = await firestoreService.getUser(user.uid);

        if (appUser != null && mounted) {
          _navigateToHome(appUser.role);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur Google Sign-In: ${_getErrorMessage(e.toString())}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _navigateToHome(String role) {
    Widget homeScreen;

    switch (role) {
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Aucun compte trouvé avec cet email';
    } else if (error.contains('wrong-password')) {
      return 'Mot de passe incorrect';
    } else if (error.contains('invalid-email')) {
      return 'Adresse email invalide';
    } else if (error.contains('user-disabled')) {
      return 'Ce compte a été désactivé';
    } else if (error.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez plus tard';
    } else if (error.contains('network')) {
      return 'Erreur réseau. Vérifiez votre connexion';
    } else {
      return 'Une erreur est survenue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Logo ou titre
                const Icon(Icons.lock_outline, size: 80, color: Colors.blue),

                const SizedBox(height: 24),

                const Text(
                  'Bienvenue',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Connectez-vous à votre compte',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Champ Email
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email requis';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                  enabled: !loading,
                ),

                const SizedBox(height: 16),

                // Champ Mot de passe
                TextFormField(
                  controller: passCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mot de passe requis';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                  enabled: !loading,
                ),

                const SizedBox(height: 8),

                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        loading
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                    child: const Text("Mot de passe oublié ?"),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton Se connecter
                ElevatedButton(
                  onPressed: loading ? null : _login,
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
                            "Se connecter",
                            style: TextStyle(fontSize: 16),
                          ),
                ),

                const SizedBox(height: 24),

                // Divider "OU"
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OU"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Bouton Google Sign-In
                if (PlatformUtils.supportsPhoneAuth)
                  GoogleSignInButton(
                    onPressed: loading ? () {} : _loginWithGoogle,
                  ),

                const SizedBox(height: 16),

                // Bouton Connexion par téléphone
                if (PlatformUtils.supportsPhoneAuth)
                  OutlinedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PhoneAuthScreen(),
                                ),
                              );
                            },
                    icon: const Icon(Icons.phone),
                    label: const Text('Se connecter par téléphone'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Lien vers inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Pas de compte ? "),
                    TextButton(
                      onPressed:
                          loading
                              ? null
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                      child: const Text(
                        "Créer un compte",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Message informatif sur desktop
                if (PlatformUtils.isDesktop)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sur ${PlatformUtils.platformName}, seule l\'authentification '
                      'par email/mot de passe est disponible.',
                      style: TextStyle(color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
