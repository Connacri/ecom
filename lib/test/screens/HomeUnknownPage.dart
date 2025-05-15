import 'package:ecom/test/profile_provider.dart';
import 'package:ecom/test/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../activities/modèles.dart';
import 'ProfileCompletionPage.dart';

class HomeUnknownPage extends StatefulWidget {
  const HomeUnknownPage({super.key});

  @override
  State<HomeUnknownPage> createState() => _HomeUnknownPageState();
}

class _HomeUnknownPageState extends State<HomeUnknownPage> {
  String? _selectedRole;

  @override
  Widget build(BuildContext ctx) {
    final prov = Provider.of<ProfileProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue'), actions: [iconLogout()]),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Rôle non reconnu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Votre rôle n’est pas configuré pour accéder à une page dédiée. '
                'Veuillez contacter le support ou modifier votre rôle dans votre profil.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButton<String>(
              value: _selectedRole,
              hint: const Text('Sélectionnez un rôle'),
              items:
                  lesRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
              onChanged: (v) => setState(() => _selectedRole = v),
            ),
            const SizedBox(height: 24),
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
              child: const Text('Choisir un rôle'),
            ),
          ],
        ),
      ),
    );
  }
}
