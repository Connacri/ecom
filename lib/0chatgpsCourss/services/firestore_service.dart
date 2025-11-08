import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../PlatformUtils.dart';
import '../../activities/modèles.dart';

/// Service unifié pour la gestion des utilisateurs dans Firestore
/// Collection unique: 'users'
/// Service unifié pour la gestion des utilisateurs dans Firestore
/// Collection unique: 'users'
class FirestoreService {
  final FirebaseFirestore? _db;
  static const String usersCollection = 'users';

  // ✅ Constructeur conditionnel
  FirestoreService()
    : _db = PlatformUtils.isDesktop ? null : FirebaseFirestore.instance {
    if (PlatformUtils.isDesktop) {
      print(
        '⚠️ FirestoreService en mode Desktop - fonctionnalités désactivées',
      );
    }
  }

  // ✅ Helper pour vérifier si Firestore est disponible
  bool get isAvailable => _db != null;

  // ========================================
  // CRÉATION ET MISE À JOUR
  // ========================================

  /// Créer ou mettre à jour un utilisateur
  Future<bool> createOrUpdateUser(
    User firebaseUser, {
    Map<String, dynamic>? additionalData,
    bool forceCreate = false,
  }) async {
    if (!isAvailable) {
      print('⚠️ Firestore non disponible sur cette plateforme');
      return false;
    }

    try {
      final uid = firebaseUser.uid;
      final docRef = _db!.collection(usersCollection).doc(uid);
      final snapshot = await docRef.get();

      final baseData = {
        'name': firebaseUser.displayName ?? 'Utilisateur',
        'email': firebaseUser.email ?? '',
        'phone': firebaseUser.phoneNumber ?? '',
        'photos': firebaseUser.photoURL != null ? [firebaseUser.photoURL!] : [],
        'logoUrl': firebaseUser.photoURL ?? 'https://picsum.photos/200/300',
        'lastLogin': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists || forceCreate) {
        final createData = {
          ...baseData,
          'createdAt': FieldValue.serverTimestamp(),
          'editedAt': FieldValue.serverTimestamp(),
          'role': 'parent',
          'gender': '',
          'courses': [],
          'dispo': true,
          'isActive': true,
          ...?additionalData,
        };

        await docRef.set(createData, SetOptions(merge: true));
        print('✅ Utilisateur créé dans Firestore: $uid');
      } else {
        final updateData = {
          ...baseData,
          'editedAt': FieldValue.serverTimestamp(),
          ...?additionalData,
        };

        await docRef.update(updateData);
        print('✅ Utilisateur mis à jour dans Firestore: $uid');
      }

      return true;
    } catch (e) {
      print('❌ Erreur createOrUpdateUser: $e');
      return false;
    }
  }

  /// Créer un utilisateur s'il n'existe pas déjà
  Future<void> createUserIfNotExists({
    required String uid,
    required String email,
    String? phone,
    String? name,
    String role = 'parent',
    Map<String, dynamic>? extraFields,
  }) async {
    if (!isAvailable) return;

    try {
      final docRef = _db!.collection(usersCollection).doc(uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        final userMap = {
          'name': name ?? email.split('@').first,
          'email': email,
          'phone': phone ?? '',
          'photos': [],
          'logoUrl': 'https://picsum.photos/200/300',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'editedAt': null,
          'role': role,
          'gender': '',
          'courses': [],
          'dispo': true,
          'isActive': true,
          ...?extraFields,
        };
        await docRef.set(userMap);
        print('✅ Utilisateur créé: $uid');
      } else {
        await docRef.update({'lastLogin': FieldValue.serverTimestamp()});
        print('ℹ️ Utilisateur existe déjà, lastLogin mis à jour: $uid');
      }
    } catch (e) {
      print('❌ Erreur createUserIfNotExists: $e');
      rethrow;
    }
  }

  // ========================================
  // LECTURE
  // ========================================

  /// Récupérer un utilisateur par son UID
  Future<UserModel?> getUser(String uid) async {
    if (!isAvailable) return null;

    try {
      final doc = await _db!.collection(usersCollection).doc(uid).get();

      if (!doc.exists) {
        print('⚠️ Utilisateur introuvable: $uid');
        return null;
      }

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Erreur getUser: $e');
      return null;
    }
  }

  /// Récupérer les données brutes d'un utilisateur
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    if (!isAvailable) return null;

    try {
      final doc = await _db!.collection(usersCollection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Erreur getUserData: $e');
      return null;
    }
  }

  /// Récupérer tous les utilisateurs (pour admin)
  Future<List<UserModel>> getAllUsers() async {
    if (!isAvailable) return [];

    try {
      final snapshot = await _db!.collection(usersCollection).get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }

  /// Récupérer les utilisateurs par rôle
  Future<List<UserModel>> getUsersByRole(String role) async {
    if (!isAvailable) return [];

    try {
      final snapshot =
          await _db!
              .collection(usersCollection)
              .where('role', isEqualTo: role)
              .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Erreur getUsersByRole: $e');
      return [];
    }
  }

  /// Vérifier si un utilisateur existe
  Future<bool> userExists(String uid) async {
    if (!isAvailable) return false;

    try {
      final doc = await _db!.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Erreur userExists: $e');
      return false;
    }
  }

  /// Stream pour écouter les changements d'un utilisateur
  Stream<UserModel?> watchUser(String uid) {
    if (!isAvailable) return Stream.value(null);

    return _db!.collection(usersCollection).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Stream brut des snapshots
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    if (!isAvailable) {
      // Retourner un stream vide pour éviter les erreurs
      throw UnsupportedError('Firestore non disponible sur cette plateforme');
    }

    return _db!.collection(usersCollection).doc(uid).snapshots();
  }

  // ========================================
  // MISE À JOUR
  // ========================================

  /// Mettre à jour les champs d'un utilisateur
  Future<bool> updateUserFields(String uid, Map<String, dynamic> fields) async {
    if (!isAvailable) return false;

    try {
      final docRef = _db!.collection(usersCollection).doc(uid);
      fields['editedAt'] = FieldValue.serverTimestamp();
      await docRef.update(fields);
      print('✅ Champs mis à jour: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur updateUserFields: $e');
      return false;
    }
  }

  /// Mettre à jour l'utilisateur complet (avec merge)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      final docRef = _db!.collection(usersCollection).doc(uid);

      data['editedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data, SetOptions(merge: true));
      print('✅ Utilisateur mis à jour (merge): $uid');
    } catch (e) {
      print('❌ Erreur updateUser: $e');
      rethrow;
    }
  }

  /// Mettre à jour la disponibilité
  Future<void> updateAvailability(String uid, bool isAvailable) async {
    try {
      await updateUserFields(uid, {'dispo': isAvailable});
    } catch (e) {
      print('❌ Erreur updateAvailability: $e');
      rethrow;
    }
  }

  /// Mettre à jour l'URL du logo
  Future<void> updateLogoUrl(String uid, String logoUrl) async {
    try {
      await updateUserFields(uid, {'logoUrl': logoUrl});
    } catch (e) {
      print('❌ Erreur updateLogoUrl: $e');
      rethrow;
    }
  }

  // ========================================
  // GESTION DES PHOTOS
  // ========================================

  /// Ajouter une photo à la galerie
  Future<void> addPhoto(String uid, String photoUrl) async {
    try {
      final docRef = _db!.collection(usersCollection).doc(uid);
      await docRef.update({
        'photos': FieldValue.arrayUnion([photoUrl]),
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Photo ajoutée: $uid');
    } catch (e) {
      print('❌ Erreur addPhoto: $e');
      rethrow;
    }
  }

  /// Supprimer une photo de la galerie
  Future<void> removePhoto(String uid, String photoUrl) async {
    try {
      final docRef = _db!.collection(usersCollection).doc(uid);
      await docRef.update({
        'photos': FieldValue.arrayRemove([photoUrl]),
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Photo supprimée: $uid');
    } catch (e) {
      print('❌ Erreur removePhoto: $e');
      rethrow;
    }
  }

  // ========================================
  // GESTION DES COURS
  // ========================================

  /// Ajouter un cours
  Future<bool> addCourse(String uid, String courseId) async {
    try {
      await _db!.collection(usersCollection).doc(uid).update({
        'courses': FieldValue.arrayUnion([courseId]),
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Cours ajouté: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur addCourse: $e');
      return false;
    }
  }

  /// Retirer un cours
  Future<bool> removeCourse(String uid, String courseId) async {
    try {
      await _db!.collection(usersCollection).doc(uid).update({
        'courses': FieldValue.arrayRemove([courseId]),
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Cours retiré: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur removeCourse: $e');
      return false;
    }
  }

  // ========================================
  // SUPPRESSION
  // ========================================

  /// Supprimer un utilisateur
  Future<bool> deleteUser(String uid) async {
    try {
      await _db!.collection(usersCollection).doc(uid).delete();
      print('✅ Utilisateur supprimé: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur deleteUser: $e');
      return false;
    }
  }

  /// Supprimer complètement un utilisateur (Firestore + Firebase Auth)
  Future<bool> deleteUserCompletely() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final uid = user.uid;

      // 1. Supprimer le document Firestore
      await _db!.collection(usersCollection).doc(uid).delete();
      print('✅ Document Firestore supprimé: $uid');

      // 2. Supprimer le compte Firebase Auth
      await user.delete();
      print('✅ Compte Firebase Auth supprimé: $uid');

      return true;
    } catch (e) {
      print('❌ Erreur deleteUserCompletely: $e');
      return false;
    }
  }
}
