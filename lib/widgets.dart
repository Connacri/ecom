import 'package:ecom/pages/MyApp.dart';
import 'package:flutter/material.dart';

import 'auth/AuthProvider.dart';

class BtnDeleteAccount extends StatelessWidget {
  final AuthService authService;

  const BtnDeleteAccount({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => _handleDeleteAccount(context),
      icon: const Icon(Icons.delete_forever),
      label: const Text('Supprimer mon compte'),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    // Confirmation avant suppression
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('⚠️ Supprimer le compte'),
            content: const Text(
              'Cette action est irréversible. Toutes vos données seront supprimées de:\n'
              '• Firebase Authentication\n'
              '• Firestore (userModel)\n'
              '• Supabase (users, signalements)\n\n'
              'Êtes-vous sûr ?',
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer définitivement'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Afficher un loader pendant la suppression
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await authService.deleteUserAccountPermanently();

      // Fermer le loader
      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (success) {
        // Succès
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Compte supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Rediriger vers la page de connexion
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MyApp1()),
          (route) => false, // Supprimer toutes les routes précédentes
        );
      } else {
        // Échec
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (!context.mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
