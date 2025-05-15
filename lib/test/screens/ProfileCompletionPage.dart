import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../myapp.dart';
import '../profile_provider.dart';
import '../widgets.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});
  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  String? phone, gender;

  @override
  Widget build(BuildContext ctx) {
    return Consumer2<AuthService, ProfileProvider>(
      builder: (context, auth, prov, _) {
        if (prov.isLoading || prov.user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Complétez votre profil'),
            actions: [iconLogout()],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  onSaved: (v) => phone = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Genre'),
                  onSaved: (v) => gender = v,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Terminer'),
                  onPressed: () async {
                    _formKey.currentState!.save();
                    print('Form values — phone: $phone, gender: $gender');

                    final Map<String, dynamic> updateFields = {
                      if (phone != null && phone!.isNotEmpty) 'phone': phone,
                      if (gender != null && gender!.isNotEmpty)
                        'gender': gender,
                    };

                    if (updateFields.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aucune donnée à mettre à jour'),
                        ),
                      );
                      return;
                    }

                    final profile = context.read<ProfileProvider>();
                    if (profile.user == null) {
                      debugPrint("Profile pas encore prêt");
                      return;
                    }
                    profile.updateUser({'phone': phone, 'gender': gender});

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (ctx) => MyApp3()),
                    );
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('Profil mis à jour')),
                    // );

                    // if (context.mounted) {
                    //   Navigator.pop(context); // ou autre redirection selon rôle
                    // }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
