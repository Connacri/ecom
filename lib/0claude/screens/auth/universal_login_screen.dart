import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/enhanced_auth_service.dart';
import '../../universelle/forgot_password.dart';
import '../../universelle/qr/QRScannerScreen.dart';
import '../../universelle/signup_screen.dart';

/// Écran de connexion universel intelligent
class UniversalLoginScreen extends StatefulWidget {
  const UniversalLoginScreen({super.key});

  @override
  State<UniversalLoginScreen> createState() => _UniversalLoginScreenState();
}

class _UniversalLoginScreenState extends State<UniversalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _authService = EnhancedAuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;
  AuthIdentifierResult? _identifierResult;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Vérifier l'identifiant en temps réel
  Future<void> _checkIdentifier() async {
    final identifier = _identifierCtrl.text.trim();

    if (identifier.isEmpty) {
      setState(() {
        _identifierResult = null;
        _isSignUp = false;
      });
      return;
    }

    try {
      final result = await _authService.checkIdentifier(identifier);

      setState(() {
        _identifierResult = result;
        _isSignUp = !result.exists;
      });

      if (result.exists) {
        print('✅ Compte trouvé - Mode connexion');
      } else {
        print('ℹ️ Nouveau compte - Mode inscription');
      }
    } catch (e) {
      print('❌ Erreur vérification: $e');
    }
  }

  /// Connexion ou inscription
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      if (_isSignUp) {
        // INSCRIPTION
        await _navigateToSignUp();
      } else {
        // CONNEXION
        final user = await _authService.signInWithPassword(
          identifier: _identifierCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

        if (user != null && mounted) {
          _navigateToHome();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(_getFirebaseErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Connexion avec Google
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur Google Sign-In: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Scanner un QR Code pour se connecter
  Future<void> _scanQRCode() async {
    // Navigation vers l'écran de scan QR
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _navigateToSignUp() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => SignUpScreen(initialIdentifier: _identifierCtrl.text.trim()),
      ),
    );

    if (result == true && mounted) {
      _navigateToHome();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Compte désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Erreur: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                const Icon(Icons.lock_outline, size: 80, color: Colors.blue),

                const SizedBox(height: 24),

                // Titre dynamique
                Text(
                  _isSignUp ? 'Créer un compte' : 'Connexion',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  _isSignUp
                      ? 'Commencez votre aventure'
                      : 'Bienvenue, connectez-vous',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Champ identifiant universel
                TextFormField(
                  controller: _identifierCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email, Username ou Téléphone',
                    hintText: 'example@mail.com',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon:
                        _identifierResult != null
                            ? Icon(
                              _identifierResult!.exists
                                  ? Icons.check_circle
                                  : Icons.add_circle,
                              color:
                                  _identifierResult!.exists
                                      ? Colors.green
                                      : Colors.orange,
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) {
                    // Vérifier après 500ms d'inactivité
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _checkIdentifier();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Identifiant requis';
                    }
                    return null;
                  },
                  enabled: !_loading,
                ),

                const SizedBox(height: 16),

                // Message d'information
                if (_identifierResult != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _identifierResult!.exists
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _identifierResult!.exists
                                ? Colors.green
                                : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _identifierResult!.exists
                              ? Icons.login
                              : Icons.person_add,
                          color:
                              _identifierResult!.exists
                                  ? Colors.green
                                  : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _identifierResult!.exists
                                ? 'Compte trouvé - Entrez votre mot de passe'
                                : 'Nouveau compte - Cliquez pour créer',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  _identifierResult!.exists
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Champ mot de passe (visible si compte existe)
                if (_identifierResult?.exists ?? false)
                  Column(
                    children: [
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
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
                          if (_identifierResult?.exists ?? false) {
                            if (value == null || value.isEmpty) {
                              return 'Mot de passe requis';
                            }
                          }
                          return null;
                        },
                        enabled: !_loading,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              _loading
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Bouton principal
                ElevatedButton(
                  onPressed: _loading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _loading
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
                          : Text(
                            _isSignUp ? 'Créer un compte' : 'Se connecter',
                            style: const TextStyle(fontSize: 16),
                          ),
                ),

                const SizedBox(height: 24),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OU'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Bouton Google
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text('Continuer avec Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bouton QR Code
                OutlinedButton.icon(
                  onPressed: _loading ? null : _scanQRCode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner un QR Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Conditions d'utilisation
                Text(
                  'En continuant, vous acceptez nos Conditions d\'utilisation '
                  'et notre Politique de confidentialité',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
