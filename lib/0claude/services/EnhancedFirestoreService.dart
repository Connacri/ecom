import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion Firestore optimisé pour le système d'authentification
class EnhancedFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String pendingDeletionsCollection = 'pending_deletions';
  static const String qrSessionsCollection = 'qr_sessions';

  // ========================================
  // GESTION UTILISATEURS
  // ========================================

  /// Créer un document utilisateur complet
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    String? username,
    String? phone,
    String role = 'parent',
    bool emailVerified = false,
    bool phoneVerified = false,
    String? photoUrl,
    String signUpMethod = 'email',
  }) async {
    try {
      await _db.collection(usersCollection).doc(uid).set({
        'email': email.toLowerCase().trim(),
        'name': name.trim(),
        'username': username?.toLowerCase().trim(),
        'phone': phone?.trim(),
        'role': role,
        'emailVerified': emailVerified,
        'phoneVerified': phoneVerified,
        'photoUrl': photoUrl,
        'accountStatus': 'active',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'editedAt': null,
        'deletionScheduledAt': null,
        'metadata': {
          'signUpMethod': signUpMethod,
          'deviceInfo': {},
          'preferences': {},
        },
        // Données additionnelles selon le rôle
        'courses': [],
        'dispo': true,
        'gender': '',
        'logoUrl': photoUrl ?? 'https://ui-avatars.com/api/?name=$name',
      });

      debugPrint('✅ Document utilisateur créé: $uid');
    } catch (e) {
      debugPrint('❌ Erreur createUser: $e');
      rethrow;
    }
  }

  /// Récupérer un utilisateur
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _db.collection(usersCollection).doc(uid).get();

      if (!doc.exists) {
        debugPrint('⚠️ Utilisateur non trouvé: $uid');
        return null;
      }

      return {...doc.data()!, 'uid': doc.id};
    } catch (e) {
      debugPrint('❌ Erreur getUser: $e');
      return null;
    }
  }

  /// Stream d'un utilisateur
  Stream<Map<String, dynamic>?> watchUser(String uid) {
    return _db.collection(usersCollection).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {...doc.data()!, 'uid': doc.id};
    });
  }

  /// Vérifier si un utilisateur existe
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _db.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Erreur userExists: $e');
      return false;
    }
  }

  /// Rechercher un utilisateur par username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final snapshot =
          await _db
              .collection(usersCollection)
              .where('username', isEqualTo: username.toLowerCase().trim())
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      return {...snapshot.docs.first.data(), 'uid': snapshot.docs.first.id};
    } catch (e) {
      debugPrint('❌ Erreur getUserByUsername: $e');
      return null;
    }
  }

  /// Rechercher un utilisateur par téléphone
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final snapshot =
          await _db
              .collection(usersCollection)
              .where('phone', isEqualTo: phone.trim())
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      return {...snapshot.docs.first.data(), 'uid': snapshot.docs.first.id};
    } catch (e) {
      debugPrint('❌ Erreur getUserByPhone: $e');
      return null;
    }
  }

  /// Récupérer un utilisateur par email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final snapshot =
          await _db
              .collection(usersCollection)
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['uid'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      debugPrint('❌ Erreur getUserByEmail: $e');
      return null;
    }
  }

  /// Vérifier la disponibilité d'un username
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final snapshot =
          await _db
              .collection(usersCollection)
              .where('username', isEqualTo: username.toLowerCase().trim())
              .limit(1)
              .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('❌ Erreur isUsernameAvailable: $e');
      return false;
    }
  }

  // ========================================
  // MISE À JOUR UTILISATEURS
  // ========================================

  /// Mettre à jour des champs spécifiques
  Future<bool> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      fields['editedAt'] = FieldValue.serverTimestamp();

      await _db.collection(usersCollection).doc(uid).update(fields);

      debugPrint('✅ Champs mis à jour: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur updateUserFields: $e');
      return false;
    }
  }

  /// Mettre à jour le lastLogin
  Future<void> updateLastLogin(String uid) async {
    try {
      await _db.collection(usersCollection).doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erreur updateLastLogin: $e');
    }
  }

  /// Mettre à jour le statut de vérification email
  Future<void> updateEmailVerified(String uid, bool verified) async {
    try {
      await updateUserFields(uid, {'emailVerified': verified});
    } catch (e) {
      debugPrint('❌ Erreur updateEmailVerified: $e');
    }
  }

  /// Mettre à jour le statut de vérification téléphone
  Future<void> updatePhoneVerified(String uid, String phone) async {
    try {
      await updateUserFields(uid, {'phone': phone, 'phoneVerified': true});
    } catch (e) {
      debugPrint('❌ Erreur updatePhoneVerified: $e');
    }
  }

  /// Mettre à jour la photo de profil
  Future<void> updateProfilePhoto(String uid, String photoUrl) async {
    try {
      await updateUserFields(uid, {'photoUrl': photoUrl, 'logoUrl': photoUrl});
    } catch (e) {
      debugPrint('❌ Erreur updateProfilePhoto: $e');
    }
  }

  // ========================================
  // GESTION DES SUPPRESSIONS
  // ========================================

  /// Créer une demande de suppression
  Future<void> createDeletionRequest({
    required String uid,
    required String email,
    String? reason,
  }) async {
    try {
      final deletionDate = DateTime.now().add(const Duration(days: 60));

      // Créer la demande
      await _db.collection(pendingDeletionsCollection).doc(uid).set({
        'userId': uid,
        'email': email,
        'reason': reason,
        'requestedAt': FieldValue.serverTimestamp(),
        'scheduledDeletionAt': Timestamp.fromDate(deletionDate),
        'status': 'pending',
        'remindersSent': [],
      });

      // Mettre à jour le statut du compte
      await updateUserFields(uid, {
        'accountStatus': 'pending_deletion',
        'deletionScheduledAt': Timestamp.fromDate(deletionDate),
      });

      debugPrint('✅ Demande de suppression créée: $uid');
    } catch (e) {
      debugPrint('❌ Erreur createDeletionRequest: $e');
      rethrow;
    }
  }

  /// Récupérer une demande de suppression
  Future<Map<String, dynamic>?> getDeletionRequest(String uid) async {
    try {
      final doc =
          await _db.collection(pendingDeletionsCollection).doc(uid).get();

      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      debugPrint('❌ Erreur getDeletionRequest: $e');
      return null;
    }
  }

  /// Annuler une demande de suppression
  Future<void> cancelDeletionRequest(String uid) async {
    try {
      // Supprimer la demande
      await _db.collection(pendingDeletionsCollection).doc(uid).delete();

      // Réactiver le compte
      await updateUserFields(uid, {
        'accountStatus': 'active',
        'deletionScheduledAt': FieldValue.delete(),
      });

      debugPrint('✅ Demande de suppression annulée: $uid');
    } catch (e) {
      debugPrint('❌ Erreur cancelDeletionRequest: $e');
      rethrow;
    }
  }

  /// Supprimer définitivement un utilisateur
  Future<bool> deleteUserPermanently(String uid) async {
    try {
      // Supprimer le document utilisateur
      await _db.collection(usersCollection).doc(uid).delete();

      // Supprimer la demande de suppression
      await _db.collection(pendingDeletionsCollection).doc(uid).delete();

      // Supprimer les sessions QR associées
      final qrSessions =
          await _db
              .collection(qrSessionsCollection)
              .where('userId', isEqualTo: uid)
              .get();

      final batch = _db.batch();
      for (var doc in qrSessions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ Utilisateur supprimé définitivement: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur deleteUserPermanently: $e');
      return false;
    }
  }

  // ========================================
  // GESTION DES SESSIONS QR
  // ========================================

  /// Créer une session QR
  Future<String> createQRSession() async {
    try {
      final sessionId = _generateSessionId();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      await _db.collection(qrSessionsCollection).doc(sessionId).set({
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'userId': null,
        'approvedAt': null,
        'deviceInfo': {},
      });

      debugPrint('✅ Session QR créée: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('❌ Erreur createQRSession: $e');
      rethrow;
    }
  }

  /// Récupérer une session QR
  Future<Map<String, dynamic>?> getQRSession(String sessionId) async {
    try {
      final doc =
          await _db.collection(qrSessionsCollection).doc(sessionId).get();

      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      debugPrint('❌ Erreur getQRSession: $e');
      return null;
    }
  }

  /// Approuver une session QR
  Future<bool> approveQRSession(String sessionId, String userId) async {
    try {
      final doc =
          await _db.collection(qrSessionsCollection).doc(sessionId).get();

      if (!doc.exists) {
        throw Exception('Session invalide');
      }

      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        await _db.collection(qrSessionsCollection).doc(sessionId).update({
          'status': 'expired',
        });
        throw Exception('Session expirée');
      }

      await _db.collection(qrSessionsCollection).doc(sessionId).update({
        'status': 'approved',
        'userId': userId,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Session QR approuvée: $sessionId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur approveQRSession: $e');
      rethrow;
    }
  }

  /// Stream d'une session QR
  Stream<String> watchQRSession(String sessionId) {
    return _db.collection(qrSessionsCollection).doc(sessionId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return 'invalid';
      return doc.data()!['status'] as String;
    });
  }

  /// Nettoyer les sessions QR expirées
  Future<void> cleanupExpiredQRSessions() async {
    try {
      final now = Timestamp.now();

      final expiredSessions =
          await _db
              .collection(qrSessionsCollection)
              .where('expiresAt', isLessThan: now)
              .where('status', isEqualTo: 'pending')
              .get();

      final batch = _db.batch();

      for (var doc in expiredSessions.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }

      await batch.commit();

      debugPrint(
        '✅ ${expiredSessions.docs.length} sessions QR expirées nettoyées',
      );
    } catch (e) {
      debugPrint('❌ Erreur cleanupExpiredQRSessions: $e');
    }
  }

  // ========================================
  // GESTION DES RÔLES ET PERMISSIONS
  // ========================================

  /// Récupérer tous les utilisateurs par rôle
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final snapshot =
          await _db
              .collection(usersCollection)
              .where('role', isEqualTo: role)
              .where('accountStatus', isEqualTo: 'active')
              .get();

      return snapshot.docs.map((doc) {
        return {...doc.data(), 'uid': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur getUsersByRole: $e');
      return [];
    }
  }

  /// Mettre à jour le rôle d'un utilisateur
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await updateUserFields(uid, {'role': newRole});
      debugPrint('✅ Rôle mis à jour pour $uid: $newRole');
    } catch (e) {
      debugPrint('❌ Erreur updateUserRole: $e');
      rethrow;
    }
  }

  // ========================================
  // STATISTIQUES ET ANALYTICS
  // ========================================

  /// Compter les utilisateurs par statut
  Future<Map<String, int>> getUserStats() async {
    try {
      final activeSnapshot =
          await _db
              .collection(usersCollection)
              .where('accountStatus', isEqualTo: 'active')
              .count()
              .get();

      final pendingDeletionSnapshot =
          await _db
              .collection(usersCollection)
              .where('accountStatus', isEqualTo: 'pending_deletion')
              .count()
              .get();

      return {
        'active': activeSnapshot.count ?? 0,
        'pending_deletion': pendingDeletionSnapshot.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Erreur getUserStats: $e');
      return {'active': 0, 'pending_deletion': 0};
    }
  }

  /// Récupérer les utilisateurs récents
  Future<List<Map<String, dynamic>>> getRecentUsers({int limit = 10}) async {
    try {
      final snapshot =
          await _db
              .collection(usersCollection)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) {
        return {...doc.data(), 'uid': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur getRecentUsers: $e');
      return [];
    }
  }

  // ========================================
  // UTILITAIRES
  // ========================================

  /// Générer un ID de session unique
  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecond.toString();
  }

  /// Nettoyer toutes les données d'un utilisateur
  Future<void> cleanupUserData(String uid) async {
    try {
      final batch = _db.batch();

      // Supprimer les sessions QR
      final qrSessions =
          await _db
              .collection(qrSessionsCollection)
              .where('userId', isEqualTo: uid)
              .get();

      for (var doc in qrSessions.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint('✅ Données nettoyées pour: $uid');
    } catch (e) {
      debugPrint('❌ Erreur cleanupUserData: $e');
    }
  }

  /// Vérifier l'intégrité des données
  Future<bool> verifyDataIntegrity(String uid) async {
    try {
      final user = await getUser(uid);

      if (user == null) return false;

      // Vérifier les champs requis
      final requiredFields = ['email', 'name', 'role', 'accountStatus'];

      for (var field in requiredFields) {
        if (!user.containsKey(field) || user[field] == null) {
          debugPrint('⚠️ Champ manquant: $field pour $uid');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Erreur verifyDataIntegrity: $e');
      return false;
    }
  }
}
