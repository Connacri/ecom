import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;

import '../activities/providers.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChildProvider? childProvider;
  final FirestoreUserService _firestoreService =
      FirestoreUserService(); // ✅ Nouveau

  // État de connexion Google
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  bool _isInitialized = false;

  // Constructeur avec initialisation
  AuthService({this.childProvider}) {
    _initializeGoogleSignIn();
  }

  /// Initialisation de Google Sign In selon la doc officielle
  Future<void> _initializeGoogleSignIn() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      // Initialiser (peut échouer sur certaines plateformes, c'est normal)
      await signIn.initialize();
      _isInitialized = true;

      // Écouter les événements d'authentification
      _authSubscription = signIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
      )..onError(_handleAuthenticationError);

      // Tentative de connexion silencieuse (lightweight)
      await signIn.attemptLightweightAuthentication();

      print('✅ Google Sign In initialisé avec succès');
    } catch (e) {
      // Sur certaines plateformes, initialize() peut ne pas être disponible
      print(
        '⚠️ Initialisation Google Sign In: $e (peut être normal sur certaines plateformes)',
      );
      _isInitialized = true; // On continue quand même
    }
  }

  /// S'assurer que GoogleSignIn est initialisé
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  /// Gestion des événements d'authentification (stream-based)
  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    _currentUser = user;
    _isAuthorized = user != null;

    if (user != null) {
      print('✅ Événement: Utilisateur connecté - ${user.email}');
    } else {
      print('ℹ️ Événement: Utilisateur déconnecté');
    }
  }

  /// Gestion des erreurs d'authentification
  Future<void> _handleAuthenticationError(Object e) async {
    print('❌ Erreur d\'authentification Google: $e');
    _currentUser = null;
    _isAuthorized = false;
  }

  /// Connexion avec Google (CORRIGÉ selon la vraie API v7.x)
  Future<User?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      final GoogleSignIn signIn = GoogleSignIn.instance;

      // Vérifier si authenticate() est supporté
      if (signIn.supportsAuthenticate()) {
        // authenticate() retourne directement le GoogleSignInAccount
        final GoogleSignInAccount? googleUser = await signIn.authenticate();

        if (googleUser == null) {
          print('ℹ️ Connexion annulée par l\'utilisateur');
          return null;
        }

        _currentUser = googleUser;

        // Obtenir les tokens d'authentification
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // CORRECTION: Les propriétés sont idToken et accessToken
        if (googleAuth.idToken == null) {
          print('❌ Impossible d\'obtenir le token ID');
          return null;
        }

        // Créer le credential Firebase avec les deux tokens
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Se connecter à Firebase
        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          print('✅ Connexion Firebase réussie: ${firebaseUser.email}');

          // ✅ Créer/mettre à jour dans Supabase
          await createUserInSupabase(firebaseUser);

          // ✅ Créer/mettre à jour dans Firestore
          await _firestoreService.createOrUpdateUser(firebaseUser);
        }

        return firebaseUser;
      } else {
        print('❌ authenticate() non supporté sur cette plateforme');
        return null;
      }
    } on GoogleSignInException catch (e) {
      String errorMessage = switch (e.code) {
        GoogleSignInExceptionCode.canceled =>
          'Connexion annulée par l\'utilisateur',
        _ => 'Erreur Google Sign In ${e.code}: ${e.description}',
      };
      print('❌ $errorMessage');
      return null;
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la connexion avec Google: $e');
      print('Stacktrace: $stackTrace');
      return null;
    }
  }

  /// Déconnexion (CORRIGÉ selon la vraie API)
  Future<void> signOut() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      // Utiliser disconnect() comme dans l'exemple officiel
      await signIn.disconnect();

      // Déconnexion Firebase
      await _auth.signOut();

      // Nettoyage du cache local
      childProvider?.clearCache();

      // Réinitialiser l'état
      _currentUser = null;
      _isAuthorized = false;

      print('✅ Déconnexion réussie');
    } catch (e) {
      print('⚠️ Erreur lors de la déconnexion: $e');
      // On continue même en cas d'erreur pour assurer la déconnexion Firebase
      try {
        await _auth.signOut();
        _currentUser = null;
        _isAuthorized = false;
      } catch (_) {}
    }
  }

  /// Suppression définitive du compte (VERSION AMÉLIORÉE)
  /// Supprime de Firebase Auth, Firestore ET Supabase
  Future<bool> deleteUserAccountPermanently() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final uid = user.uid;

      // 1. Suppression des données Supabase
      try {
        await su.Supabase.instance.client
            .from('signalements')
            .delete()
            .eq('user', uid);
        print('✅ Signalements Supabase supprimés');

        await su.Supabase.instance.client
            .from('users')
            .delete()
            .eq('firebase_id', uid);
        print('✅ Utilisateur Supabase supprimé');
      } catch (e) {
        print('⚠️ Erreur Supabase (on continue): $e');
      }

      // 2. Suppression Firestore + Firebase Auth via le service
      final firestoreDeleted = await _firestoreService.deleteUserCompletely();

      if (!firestoreDeleted) {
        print('⚠️ Erreur lors de la suppression Firestore/Auth');
        return false;
      }

      // 3. Déconnexion Google Sign In
      await signOut();

      print('✅ Compte supprimé complètement de tous les services');
      return true;
    } catch (e) {
      print('❌ Erreur suppression compte: $e');
      return false;
    }
  }

  // Getters
  GoogleSignInAccount? get currentGoogleUser => _currentUser;
  User? get currentFirebaseUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  bool get isAuthorized => _isAuthorized;

  /// Stream pour écouter les changements d'état Firebase
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Nettoyage des ressources
  void dispose() {
    _authSubscription?.cancel();
  }
}

/// Création/mise à jour de l'utilisateur dans Supabase
Future<void> createUserInSupabase(User firebaseUser) async {
  try {
    final supabase = su.Supabase.instance.client;

    // Vérification si l'utilisateur existe déjà
    final existing =
        await supabase
            .from('users')
            .select()
            .eq('firebase_id', firebaseUser.uid)
            .maybeSingle();

    if (existing != null) {
      print('ℹ️ Utilisateur déjà enregistré dans Supabase');
      return;
    }

    // Insertion du nouvel utilisateur
    await supabase.from('users').insert({
      'firebase_id': firebaseUser.uid,
      'email': firebaseUser.email,
      'full_name': firebaseUser.displayName,
      'phone': firebaseUser.phoneNumber,
      'created_at': DateTime.now().toIso8601String(),
      'metadata': {'photo_url': firebaseUser.photoURL},
    });

    print('✅ Utilisateur créé dans Supabase avec succès');
  } catch (e) {
    print('❌ Erreur insertion Supabase: $e');
  }
}

/// Service pour gérer les opérations Firestore sur les utilisateurs
class FirestoreUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection principale des utilisateurs
  static const String _usersCollection = 'userModel';

  /// Crée ou met à jour un utilisateur dans Firestore
  ///
  /// Paramètres:
  /// - [user]: L'utilisateur Firebase authentifié
  /// - [additionalData]: Données supplémentaires optionnelles (ex: role, phone, gender)
  /// - [forceCreate]: Si true, force la création même si le document existe
  ///
  /// Retourne: true si l'opération a réussi, false sinon
  Future<bool> createOrUpdateUser(
    User user, {
    Map<String, dynamic>? additionalData,
    bool forceCreate = false,
  }) async {
    try {
      final uid = user.uid;
      final docRef = _firestore.collection(_usersCollection).doc(uid);

      // Données de base de l'utilisateur
      final baseData = {
        'name': user.displayName ?? 'Utilisateur',
        'email': user.email ?? '',
        'photos': user.photoURL != null ? [user.photoURL!] : [],
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Vérifier si le document existe
      final snapshot = await docRef.get();

      if (!snapshot.exists || forceCreate) {
        // ✅ CRÉATION du document
        final createData = {
          ...baseData,
          'createdAt': FieldValue.serverTimestamp(),
          'editedAt': FieldValue.serverTimestamp(),
          'phone': '',
          'gender': '',
          'courses': [],
          'role': 'sero',
          ...?additionalData, // Fusionne les données supplémentaires
        };

        await docRef.set(createData, SetOptions(merge: true));
        print('✅ Utilisateur créé dans Firestore: $uid');
      } else {
        // ✅ MISE À JOUR du document
        final updateData = {
          ...baseData,
          'editedAt': FieldValue.serverTimestamp(),
          ...?additionalData, // Fusionne les données supplémentaires
        };

        await docRef.update(updateData);
        print('✅ Utilisateur mis à jour dans Firestore: $uid');
      }

      return true;
    } catch (e) {
      print('❌ Erreur lors de la création/mise à jour Firestore: $e');
      return false;
    }
  }

  /// Récupère les données d'un utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return null;
    }
  }

  /// Met à jour des champs spécifiques d'un utilisateur
  Future<bool> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        ...fields,
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Champs mis à jour pour l\'utilisateur: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des champs: $e');
      return false;
    }
  }

  /// Supprime un utilisateur de Firestore uniquement
  /// Utilisez deleteUserCompletely() pour supprimer de Firebase Auth aussi
  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      print('✅ Utilisateur supprimé de Firestore: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Supprime complètement un utilisateur:
  /// - Firebase Authentication
  /// - Firestore userModel
  /// - Retourne le User avant suppression pour d'autres opérations (ex: Supabase)
  ///
  /// ⚠️ ATTENTION: Cette action est irréversible!
  Future<bool> deleteUserCompletely() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final uid = user.uid;

      // 1. Supprimer de Firestore
      await _firestore.collection(_usersCollection).doc(uid).delete();
      print('✅ Document Firestore supprimé: $uid');

      // 2. Supprimer de Firebase Authentication
      await user.delete();
      print('✅ Compte Firebase Auth supprimé: $uid');

      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression complète: $e');
      return false;
    }
  }

  /// Ajoute un cours à la liste des cours d'un utilisateur
  Future<bool> addCourse(String uid, String courseId) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'courses': FieldValue.arrayUnion([courseId]),
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Cours ajouté pour l\'utilisateur: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du cours: $e');
      return false;
    }
  }

  /// Retire un cours de la liste des cours d'un utilisateur
  Future<bool> removeCourse(String uid, String courseId) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'courses': FieldValue.arrayRemove([courseId]),
        'editedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Cours retiré pour l\'utilisateur: $uid');
      return true;
    } catch (e) {
      print('❌ Erreur lors du retrait du cours: $e');
      return false;
    }
  }

  /// Stream pour écouter les changements en temps réel d'un utilisateur
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots();
  }
}
