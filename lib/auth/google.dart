import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

import '../activities/modèles.dart';
import '../activities/screens/userHomePage.dart';
import '../fonctions/AppLocalizations.dart';
import '../pages/MyApp.dart';
import 'AuthProvider.dart';

class google extends StatefulWidget {
  @override
  _googleState createState() => _googleState();
}

class _googleState extends State<google> {
  final AuthService _authService = AuthService();
  User? _user;
  bool isLoading = false;
  bool isSigningOut = false;
  int _selectedTab = 0; // ✅ déplacé ici
  bool _loading = false; // ✅ déplacé ici
  List<Map<String, dynamic>> _reportedNumbers = [];

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _setupAuthListener();
  }

  void _switchTab(int index) {
    setState(() => _selectedTab = index);
  }

  Future<void> _handleSignIn() async {
    setState(() => isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) return;

      final uid = user.uid;
      final docRef = FirebaseFirestore.instance
          .collection('userModel')
          .doc(uid);
      final snapshot = await docRef.get();

      final data = {
        'name': user.displayName ?? 'Utilisateur',
        'email': user.email ?? '',
        'photos': user.photoURL != null ? [user.photoURL!] : [],
        'lastLogin': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        await docRef.set({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'editedAt': FieldValue.serverTimestamp(),
          'phone': '',
          'gender': '',
          'courses': [],
          'role': 'sero',
        }, SetOptions(merge: true));
      } else {
        await docRef.update(data);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion : $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleEmailSignIn() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connexion réussie')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSignUp() async {
    setState(() => _loading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailCtrl.text.trim(),
            password: passCtrl.text.trim(),
          );
      await userCredential.user?.updateDisplayName(nameCtrl.text.trim());
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

  Future<void> _resetPassword() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailCtrl.text.trim(),
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

  Future<void> _handleSignOut() async {
    setState(() => isSigningOut = true);

    try {
      // On attend que les deux futures se terminent : la déconnexion + le délai
      await Future.wait([
        _authService.signOut(),
        Future.delayed(const Duration(seconds: 2)), // 👈 délai imposé
      ]);
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp1()));
      setState(() {
        _user = null;
        _reportedNumbers.clear();
      });
    } catch (e) {
      print('Erreur déconnexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('connexErreur')),
        ),
      );
    } finally {
      setState(() => isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child:
            isLoading
                ? CircularProgressIndicator()
                : _user == null
                ? _buildLoginUI(context)
                : _buildProfileUI(), //HomeScreenAct(),
        //_buildProfileUI(),
      ),
    );
  }

  // ✅ UI Login corrigée
  Widget _buildLoginUI(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lotties/boost (10).json',
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Text(
                  "Connectez-vous pour accéder à votre espace".toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ToggleButtons(
                isSelected: [
                  _selectedTab == 0,
                  _selectedTab == 1,
                  _selectedTab == 2,
                ],
                onPressed: _switchTab,
                borderRadius: BorderRadius.circular(12),
                selectedColor: theme.colorScheme.onPrimary,
                fillColor: theme.primaryColor,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Connexion'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Inscription'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Oublié'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_selectedTab == 0) ...[
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _handleEmailSignIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(_loading ? 'Connexion...' : 'Connexion'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4.0,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(FontAwesomeIcons.google, color: Colors.red),
                  label: const Text(
                    'Google',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  onPressed: _handleSignIn,
                ),
              ] else if (_selectedTab == 1) ...[
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(_loading ? 'Création...' : 'Créer un compte'),
                ),
              ] else ...[
                TextField(
                  controller: emailCtrl,
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
                    _loading
                        ? 'Envoi...'
                        : 'Envoyer le lien de réinitialisation',
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 1. D'abord, modifions la méthode _buildProfileUI
  Widget _buildProfileUI() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Carte de profil
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundImage:
                                      _user?.photoURL != null
                                          ? NetworkImage(_user!.photoURL!)
                                          : AssetImage(
                                                'assets/images/default_avatar.png',
                                              )
                                              as ImageProvider,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                _user?.displayName ??
                                    '${AppLocalizations.of(context).translate('user')}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  //padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _handleSignOut,
                                icon: Icon(
                                  Icons.logout,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                label: Text(
                                  '${AppLocalizations.of(context).translate('deconex')}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Divider
                    if (_reportedNumbers.length != 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Divider(),
                      ),

                    // Animation Lottie quand il n'y a pas de signalements
                    if (_reportedNumbers.length == 0)
                      Container(
                        height: 250,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Lottie.asset('assets/lotties/1 (123).json'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  Future<void> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context).translate('cancel')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text(AppLocalizations.of(context).translate('confirm')),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onConfirm();
                },
              ),
            ],
          ),
    );
  }
}

class RoleSelectionDropdown extends StatefulWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionDropdown({Key? key, required this.onRoleSelected})
    : super(key: key);

  @override
  _RoleSelectionDropdownState createState() => _RoleSelectionDropdownState();
}

class _RoleSelectionDropdownState extends State<RoleSelectionDropdown> {
  String? roleChoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: DropdownButton<String>(
        value: roleChoice,
        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        hint: FittedBox(
          child: Text(
            'Sélectionnez mon rôle',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Theme.of(context).iconTheme.color,
        ),

        iconSize: 24,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),

        underline: Container(
          height: 0, // Supprime la ligne par défaut
        ),
        isExpanded: true,
        menuMaxHeight: 300,

        items:
            lesRoles.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    value.toUpperCase(),
                    style: TextStyle(color: Colors.grey[800], fontSize: 15),
                  ),
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            roleChoice = newValue;
          });
          if (newValue != null) {
            widget.onRoleSelected(newValue); // Cette ligne manquait
          }
        },
      ),
    );
  }
}
