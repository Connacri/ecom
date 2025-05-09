import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../fonctions/AppLocalizations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = FirebaseAuth.instance.currentUser; //auth.user!;
    return Scaffold(
      appBar: AppBar(
        title: Text("${AppLocalizations.of(context).translate('profile')}"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user!.photoURL!),
              radius: 40,
            ),
            const SizedBox(height: 10),
            Text(user.displayName ?? "", style: const TextStyle(fontSize: 18)),
            Text(user.email ?? "", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.logout),
            //   label: Text(
            //     "${AppLocalizations.of(context).translate('logout')}",
            //   ),
            //   onPressed: () {
            //     auth.signOut();
            //     _handleSignOut();
            //     Navigator.pop(context);
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
