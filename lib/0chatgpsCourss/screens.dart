import 'package:ecom/0chatgpsCourss/services/firebase_wrapper.dart';
import 'package:flutter/material.dart';

import '../0chatgpsCourss/services/auth_service.dart';
import '../PlatformUtils.dart';
import 'edit_profile_screen.dart';

/// Écran d'accueil pour les administrateurs
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseHomeScreen(
      title: 'Tableau de bord Admin',
      role: 'admin',
      children: [
        _MenuCard(
          icon: Icons.people,
          title: 'Gestion des utilisateurs',
          subtitle: 'Gérer les comptes utilisateurs',
          onTap: () {
            // Navigation vers la gestion des utilisateurs
          },
        ),
        _MenuCard(
          icon: Icons.settings,
          title: 'Paramètres',
          subtitle: 'Configuration de l\'application',
          onTap: () {
            // Navigation vers les paramètres
          },
        ),
      ],
    );
  }
}

/// Écran d'accueil pour les clubs/associations/écoles
class HomeClub extends StatelessWidget {
  const HomeClub({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseHomeScreen(
      title: 'Espace Club',
      role: 'club',
      children: [
        _MenuCard(
          icon: Icons.event,
          title: 'Événements',
          subtitle: 'Gérer les événements du club',
          onTap: () {
            // Navigation vers les événements
          },
        ),
        _MenuCard(
          icon: Icons.groups,
          title: 'Membres',
          subtitle: 'Gestion des membres',
          onTap: () {
            // Navigation vers les membres
          },
        ),
      ],
    );
  }
}

/// Écran d'accueil pour les professeurs/coachs/animateurs
class HomeProf extends StatelessWidget {
  const HomeProf({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseHomeScreen(
      title: 'Espace Professeur',
      role: 'professeur',
      children: [
        _MenuCard(
          icon: Icons.class_,
          title: 'Mes cours',
          subtitle: 'Gérer mes cours et sessions',
          onTap: () {
            // Navigation vers les cours
          },
        ),
        _MenuCard(
          icon: Icons.people_outline,
          title: 'Élèves',
          subtitle: 'Liste de mes élèves',
          onTap: () {
            // Navigation vers les élèves
          },
        ),
      ],
    );
  }
}

/// Écran d'accueil pour les parents
class HomeParent extends StatelessWidget {
  const HomeParent({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseHomeScreen(
      title: 'Espace Parent',
      role: 'parent',
      children: [
        _MenuCard(
          icon: Icons.child_care,
          title: 'Mes enfants',
          subtitle: 'Gérer les profils de mes enfants',
          onTap: () {
            // Navigation vers les enfants
          },
        ),
        _MenuCard(
          icon: Icons.event_note,
          title: 'Activités',
          subtitle: 'Voir les activités inscrites',
          onTap: () {
            // Navigation vers les activités
          },
        ),
      ],
    );
  }
}

/// Widget de base pour tous les écrans d'accueil
class _BaseHomeScreen extends StatelessWidget {
  final String title;
  final String role;
  final List<Widget> children;

  const _BaseHomeScreen({
    required this.title,
    required this.role,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Mode Desktop - Interface simplifiée
    if (PlatformUtils.isDesktop) {
      return _DesktopHomeScreen(title: title, role: role, children: children);
    }

    // ✅ Mode normal (Mobile/Web) avec Firebase
    final user = FirebaseWrapper.currentUser;
    final authService = AuthService();

    // Si pas d'utilisateur connecté (ne devrait pas arriver)
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 16),
              Text('Utilisateur non connecté'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Ouvrir les notifications
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.displayName ?? 'Utilisateur'),
              accountEmail: Text(user.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child:
                    user.photoURL != null
                        ? ClipOval(
                          child: Image.network(
                            user.photoURL!,
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                        )
                        : Text(
                          (user.displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40),
                        ),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mon profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                // Navigation vers paramètres
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Aide'),
              onTap: () {
                Navigator.pop(context);
                // Navigation vers aide
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos'),
              onTap: () {
                Navigator.pop(context);
                // Navigation vers à propos
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Confirmation'),
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

                if (confirm == true) {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, ${user.displayName ?? "Utilisateur"}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rôle: $role',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran spécifique pour Desktop (sans Firebase)
class _DesktopHomeScreen extends StatelessWidget {
  final String title;
  final String role;
  final List<Widget> children;

  const _DesktopHomeScreen({
    required this.title,
    required this.role,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title (Mode Desktop)'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.desktop_windows),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Mode Desktop'),
                      content: const Text(
                        'Vous êtes en mode développement Desktop.\n\n'
                        'Firebase et Google Services sont désactivés sur cette plateforme.\n\n'
                        'Pour tester les fonctionnalités complètes, utilisez Android, iOS ou Web.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.orange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.desktop_windows, size: 30),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mode Desktop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Développement',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos du mode Desktop'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Mode Desktop'),
                        content: const Text(
                          'Ce mode permet de développer l\'interface sur Windows.\n\n'
                          'Fonctionnalités limitées:\n'
                          '• Pas d\'authentification Firebase\n'
                          '• Pas de Google Sign-In\n'
                          '• Pas de notifications push\n'
                          '• Pas de Firestore\n\n'
                          'Utilisez Android/iOS/Web pour les tests complets.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text('Quitter', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Fermer l'application ou retourner à l'écran de login
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bandeau d'avertissement
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mode Desktop - Fonctionnalités Firebase désactivées',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bonjour, Développeur',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Rôle: $role (simulation)',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de carte pour le menu
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
