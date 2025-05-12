import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/AuthProvider.dart';
import '../../fonctions/AppLocalizations.dart';
import '../../pages/MyApp.dart';
import '../ParentsScreen.dart';
import '../modèles.dart';
import '../providers.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user = FirebaseAuth.instance.currentUser;
  bool _isMounted = false;
  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charge l'utilisateur et les enfants si parent
      if (_isMounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!.uid;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser(currentUser);

      if (_isMounted &&
          userProvider.user != null &&
          userProvider.user!.role.toLowerCase() == 'parent') {
        final childProvider = Provider.of<ChildProvider>(
          context,
          listen: false,
        );
        await childProvider.loadChildren(currentUser);
      }
    } catch (e) {
      if (_isMounted) {
        // Gérer l'erreur si nécessaire
        debugPrint('Erreur lors du chargement initial: $e');
      }
    }
  }

  Future<void> _retryLoading() async {
    if (_isMounted) {
      await _loadInitialData();
    }
  }

  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final childProvider = Provider.of<ChildProvider>(context);

    // Gestion des états globaux
    if (userProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userProvider.error != null) {
      return _buildErrorScreen(userProvider.error!, onRetry: _retryLoading);
    }

    if (userProvider.user == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun utilisateur trouvé')),
      );
    }

    final user = userProvider.user!;

    // Gestion spécifique pour les parents (chargement des enfants)
    if (user.role.toLowerCase() == 'parent') {
      if (childProvider.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (childProvider.error != null) {
        return _buildErrorScreen(
          childProvider.error!,
          onRetry:
              () => childProvider.loadChildren(user.id, forceRefresh: true),
        );
      }
    }

    // Redirection en fonction du rôle
    switch (user.role.toLowerCase()) {
      case 'parent':
        return ParentHomePage(user: user);
      case 'professeur':
      case 'prof':
      case 'coach':
        return _ProfHomePage(user: user);
      case 'club':
      case 'association':
      case 'ecole':
        return _ClubHomePage(user: user);
      default:
        return _UnknownRolePage(user: user);
    }
  }

  Widget _buildErrorScreen(String error, {VoidCallback? onRetry}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $error'),
            const SizedBox(height: 20),
            if (onRetry != null)
              Column(
                children: [
                  IconButton(
                    onPressed: isLoading ? null : _handleSignOut,
                    icon:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.logout),
                    tooltip: 'Logout',
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Logout handler with confirmation dialog
  Future<void> _handleSignOut() async {
    setState(() => isSigningOut = true);

    try {
      // On attend que les deux futures se terminent : la déconnexion + le délai
      await Future.wait([
        _authService.signOut(),
        Future.delayed(const Duration(seconds: 2)), // 👈 délai imposé
      ]);
      if (_isMounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp()));
      }
      setState(() {
        _user = null;
      });
    } catch (e) {
      print('Erreur déconnexion: $e');
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('connexErreur'),
            ),
          ),
        );
      }
    } finally {
      setState(() => isSigningOut = false);
    }
  }
}

class _ProfHomePage extends StatelessWidget {
  final UserModel user;

  const _ProfHomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bienvenue ${user.name}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 50),
            const SizedBox(height: 20),
            Text(
              'Interface Professeur',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text('Rôle: ${user.role}'),
          ],
        ),
      ),
    );
  }
}

// Page pour les clubs
class _ClubHomePage extends StatelessWidget {
  final UserModel user;

  const _ClubHomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bienvenue ${user.name}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 50),
            const SizedBox(height: 20),
            Text(
              'Interface Club',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text('Rôle: ${user.role}'),
          ],
        ),
      ),
    );
  }
}

// Page pour les rôles non reconnus
class _UnknownRolePage extends StatelessWidget {
  final UserModel user;

  const _UnknownRolePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rôle non reconnu')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 50, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'Rôle "${user.role}" non pris en charge',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Contactez le support',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
