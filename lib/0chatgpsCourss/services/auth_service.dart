import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;

import '../../PlatformUtils.dart';
import '../../activities/providers.dart' show ChildProvider;
import '../services/firestore_service.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final ChildProvider? childProvider;
  final FirestoreService _firestoreService = FirestoreService();

  // État de connexion Google
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  bool _isInitialized = false;

  // ✅ Constructeur avec initialisation conditionnelle
  AuthService({this.childProvider})
    : _auth = PlatformUtils.isDesktop ? null : FirebaseAuth.instance {
    if (PlatformUtils.isDesktop) {
      print('⚠️ AuthService en mode Desktop - fonctionnalités limitées');
      _isInitialized = true;
      return;
    }

    // N'initialiser Google Sign-In que sur les plateformes supportées
    if (PlatformUtils.supportsGoogleSignIn) {
      _initializeGoogleSignIn();
    } else {
      print('ℹ️ Google Sign-In non supporté sur ${PlatformUtils.platformName}');
      _isInitialized = true;
    }
  }

  // Getter public pour accéder au service Firestore
  FirestoreService get firestoreService => _firestoreService;

  /// Initialisation de Google Sign In selon la doc officielle
  Future<void> _initializeGoogleSignIn() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      await signIn.initialize();
      _isInitialized = true;

      _authSubscription = signIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
      )..onError(_handleAuthenticationError);

      await signIn.attemptLightweightAuthentication();

      print('✅ Google Sign In initialisé avec succès');
    } catch (e) {
      print('⚠️ Initialisation Google Sign In: $e');
      _isInitialized = true;
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

  // ========================================
  // CONNEXION GOOGLE
  // ========================================

  /// Connexion avec Google
  Future<User?> signInWithGoogle() async {
    // Vérifier si la plateforme supporte Google Sign-In
    if (!PlatformUtils.supportsGoogleSignIn) {
      print('❌ Google Sign-In non supporté sur ${PlatformUtils.platformName}');
      throw UnimplementedError(
        'Google Sign-In n\'est pas disponible sur ${PlatformUtils.platformName}. '
        'Utilisez l\'authentification par email/mot de passe.',
      );
    }

    try {
      await _ensureInitialized();

      final GoogleSignIn signIn = GoogleSignIn.instance;

      if (signIn.supportsAuthenticate()) {
        final GoogleSignInAccount? googleUser = await signIn.authenticate();

        if (googleUser == null) {
          print('ℹ️ Connexion annulée par l\'utilisateur');
          return null;
        }

        _currentUser = googleUser;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          print('❌ Impossible d\'obtenir le token ID');
          return null;
        }

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth!.signInWithCredential(
          credential,
        );

        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          print('✅ Connexion Firebase réussie: ${firebaseUser.email}');

          await createUserInSupabase(firebaseUser);
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

  // ========================================
  // INSCRIPTION / CONNEXION EMAIL
  // ========================================

  /// Inscription avec email/password
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String role = 'parent',
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email et mot de passe requis',
        );
      }

      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Le mot de passe doit contenir au moins 6 caractères',
        );
      }

      final UserCredential credential = await _auth!
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final User user = credential.user!;

      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name.trim());
        await user.reload();
      }

      await createUserInSupabase(user);

      await _firestoreService.createOrUpdateUser(
        user,
        additionalData: {'role': role},
      );

      print('✅ Inscription réussie: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur inscription: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Connexion avec email/password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email et mot de passe requis',
        );
      }

      final UserCredential credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User user = credential.user!;

      await _firestoreService.updateUserFields(user.uid, {
        'lastLogin': FieldValue.serverTimestamp(),
      });

      print('✅ Connexion réussie: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur connexion: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Adresse email requise',
        );
      }

      await _auth!.sendPasswordResetEmail(email: email.trim());
      print('✅ Email de réinitialisation envoyé à : $email');
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur réinitialisation: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // ========================================
  // AUTHENTIFICATION PAR TÉLÉPHONE
  // ========================================

  /// Authentification par téléphone - Étape 1: Envoyer le code
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
  ) async {
    // Vérifier si la plateforme supporte l'authentification par téléphone
    if (!PlatformUtils.supportsPhoneAuth) {
      print('❌ Auth téléphone non supportée sur ${PlatformUtils.platformName}');
      throw UnimplementedError(
        'L\'authentification par téléphone n\'est pas disponible sur ${PlatformUtils.platformName}.',
      );
    }

    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          print('✅ Vérification automatique réussie');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Échec vérification: ${e.code} - ${e.message}');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ Code SMS envoyé');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Timeout auto-retrieval: $verificationId');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('❌ Erreur vérification téléphone: $e');
      rethrow;
    }
  }

  /// Authentification par téléphone - Étape 2: Vérifier le code SMS
  Future<User?> verifySmsCode(String verificationId, String smsCode) async {
    if (!PlatformUtils.supportsPhoneAuth) {
      throw UnimplementedError(
        'L\'authentification par téléphone n\'est pas disponible sur ${PlatformUtils.platformName}.',
      );
    }

    try {
      if (smsCode.isEmpty || smsCode.length != 6) {
        throw FirebaseAuthException(
          code: 'invalid-code',
          message: 'Le code SMS doit contenir 6 chiffres',
        );
      }

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final UserCredential userCredential = await _auth!.signInWithCredential(
        credential,
      );

      final User user = userCredential.user!;

      await createUserInSupabase(user);
      await _firestoreService.createOrUpdateUser(user);

      print('✅ Vérification SMS réussie: ${user.phoneNumber}');
      return user;
    } catch (e) {
      print('❌ Erreur vérification code SMS: $e');
      rethrow;
    }
  }

  // ========================================
  // MISE À JOUR PROFIL
  // ========================================

  /// Mettre à jour l'email (avec ré-authentification requise)
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      final user = _auth!.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'Aucun utilisateur connecté',
        );
      }

      // Ré-authentification obligatoire
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Mise à jour email
      await user.verifyBeforeUpdateEmail(newEmail.trim());

      // Mise à jour Firestore
      await _firestoreService.updateUserFields(user.uid, {
        'email': newEmail.trim(),
      });

      print('✅ Email mis à jour: $newEmail');
    } catch (e) {
      print('❌ Erreur mise à jour email: $e');
      rethrow;
    }
  }

  /// Mettre à jour le mot de passe
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth!.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'Aucun utilisateur connecté',
        );
      }

      if (newPassword.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Le mot de passe doit contenir au moins 6 caractères',
        );
      }

      // Ré-authentification obligatoire
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Mise à jour mot de passe
      await user.updatePassword(newPassword);

      print('✅ Mot de passe mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour mot de passe: $e');
      rethrow;
    }
  }

  // ========================================
  // DÉCONNEXION ET SUPPRESSION
  // ========================================

  /// Déconnexion
  Future<void> signOut() async {
    try {
      // Déconnexion Google seulement si supporté
      if (PlatformUtils.supportsGoogleSignIn) {
        try {
          final GoogleSignIn signIn = GoogleSignIn.instance;
          await signIn.disconnect();
        } catch (e) {
          print('⚠️ Erreur déconnexion Google: $e');
        }
      }

      await _auth!.signOut();

      childProvider?.clearCache();

      _currentUser = null;
      _isAuthorized = false;

      print('✅ Déconnexion réussie');
    } catch (e) {
      print('⚠️ Erreur lors de la déconnexion: $e');
      try {
        await _auth!.signOut();
        _currentUser = null;
        _isAuthorized = false;
      } catch (_) {}
    }
  }

  /// Suppression définitive du compte
  Future<bool> deleteUserAccountPermanently() async {
    try {
      final user = _auth!.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final uid = user.uid;

      // 1. Suppression Supabase
      try {
        await su.Supabase.instance.client
            .from('signalements')
            .delete()
            .eq('user', uid);
        await su.Supabase.instance.client
            .from('users')
            .delete()
            .eq('firebase_id', uid);
        print('✅ Données Supabase supprimées');
      } catch (e) {
        print('⚠️ Erreur Supabase: $e');
      }

      // 2. Suppression Firestore + Firebase Auth
      final deleted = await _firestoreService.deleteUserCompletely();

      if (!deleted) {
        print('⚠️ Erreur lors de la suppression');
        return false;
      }

      // 3. Déconnexion Google
      await signOut();

      print('✅ Compte supprimé complètement');
      return true;
    } catch (e) {
      print('❌ Erreur suppression compte: $e');
      return false;
    }
  }

  // ========================================
  // GETTERS
  // ========================================

  GoogleSignInAccount? get currentGoogleUser => _currentUser;
  User? get currentFirebaseUser => _auth!.currentUser;
  bool get isSignedIn => _auth!.currentUser != null;
  bool get isAuthorized => _isAuthorized;

  Stream<User?> get authStateChanges => _auth!.authStateChanges();

  void dispose() {
    _authSubscription?.cancel();
  }
}

// ========================================
// FONCTION SUPABASE (externe)
// ========================================

/// Création/mise à jour de l'utilisateur dans Supabase
Future<void> createUserInSupabase(User firebaseUser) async {
  try {
    final supabase = su.Supabase.instance.client;

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

    await supabase.from('users').insert({
      'firebase_id': firebaseUser.uid,
      'email': firebaseUser.email,
      'full_name': firebaseUser.displayName,
      'phone': firebaseUser.phoneNumber,
      'created_at': DateTime.now().toIso8601String(),
      'metadata': {'photo_url': firebaseUser.photoURL},
    });

    print('✅ Utilisateur créé dans Supabase');
  } catch (e) {
    print('❌ Erreur insertion Supabase: $e');
  }
}
