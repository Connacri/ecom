import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../activities/modèles.dart';
import '../auth_service.dart';
import '../profile_provider.dart';
import '../widgets.dart';
import 'ProfileCompletionPage.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});
  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir votre rôle'),
        actions: [iconLogout()],
      ),
      body: FutureBuilder(
        future: Provider.of<ProfileProvider>(context, listen: false).init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            final prov = Provider.of<ProfileProvider>(context);
            final auth = Provider.of<AuthService>(context);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: const Text(
                      'Choisissez votre rôle',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      prov.user?.name ?? 'Utilisateur non trouvé',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _selectedRole,
                    hint: const Text('Sélectionnez un rôle'),
                    items:
                        lesRoles
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _selectedRole = v),
                  ),
                  ElevatedButton(
                    onPressed:
                        _selectedRole == null
                            ? null
                            : () async {
                              await prov.updateUser({'role': _selectedRole});
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileCompletionPage(),
                                ),
                              );
                            },
                    child: const Text('Suivant'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
