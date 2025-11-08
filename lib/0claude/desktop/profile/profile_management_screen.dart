import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/enhanced_auth_service.dart';

/// Écran de gestion du profil utilisateur
class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _authService = EnhancedAuthService();
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _pendingDeletion;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Charger les données Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      // Vérifier s'il y a une suppression en attente
      final deletionDoc =
          await _firestore.collection('pending_deletions').doc(user.uid).get();

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _pendingDeletion = deletionDoc.exists ? deletionDoc.data() : null;
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Lier un numéro de téléphone
  Future<void> _addPhoneNumber() async {
    final phoneCtrl = TextEditingController();

    final phone = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajouter un téléphone'),
            content: TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '+213...',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, phoneCtrl.text),
                child: const Text('Continuer'),
              ),
            ],
          ),
    );

    if (phone == null || phone.isEmpty) return;

    // Naviguer vers l'écran de vérification OTP
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhoneVerificationScreen(phoneNumber: phone),
        ),
      );

      // Recharger les données
      _loadUserData();
    }
  }

  /// Demander la suppression du compte
  Future<void> _requestAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le compte'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Êtes-vous sûr de vouloir supprimer votre compte ?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre compte sera désactivé immédiatement et supprimé définitivement dans 60 jours.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vous pourrez annuler cette demande pendant ces 60 jours.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _authService.requestAccountDeletion();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suppression programmée pour dans 60 jours'),
            backgroundColor: Colors.orange,
          ),
        );

        _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Annuler la suppression du compte
  Future<void> _cancelAccountDeletion() async {
    try {
      await _authService.cancelAccountDeletion();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suppression annulée - Compte réactivé'),
            backgroundColor: Colors.green,
          ),
        );

        _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Calculer les jours restants avant suppression
  int _getDaysUntilDeletion() {
    if (_pendingDeletion == null) return 0;

    final scheduledDate =
        (_pendingDeletion!['scheduledDeletionAt'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);

    return difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                    child:
                        user.photoURL == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nom
            Text(
              user.displayName ?? 'Utilisateur',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Email avec badge de vérification
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                if (user.emailVerified)
                  const Icon(Icons.verified, size: 16, color: Colors.green)
                else
                  TextButton(
                    onPressed: () async {
                      await _authService.sendEmailVerification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email de vérification envoyé'),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Vérifier',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Section téléphone
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Téléphone'),
                subtitle: Text(_userData?['phone'] ?? 'Non configuré'),
                trailing:
                    _userData?['phoneVerified'] == true
                        ? const Icon(Icons.verified, color: Colors.green)
                        : TextButton(
                          onPressed: _addPhoneNumber,
                          child: const Text('Ajouter'),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Section username
            Card(
              child: ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Nom d\'utilisateur'),
                subtitle: Text(_userData?['username'] ?? 'Non défini'),
              ),
            ),

            const SizedBox(height: 16),

            // Rôle
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Rôle'),
                subtitle: Text(_userData?['role'] ?? 'parent'),
              ),
            ),

            const SizedBox(height: 32),

            // Avertissement de suppression en attente
            if (_pendingDeletion != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Suppression programmée',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre compte sera supprimé dans ${_getDaysUntilDeletion()} jours',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _cancelAccountDeletion,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Annuler la suppression'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Bouton de suppression de compte
            if (_pendingDeletion == null)
              OutlinedButton.icon(
                onPressed: _requestAccountDeletion,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Supprimer mon compte'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Informations légales
            Text(
              'En supprimant votre compte, toutes vos données seront définitivement effacées après 60 jours. Vous pouvez annuler cette demande à tout moment pendant cette période.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran de vérification OTP pour le téléphone
class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _authService = EnhancedAuthService();
  final _otpCtrl = TextEditingController();

  String? _verificationId;
  bool _loading = false;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() => _loading = true);

    await _authService.sendPhoneVerification(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _loading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $error'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _loading = false);
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code doit contenir 6 chiffres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await _authService.verifyPhoneOTP(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléphone vérifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code invalide: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification téléphone'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_android, size: 80, color: Colors.blue),

            const SizedBox(height: 24),

            const Text(
              'Entrez le code OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Code envoyé au ${widget.phoneNumber}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Code OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              enabled: _codeSent && !_loading,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _codeSent && !_loading ? _verifyOTP : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _loading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Vérifier', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: _codeSent ? _sendOTP : null,
              child: const Text('Renvoyer le code'),
            ),
          ],
        ),
      ),
    );
  }
}
