import 'package:ecom/activities/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

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
  List<Map<String, dynamic>> _reportedNumbers = [];
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 10; // Nombre de résultats par page
  bool isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _setupAuthListener();
  }

  Future<void> _handleSignIn() async {
    setState(() => isLoading = true);

    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          // Force le rafraîchissement
          context,
          MaterialPageRoute(builder: (ctx) => HomeScreenAct()),
        );
      }
    } finally {
      setState(() => isLoading = false);
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
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp()));
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
                ? _buildLoginUI()
                : HomeScreenAct(),
        //_buildProfileUI(),
      ),
    );
  }

  Widget _buildLoginUI() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Lottie.asset(
              'assets/lotties/google.json',
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),

            AppLocalizations.of(context).locale.languageCode != 'ar'
                ? Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),

                    child: Text(
                      '${AppLocalizations.of(context).translate('usingGoogleToReport')}'
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Oswald',
                      ),
                    ),
                  ),
                )
                : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Text(
                      '${AppLocalizations.of(context).translate('usingGoogleToReport')}'
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'ArbFONTS',
                      ),
                    ),
                  ),
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
              icon: Icon(FontAwesomeIcons.google, color: Colors.red),
              label: const Text(
                'Google',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              onPressed: _handleSignIn,
            ),
            Spacer(),
          ],
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
    return showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                child: Text(
                  '${AppLocalizations.of(context).translate('annuler')}',
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              ElevatedButton(
                child: Text(
                  '${AppLocalizations.of(context).translate('delete')}',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Ferme la boîte de dialogue
                  onConfirm(); // Appelle la fonction de suppression
                },
              ),
            ],
          ),
    );
  }
}
