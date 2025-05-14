import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../activities/modèles.dart';
import '../activities/providers.dart';
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
  List<Map<String, dynamic>> _reportedNumbers = [];
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 10; // Nombre de résultats par page
  bool isSigningOut = false;
  // String? roleChoice;
  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _setupAuthListener();
  }

  // Future<void> _handleSignIn(/*String? role*/) async {
  //   // if (role!.isEmpty) {
  //   //   ScaffoldMessenger.of(
  //   //     context,
  //   //   ).showSnackBar(SnackBar(content: Text('Please select a role')));
  //   //   return;
  //   // }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     User? user = await _authService.signInWithGoogle();
  //
  //     if (user != null) {
  //       final uid = user.uid;
  //       final docRef = FirebaseFirestore.instance
  //           .collection('userModel')
  //           .doc(uid);
  //       final docSnapshot = await docRef.get();
  //
  //       final userData = {
  //         'name': user.displayName ?? 'New User',
  //         'email': user.email ?? '',
  //         'photos': user.photoURL != null ? [user.photoURL!] : [],
  //         'role': 'role',
  //         'lastLogin': FieldValue.serverTimestamp(),
  //       };
  //
  //       if (!docSnapshot.exists) {
  //         // New user - create document
  //         await docRef.set({
  //           ...userData,
  //           'createdAt': FieldValue.serverTimestamp(),
  //           'editedAt': FieldValue.serverTimestamp(),
  //           'phone': '',
  //           'gender': '',
  //           'courses': [],
  //         }, SetOptions(merge: true));
  //       } else {
  //         // Existing user - update last login
  //         await docRef.update(userData);
  //       }
  //
  //       if (!mounted) return;
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (ctx) => HomePage()),
  //       );
  //     } else {
  //       if (!mounted) return;
  //       // ScaffoldMessenger.of(context).showSnackBar(
  //       //   SnackBar(content: Text('Sign in failed - no user returned')),
  //       // );
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error during sign in: ${e.toString()}')),
  //     );
  //     debugPrint('Erreur authentification: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => isLoading = false);
  //     }
  //   }
  // }
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
        'role': '',
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
        }, SetOptions(merge: true));
      } else {
        await docRef.update(data);
      }

      // ➔ Rechargement explicite du provider
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadCurrentUser(uid);

      // ➔ Navigation vers HomePage
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
                : _buildProfileUI(), //HomeScreenAct(),
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
                ? Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),

                    child: Text(
                      'En Utilisant votre compte google tu porra t\'authentifier\n\n' //\n\nqui je suis ?!'
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                : Flexible(
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

            // RoleSelectionDropdown(
            //   onRoleSelected: (role) {
            //     setState(() {
            //       roleChoice = role;
            //     });
            //     print('choicerole : $roleChoice');
            //     print('role $role');
            //   },
            // ),
            // Spacer(),
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
              onPressed:
                  //roleChoice != null ?
                  () => _handleSignIn(/*roleChoice!*/),
              //: null,
            ),
            SizedBox(height: 70),
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
