import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../0chatgpsCourss/providers/user_provider.dart';
import '../PlatformUtils.dart';
import 'login_screen.dart';
import 'screens.dart';

class MyAppGpt extends StatelessWidget {
  const MyAppGpt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home:
          PlatformUtils.isDesktop
              ? const DesktopAuthWrapper()
              : const AuthWrapper(),
    );
  }
}

/// Wrapper spécifique pour Desktop (sans Firebase)
class DesktopAuthWrapper extends StatefulWidget {
  const DesktopAuthWrapper({super.key});

  @override
  State<DesktopAuthWrapper> createState() => _DesktopAuthWrapperState();
}

class _DesktopAuthWrapperState extends State<DesktopAuthWrapper> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mode Desktop - Développement'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.desktop_windows, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Mode Desktop',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Firebase Auth n\'est pas disponible sur Windows.\n'
                  'Utilisez ce mode uniquement pour le développement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoggedIn = true);
                },
                child: const Text('Continuer en mode développement'),
              ),
            ],
          ),
        ),
      );
    }

    // Mode développement - accès direct
    return const HomeParent(); // ou la page que vous voulez tester
  }
}

/// Widget qui gère le routage selon l'état d'authentification
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // En attente de la connexion
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Erreur de connexion
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de connexion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Relancer l'application
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyAppGpt()),
                      );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        // Pas d'utilisateur connecté
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Utilisateur connecté -> charger ses données
        final user = snapshot.data!;
        return UserDataLoader(user: user);
      },
    );
  }
}

/// Widget qui charge les données utilisateur depuis Firestore
/// Utilise StatefulWidget pour éviter l'erreur "setState during build"
class UserDataLoader extends StatefulWidget {
  final User user;

  const UserDataLoader({super.key, required this.user});

  @override
  State<UserDataLoader> createState() => _UserDataLoaderState();
}

class _UserDataLoaderState extends State<UserDataLoader> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Charger les données après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      await context.read<UserProviderGpt>().loadUser(widget.user.uid);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      print('Erreur chargement utilisateur: $e');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Affichage du chargement
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de vos données...'),
            ],
          ),
        ),
      );
    }

    // Affichage de l'erreur
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadUserData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Données chargées avec succès -> router vers la page appropriée
    return const HomeRouter();
  }
}

/// Widget qui route vers la bonne page d'accueil selon le rôle
class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProviderGpt>(
      builder: (context, userProvider, child) {
        // Vérifier si le chargement est en cours
        if (userProvider.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Vérifier si l'utilisateur existe
        final user = userProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Utilisateur introuvable')),
          );
        }

        // Router selon le rôle
        final role = user.role.toLowerCase();

        switch (role) {
          case 'club':
          case 'association':
          case 'ecole':
            return const HomeClub();

          case 'professeur':
          case 'coach':
          case 'animateur':
            return const HomeProf();

          case 'parent':
          case 'sero':
          default:
            return const HomeParent();
        }
      },
    );
  }
}
