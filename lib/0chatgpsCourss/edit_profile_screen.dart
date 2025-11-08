import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../0chatgpsCourss/providers/user_provider.dart';
import '../0chatgpsCourss/services/auth_service.dart' show AuthService;
import 'services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  late final AuthService authService;
  late final FirestoreService firestoreService;
  late final User user;

  bool loading = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
    authService = AuthService();
    firestoreService = FirestoreService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await firestoreService.getUser(user.uid);

      if (userData != null && mounted) {
        setState(() {
          emailCtrl.text = userData.email;
          phoneCtrl.text = userData.phone ?? '';
          nameCtrl.text = userData.name;
        });
      } else {
        // Fallback sur les données Firebase Auth
        setState(() {
          emailCtrl.text = user.email ?? '';
          phoneCtrl.text = user.phoneNumber ?? '';
          nameCtrl.text = user.displayName ?? '';
        });
      }
    } catch (e) {
      print('Erreur chargement données: $e');
      // Fallback sur les données Firebase Auth
      if (mounted) {
        setState(() {
          emailCtrl.text = user.email ?? '';
          phoneCtrl.text = user.phoneNumber ?? '';
          nameCtrl.text = user.displayName ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    phoneCtrl.dispose();
    nameCtrl.dispose();
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      // Si l'email a changé
      if (emailCtrl.text.trim() != user.email) {
        if (currentPasswordCtrl.text.isEmpty) {
          throw FirebaseAuthException(
            code: 'requires-password',
            message: 'Le mot de passe actuel est requis pour changer l\'email',
          );
        }

        await authService.updateEmail(
          emailCtrl.text.trim(),
          currentPasswordCtrl.text,
        );
      }

      // Si changement de mot de passe
      if (_showPasswordFields && newPasswordCtrl.text.isNotEmpty) {
        if (currentPasswordCtrl.text.isEmpty) {
          throw FirebaseAuthException(
            code: 'requires-password',
            message: 'Le mot de passe actuel est requis',
          );
        }

        await authService.updatePassword(
          currentPasswordCtrl.text,
          newPasswordCtrl.text,
        );
      }

      // Mettre à jour le nom dans Firebase Auth
      if (nameCtrl.text.trim() != user.displayName) {
        await user.updateDisplayName(nameCtrl.text.trim());
        await user.reload();
      }

      // Mettre à jour Firestore via FirestoreService
      await firestoreService.updateUserFields(user.uid, {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
      });

      // Rafraîchir le UserProvider
      if (mounted) {
        await context.read<UserProviderGpt>().loadUser(user.uid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Profil mis à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser les champs de mot de passe
        currentPasswordCtrl.clear();
        newPasswordCtrl.clear();
        confirmPasswordCtrl.clear();
        setState(() => _showPasswordFields = false);
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

  String _getErrorMessage(String error) {
    if (error.contains('wrong-password')) {
      return 'Mot de passe actuel incorrect';
    } else if (error.contains('requires-recent-login')) {
      return 'Veuillez vous reconnecter pour cette opération';
    } else if (error.contains('email-already-in-use')) {
      return 'Cet email est déjà utilisé';
    } else if (error.contains('invalid-email')) {
      return 'Adresse email invalide';
    } else if (error.contains('weak-password')) {
      return 'Mot de passe trop faible (min. 6 caractères)';
    } else if (error.contains('network')) {
      return 'Erreur réseau. Vérifiez votre connexion';
    } else {
      return 'Erreur: $error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le profil"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                        child:
                            user.photoURL == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Nom
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Nom complet",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                  enabled: !loading,
                ),

                const SizedBox(height: 16),

                // Email
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

                // Téléphone
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Téléphone",
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  enabled: !loading,
                ),

                const SizedBox(height: 24),

                // Bouton changer mot de passe
                OutlinedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : () {
                            setState(() {
                              _showPasswordFields = !_showPasswordFields;
                            });
                          },
                  icon: Icon(
                    _showPasswordFields
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  label: const Text('Changer le mot de passe'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Champs mot de passe
                if (_showPasswordFields) ...[
                  const SizedBox(height: 16),

                  // Mot de passe actuel
                  TextFormField(
                    controller: currentPasswordCtrl,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: "Mot de passe actuel",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_showPasswordFields &&
                          (value == null || value.isEmpty)) {
                        return 'Mot de passe actuel requis';
                      }
                      return null;
                    },
                    enabled: !loading,
                  ),

                  const SizedBox(height: 16),

                  // Nouveau mot de passe
                  TextFormField(
                    controller: newPasswordCtrl,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: "Nouveau mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_showPasswordFields &&
                          value != null &&
                          value.isNotEmpty) {
                        if (value.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                      }
                      return null;
                    },
                    enabled: !loading,
                  ),

                  const SizedBox(height: 16),

                  // Confirmer mot de passe
                  TextFormField(
                    controller: confirmPasswordCtrl,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Confirmer le mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_showPasswordFields &&
                          newPasswordCtrl.text.isNotEmpty) {
                        if (value != newPasswordCtrl.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                      }
                      return null;
                    },
                    enabled: !loading,
                  ),
                ],

                const SizedBox(height: 32),

                // Bouton Enregistrer
                ElevatedButton(
                  onPressed: loading ? null : _save,
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
                            "Enregistrer les modifications",
                            style: TextStyle(fontSize: 16),
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
