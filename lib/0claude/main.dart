import 'package:ecom/0claude/universelle/forgot_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports des screens
import '../PlatformUtils.dart';
import 'FirebaseWrapper.dart';
import 'desktop/profile/profile_management_screen.dart';
import 'screens/auth/universal_login_screen.dart';
// Imports des services
import 'services/EnhancedFirestoreService.dart';
import 'universelle/qr/QRScannerScreen.dart';
import 'universelle/signup_screen.dart';

class MyAppClaude extends StatelessWidget {
  const MyAppClaude({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth System Complete',
      debugShowCheckedModeBanner: false,

      // Thème
      theme: ThemeData(
        fontFamily: 'OSWALD',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // Route initiale
      // ✅ Home conditionnel selon la plateforme
      home:
          PlatformUtils.isDesktop
              ? const DesktopLoginScreen() // ✅ Change aussi ici
              : const AuthWrapper(),

      // Routes nommées
      routes: {
        '/login': (context) => const UniversalLoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/qr-scanner': (context) => const QRScannerScreen(),
        '/qr-display': (context) => const QRDisplayScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileManagementScreen(),
      },
    );
  }
}

// ============================================
// DESKTOP LOGIN SCREEN - Écran de connexion Desktop
// ============================================

class DesktopLoginScreen extends StatefulWidget {
  const DesktopLoginScreen({super.key});

  @override
  State<DesktopLoginScreen> createState() => _DesktopLoginScreenState();
}

class _DesktopLoginScreenState extends State<DesktopLoginScreen> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    // Si connecté, afficher l'écran d'accueil
    if (_isLoggedIn) {
      return const DesktopHomeScreen();
    }

    // Sinon, afficher l'écran de connexion
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion - Mode Desktop'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.desktop_windows, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Mode Desktop - Développement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Firebase Auth n\'est pas disponible sur Windows.\n'
                'Ce mode est uniquement pour le développement local.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isLoggedIn = true);
              },
              icon: const Icon(Icons.login),
              label: const Text('Se connecter (Mode Dev)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cette connexion est simulée pour le développement',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// AUTH WRAPPER - Gestion de l'état d'auth
// ============================================

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔧 Sur Desktop, vérifier d'abord l'état de connexion
    if (PlatformUtils.isDesktop) {
      // Retourner directement l'écran de login pour Desktop
      return const UniversalLoginScreen();
    }

    // Écouter l'état d'authentification
    return StreamBuilder<User?>(
      stream: FirebaseWrapper.authStateChanges,
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...'),
                ],
              ),
            ),
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
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Relancer
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
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
          return const UniversalLoginScreen();
        }

        // Utilisateur connecté
        final user = snapshot.data!;

        // Vérifier si l'email est vérifié
        if (!user.emailVerified) {
          return EmailVerificationScreen(user: user);
        }

        // Charger les données utilisateur
        return UserDataLoader(user: user);
      },
    );
  }
}

// ============================================
// DESKTOP AUTH WRAPPER - Mode développement
// ============================================

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

    // Mode développement - accès direct avec données mock
    return const DesktopHomeScreen();
  }
}

// ============================================
// DESKTOP HOME SCREEN - Écran de test Desktop
// ============================================

class DesktopHomeScreen extends StatelessWidget {
  const DesktopHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Desktop (Dev Mode)'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.developer_mode, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Mode Développement Desktop',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Firebase n\'est pas disponible sur cette plateforme',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person),
              label: const Text('Tester le profil'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// USER DATA LOADER
// ============================================

class UserDataLoader extends StatefulWidget {
  final User user;

  const UserDataLoader({super.key, required this.user});

  @override
  State<UserDataLoader> createState() => _UserDataLoaderState();
}

class _UserDataLoaderState extends State<UserDataLoader> {
  final EnhancedFirestoreService? _firestoreService =
      PlatformUtils.isDesktop ? null : EnhancedFirestoreService();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Sur Desktop, ne pas charger de données réelles
    if (PlatformUtils.isDesktop) {
      setState(() {
        _loading = false;
      });
      return;
    }

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_firestoreService == null) return;
    try {
      // Charger les données Firestore
      final userData = await _firestoreService.getUser(widget.user.uid);

      if (userData == null) {
        throw Exception('Données utilisateur introuvables');
      }

      // Mettre à jour le provider
      if (mounted) {
        context.read<UserProviderClaude>().setUser(userData);
      }

      // Mettre à jour lastLogin
      await _firestoreService.updateLastLogin(widget.user.uid);

      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement utilisateur: $e');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chargement
    if (_loading) {
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

    // Erreur
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
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadUserData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await FirebaseWrapper.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      );
    }

    // Succès - afficher l'écran d'accueil
    return const HomeScreen();
  }
}

// ============================================
// HOME SCREEN - Exemple d'écran principal
// ============================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProviderClaude>();
    final userData = userProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/qr-scanner');
            },
            tooltip: 'Scanner QR Code',
          ),
        ],
      ),
      drawer: _buildDrawer(context, userData),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carte de bienvenue
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          userData?['photoUrl'] != null
                              ? NetworkImage(userData!['photoUrl'])
                              : null,
                      child:
                          userData?['photoUrl'] == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData?['name'] ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData?['email'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(userData?['role'] ?? 'user'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statut du compte
            if (userData?['accountStatus'] == 'pending_deletion')
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Suppression programmée',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Votre compte sera supprimé bientôt',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Annuler la suppression'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Actions rapides
            const Text(
              'Actions rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _QuickActionCard(
              icon: Icons.person,
              title: 'Mon profil',
              subtitle: 'Gérer mes informations',
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),

            _QuickActionCard(
              icon: Icons.qr_code,
              title: 'QR Code Login',
              subtitle: 'Se connecter sur un autre appareil',
              onTap: () {
                Navigator.pushNamed(context, '/qr-display');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, Map<String, dynamic>? userData) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userData?['name'] ?? 'Utilisateur'),
            accountEmail: Text(userData?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
                  userData?['photoUrl'] != null
                      ? NetworkImage(userData!['photoUrl'])
                      : null,
              child:
                  userData?['photoUrl'] == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mon profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text(
                        'Voulez-vous vraiment vous déconnecter ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Déconnexion',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );

              if (confirm == true && context.mounted) {
                await FirebaseWrapper.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ============================================
// USER PROVIDER - Gestion d'état
// ============================================

class UserProviderClaude with ChangeNotifier {
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  void setUser(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void clearUser() {
    _userData = null;
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> updates) {
    if (_userData != null) {
      _userData = {..._userData!, ...updates};
      notifyListeners();
    }
  }
}
