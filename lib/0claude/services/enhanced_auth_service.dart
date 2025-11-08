import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;

import '../../PlatformUtils.dart';
import 'EnhancedFirestoreService.dart';

/// Service d'authentification complet avec toutes les fonctionnalités
/// - Login universel (Email/Username/Phone)
/// - Google Sign-In avec gestion complète
/// - QR Code authentification
/// - Vérification Email/Phone
/// - Gestion de compte (suppression avec délai)
/// - Support multi-plateforme (Mobile/Web/Desktop)
class EnhancedAuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final EnhancedFirestoreService _firestoreService = EnhancedFirestoreService();

  // État de connexion Google
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  bool _isInitialized = false;

  // ✅ Constructeur avec initialisation conditionnelle
  EnhancedAuthService()
    : _auth = PlatformUtils.isDesktop ? null : FirebaseAuth.instance,
      _firestore = PlatformUtils.isDesktop ? null : FirebaseFirestore.instance {
    if (PlatformUtils.isDesktop) {
      debugPrint(
        '⚠️ EnhancedAuthService en mode Desktop - fonctionnalités limitées',
      );
      _isInitialized = true;
      return;
    }

    // N'initialiser Google Sign-In que sur les plateformes supportées
    if (PlatformUtils.supportsGoogleSignIn) {
      _initializeGoogleSignIn();
    } else {
      debugPrint(
        'ℹ️ Google Sign-In non supporté sur ${PlatformUtils.platformName}',
      );
      _isInitialized = true;
    }
  }

  // Getter public pour accéder au service Firestore
  EnhancedFirestoreService get firestoreService => _firestoreService;

  /// Vérifier si le service est disponible
  bool get isAvailable => !PlatformUtils.isDesktop && _auth != null;

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

      debugPrint('✅ Google Sign In initialisé avec succès');
    } catch (e) {
      debugPrint('⚠️ Initialisation Google Sign In: $e');
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
      debugPrint('✅ Événement: Utilisateur connecté - ${user.email}');
    } else {
      debugPrint('ℹ️ Événement: Utilisateur déconnecté');
    }
  }

  /// Gestion des erreurs d'authentification
  Future<void> _handleAuthenticationError(Object e) async {
    debugPrint('❌ Erreur d\'authentification Google: $e');
    _currentUser = null;
    _isAuthorized = false;
  }

  // ========================================
  // 1. LOGIN UNIVERSEL (Email/Username/Phone)
  // ========================================

  /// Étape 1: Vérifier si l'identifiant existe
  Future<AuthIdentifierResult> checkIdentifier(String identifier) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      identifier = identifier.trim().toLowerCase();

      // Déterminer le type d'identifiant
      if (identifier.contains('@')) {
        // C'est un email - vérifier via Firestore au lieu de fetchSignInMethodsForEmail
        final userDoc = await _firestoreService.getUserByEmail(identifier);

        return AuthIdentifierResult(
          exists: userDoc != null,
          type: IdentifierType.email,
          identifier: identifier,
          userId: userDoc?['uid'],
          signInMethods: userDoc != null ? ['password'] : [],
        );
      } else if (RegExp(r'^\+?[0-9]{10,15}$').hasMatch(identifier)) {
        // C'est un numéro de téléphone
        final userDoc = await _firestoreService.getUserByPhone(identifier);

        return AuthIdentifierResult(
          exists: userDoc != null,
          type: IdentifierType.phone,
          identifier: identifier,
          userId: userDoc?['uid'],
          email: userDoc?['email'],
        );
      } else {
        // C'est un username
        final userDoc = await _firestoreService.getUserByUsername(identifier);

        return AuthIdentifierResult(
          exists: userDoc != null,
          type: IdentifierType.username,
          identifier: identifier,
          userId: userDoc?['uid'],
          email: userDoc?['email'],
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur checkIdentifier: $e');
      rethrow;
    }
  }

  // ========================================
  // 2. INSCRIPTION COMPLÈTE
  // ========================================

  /// Inscription avec email et password
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    String? username,
    String? phone,
    String role = 'parent',
  }) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      // Validation des entrées
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email, mot de passe et nom requis',
        );
      }

      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Le mot de passe doit contenir au moins 6 caractères',
        );
      }

      // Vérifier si l'email existe déjà via Firestore
      final existingUser = await _firestoreService.getUserByEmail(email);
      if (existingUser != null) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Cet email est déjà utilisé',
        );
      }

      // Vérifier si le username existe (si fourni)
      if (username != null && username.isNotEmpty) {
        final isAvailable = await _firestoreService.isUsernameAvailable(
          username,
        );
        if (!isAvailable) {
          throw Exception('Ce nom d\'utilisateur est déjà pris');
        }
      }

      // Créer le compte Firebase Auth
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // Mettre à jour le profil
      await user.updateDisplayName(name.trim());
      await user.reload();

      // Envoyer l'email de vérification
      await user.sendEmailVerification();

      // Créer dans Supabase
      await _createUserInSupabase(user);

      // Créer le document Firestore
      await _firestoreService.createUser(
        uid: user.uid,
        email: email,
        name: name,
        username: username,
        phone: phone,
        role: role,
        emailVerified: false,
      );

      debugPrint('✅ Inscription réussie: ${user.email}');
      debugPrint('📧 Email de vérification envoyé');

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur inscription: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Erreur signUp: $e');
      rethrow;
    }
  }

  /// Inscription simplifiée (compatible avec ancien AuthService)
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    String? name,
    String role = 'parent',
  }) async {
    return signUp(
      email: email,
      password: password,
      name: name ?? email.split('@').first,
      role: role,
    );
  }

  // ========================================
  // 3. CONNEXION AVEC PASSWORD
  // ========================================

  /// Connexion avec identifiant (email/username/phone) et password
  Future<User?> signInWithPassword({
    required String identifier,
    required String password,
  }) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      // Validation
      if (identifier.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Identifiant et mot de passe requis',
        );
      }

      // Vérifier l'identifiant
      final result = await checkIdentifier(identifier);

      if (!result.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Aucun compte trouvé avec cet identifiant',
        );
      }

      // Récupérer l'email pour la connexion
      String email = identifier;

      if (result.type == IdentifierType.username ||
          result.type == IdentifierType.phone) {
        email = result.email!;
      }

      // Connexion Firebase Auth
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Mettre à jour lastLogin
      await _firestoreService.updateLastLogin(user.uid);

      debugPrint('✅ Connexion réussie: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur connexion: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Erreur signInWithPassword: $e');
      rethrow;
    }
  }

  /// Connexion email simple (compatible avec ancien AuthService)
  Future<User?> loginWithEmail(String email, String password) async {
    return signInWithPassword(identifier: email, password: password);
  }

  // ========================================
  // 4. GOOGLE SIGN IN
  // ========================================

  /// Connexion avec Google (crée un compte si n'existe pas)
  Future<User?> signInWithGoogle() async {
    // Vérifier si la plateforme supporte Google Sign-In
    if (!PlatformUtils.supportsGoogleSignIn) {
      debugPrint(
        '❌ Google Sign-In non supporté sur ${PlatformUtils.platformName}',
      );
      throw UnimplementedError(
        'Google Sign-In n\'est pas disponible sur ${PlatformUtils.platformName}. '
        'Utilisez l\'authentification par email/mot de passe.',
      );
    }

    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      await _ensureInitialized();

      final GoogleSignIn signIn = GoogleSignIn.instance;

      // ✅ FIX: Utiliser authenticate() si disponible, sinon méthode alternative
      GoogleSignInAccount? googleUser;

      if (signIn.supportsAuthenticate()) {
        googleUser = await signIn.authenticate();
      } else {
        // Pour les plateformes qui ne supportent pas authenticate()
        // On doit utiliser le stream ou laisser l'utilisateur se connecter manuellement
        debugPrint('⚠️ authenticate() non supporté, tentative alternative...');

        // Vérifier si un utilisateur est déjà dans le cache via le stream
        try {
          // Attendre un événement du stream (timeout après 2 secondes)
          googleUser = await signIn.authenticationEvents
              .where((event) => event is GoogleSignInAuthenticationEventSignIn)
              .map(
                (event) =>
                    (event as GoogleSignInAuthenticationEventSignIn).user,
              )
              .first
              .timeout(
                const Duration(seconds: 2),
                onTimeout:
                    () =>
                        throw TimeoutException(
                          'Aucune connexion Google active',
                        ),
              );
        } catch (e) {
          debugPrint('❌ Impossible de se connecter avec Google: $e');
          throw UnimplementedError(
            'Google Sign-In n\'est pas disponible sur cette plateforme. '
            'Utilisez l\'authentification par email/mot de passe.',
          );
        }
      }

      if (googleUser == null) {
        debugPrint('ℹ️ Connexion Google annulée par l\'utilisateur');
        return null;
      }

      _currentUser = googleUser;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('❌ Impossible d\'obtenir le token ID');
        return null;
      }

      // ✅ FIX: Ne pas utiliser accessToken s'il n'est pas nécessaire
      // idToken seul suffit pour l'authentification Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user!;

      // Vérifier si c'est une première connexion
      final userExists = await _firestoreService.userExists(user.uid);

      if (!userExists) {
        // Créer dans Supabase
        await _createUserInSupabase(user);

        // Créer le document Firestore pour le nouvel utilisateur
        await _firestoreService.createUser(
          uid: user.uid,
          email: user.email!,
          name: user.displayName ?? user.email!.split('@').first,
          username: null,
          phone: user.phoneNumber,
          role: 'parent',
          emailVerified: user.emailVerified,
          photoUrl: user.photoURL,
          signUpMethod: 'google',
        );

        debugPrint('✅ Nouveau compte créé via Google: ${user.email}');
      } else {
        // Mettre à jour lastLogin
        await _firestoreService.updateLastLogin(user.uid);
        debugPrint('✅ Connexion Google existante: ${user.email}');
      }

      return user;
    } on GoogleSignInException catch (e) {
      String errorMessage = switch (e.code) {
        GoogleSignInExceptionCode.canceled =>
          'Connexion annulée par l\'utilisateur',
        _ => 'Erreur Google Sign In ${e.code}: ${e.description}',
      };
      debugPrint('❌ $errorMessage');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur signInWithGoogle: $e');
      debugPrint('Stacktrace: $stackTrace');
      rethrow;
    }
  }

  // ========================================
  // 5. QR CODE AUTHENTICATION
  // ========================================

  /// Générer une session QR Code pour authentification
  Future<String> generateQRSession() async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      final sessionId = await _firestoreService.createQRSession();
      debugPrint('✅ Session QR créée: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('❌ Erreur generateQRSession: $e');
      rethrow;
    }
  }

  /// Scanner et approuver une session QR Code
  Future<bool> approveQRSession(String sessionId) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      final user = _auth!.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final success = await _firestoreService.approveQRSession(
        sessionId,
        user.uid,
      );

      if (success) {
        debugPrint('✅ Session QR approuvée: $sessionId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Erreur approveQRSession: $e');
      rethrow;
    }
  }

  /// Écouter le statut d'une session QR Code
  Stream<String> watchQRSession(String sessionId) {
    return _firestoreService.watchQRSession(sessionId);
  }

  // ========================================
  // 6. VÉRIFICATION EMAIL
  // ========================================

  /// Envoyer un email de vérification
  Future<void> sendEmailVerification() async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      final user = _auth!.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      if (user.emailVerified) {
        debugPrint('ℹ️ Email déjà vérifié');
        return;
      }

      await user.sendEmailVerification();
      debugPrint('✅ Email de vérification envoyé');
    } catch (e) {
      debugPrint('❌ Erreur sendEmailVerification: $e');
      rethrow;
    }
  }

  /// Vérifier si l'email a été confirmé
  Future<bool> checkEmailVerification() async {
    if (!isAvailable) return false;

    try {
      final user = _auth!.currentUser;
      if (user == null) return false;

      await user.reload();
      final currentUser = _auth!.currentUser;

      if (currentUser?.emailVerified ?? false) {
        // Mettre à jour Firestore
        await _firestoreService.updateEmailVerified(user.uid, true);
        debugPrint('✅ Email vérifié');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erreur checkEmailVerification: $e');
      return false;
    }
  }

  // ========================================
  // 7. VÉRIFICATION TÉLÉPHONE (OTP)
  // ========================================

  /// Envoyer un code OTP pour lier un numéro de téléphone
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    // Vérifier si la plateforme supporte l'authentification par téléphone
    if (!PlatformUtils.supportsPhoneAuth) {
      debugPrint(
        '❌ Auth téléphone non supportée sur ${PlatformUtils.platformName}',
      );
      throw UnimplementedError(
        'L\'authentification par téléphone n\'est pas disponible sur ${PlatformUtils.platformName}.',
      );
    }

    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-vérification (Android uniquement)
          await _linkPhoneNumber(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Échec vérification: ${e.code} - ${e.message}');
          onError(e.message ?? 'Erreur de vérification');
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ Code SMS envoyé');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ Timeout auto-retrieval');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('❌ Erreur sendPhoneVerification: $e');
      onError(e.toString());
    }
  }

  /// Vérifier le code OTP et lier le téléphone
  Future<bool> verifyPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (!PlatformUtils.supportsPhoneAuth) {
      throw UnimplementedError(
        'L\'authentification par téléphone n\'est pas disponible sur ${PlatformUtils.platformName}.',
      );
    }

    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      if (smsCode.isEmpty || smsCode.length != 6) {
        throw FirebaseAuthException(
          code: 'invalid-code',
          message: 'Le code SMS doit contenir 6 chiffres',
        );
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      await _linkPhoneNumber(credential);
      return true;
    } catch (e) {
      debugPrint('❌ Erreur verifyPhoneOTP: $e');
      rethrow;
    }
  }

  /// Authentification par téléphone - Étape 1: Envoyer le code (compatible ancien service)
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
  ) async {
    await sendPhoneVerification(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: (error) => throw Exception(error),
    );
  }

  /// Authentification par téléphone - Étape 2: Vérifier le code SMS (compatible ancien service)
  Future<User?> verifySmsCode(String verificationId, String smsCode) async {
    if (!isAvailable) return null;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user!;

      // Créer dans Supabase
      await _createUserInSupabase(user);

      // Vérifier si l'utilisateur existe dans Firestore
      final exists = await _firestoreService.userExists(user.uid);
      if (!exists) {
        await _firestoreService.createUser(
          uid: user.uid,
          email: user.email ?? '',
          name: user.phoneNumber ?? 'Utilisateur',
          phone: user.phoneNumber,
          role: 'parent',
          phoneVerified: true,
          signUpMethod: 'phone',
        );
      }

      debugPrint('✅ Vérification SMS réussie: ${user.phoneNumber}');
      return user;
    } catch (e) {
      debugPrint('❌ Erreur vérification code SMS: $e');
      rethrow;
    }
  }

  /// Lier le numéro de téléphone au compte
  Future<void> _linkPhoneNumber(PhoneAuthCredential credential) async {
    try {
      final user = _auth!.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await user.linkWithCredential(credential);

      // Mettre à jour Firestore
      await _firestoreService.updatePhoneVerified(user.uid, user.phoneNumber!);

      debugPrint('✅ Téléphone lié et vérifié: ${user.phoneNumber}');
    } catch (e) {
      debugPrint('❌ Erreur _linkPhoneNumber: $e');
      rethrow;
    }
  }

  // ========================================
  // 8. MOT DE PASSE OUBLIÉ
  // ========================================

  /// Envoyer un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String identifier) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      // Vérifier l'identifiant
      final result = await checkIdentifier(identifier);

      if (!result.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Aucun compte trouvé avec cet identifiant',
        );
      }

      // Récupérer l'email
      String email = identifier;

      if (result.type == IdentifierType.username ||
          result.type == IdentifierType.phone) {
        email = result.email!;
      }

      // Envoyer l'email de réinitialisation
      await _auth!.sendPasswordResetEmail(email: email);

      debugPrint('✅ Email de réinitialisation envoyé à : $email');
    } catch (e) {
      debugPrint('❌ Erreur sendPasswordResetEmail: $e');
      rethrow;
    }
  }

  /// Réinitialisation mot de passe simple (compatible ancien service)
  Future<void> resetPassword(String email) async {
    return sendPasswordResetEmail(email);
  }

  // ========================================
  // 9. MISE À JOUR PROFIL
  // ========================================

  /// Mettre à jour l'email (avec ré-authentification requise)
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

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

      debugPrint('✅ Email mis à jour: $newEmail');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour email: $e');
      rethrow;
    }
  }

  /// Mettre à jour le mot de passe
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

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

      debugPrint('✅ Mot de passe mis à jour');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour mot de passe: $e');
      rethrow;
    }
  }

  // ========================================
  // 10. SUPPRESSION / DÉSACTIVATION COMPTE
  // ========================================

  /// Demander la suppression du compte (délai de 60 jours)
  Future<void> requestAccountDeletion({String? reason}) async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      final user = _auth!.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _firestoreService.createDeletionRequest(
        uid: user.uid,
        email: user.email!,
        reason: reason,
      );

      debugPrint('✅ Suppression programmée pour dans 60 jours');
    } catch (e) {
      debugPrint('❌ Erreur requestAccountDeletion: $e');
      rethrow;
    }
  }

  /// Annuler la demande de suppression
  Future<void> cancelAccountDeletion() async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      final user = _auth!.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _firestoreService.cancelDeletionRequest(user.uid);
      debugPrint('✅ Suppression annulée');
    } catch (e) {
      debugPrint('❌ Erreur cancelAccountDeletion: $e');
      rethrow;
    }
  }

  /// Supprimer définitivement le compte immédiatement
  Future<void> deleteAccountImmediately() async {
    if (!isAvailable) {
      throw Exception('Service non disponible sur cette plateforme');
    }

    try {
      final user = _auth!.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final uid = user.uid;

      // Supprimer dans Supabase
      try {
        await su.Supabase.instance.client
            .from('signalements')
            .delete()
            .eq('user', uid);
        await su.Supabase.instance.client
            .from('users')
            .delete()
            .eq('firebase_id', uid);
        debugPrint('✅ Données Supabase supprimées');
      } catch (e) {
        debugPrint('⚠️ Erreur Supabase: $e');
      }

      // Supprimer le document Firestore et les données associées
      await _firestoreService.deleteUserPermanently(uid);

      // Supprimer le compte Firebase Auth
      await user.delete();

      debugPrint('✅ Compte supprimé définitivement: $uid');
    } catch (e) {
      debugPrint('❌ Erreur deleteAccountImmediately: $e');
      rethrow;
    }
  }

  /// Suppression définitive du compte (compatible ancien service)
  Future<bool> deleteUserAccountPermanently() async {
    try {
      await deleteAccountImmediately();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression compte: $e');
      return false;
    }
  }

  // ========================================
  // 11. DÉCONNEXION
  // ========================================

  /// Déconnexion complète
  Future<void> signOut() async {
    try {
      // Déconnexion Google seulement si supporté
      if (PlatformUtils.supportsGoogleSignIn) {
        try {
          final GoogleSignIn signIn = GoogleSignIn.instance;
          await signIn.signOut();
          await signIn.disconnect();
        } catch (e) {
          debugPrint('⚠️ Erreur déconnexion Google: $e');
        }
      }

      if (_auth != null) {
        await _auth!.signOut();
      }

      _currentUser = null;
      _isAuthorized = false;

      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la déconnexion: $e');
      // Forcer la déconnexion même en cas d'erreur
      try {
        if (_auth != null) {
          await _auth!.signOut();
        }
        _currentUser = null;
        _isAuthorized = false;
      } catch (_) {}
      rethrow;
    }
  }

  // ========================================
  // 12. SUPABASE INTEGRATION
  // ========================================

  /// Création/mise à jour de l'utilisateur dans Supabase
  Future<void> _createUserInSupabase(User firebaseUser) async {
    try {
      final supabase = su.Supabase.instance.client;

      final existing =
          await supabase
              .from('users')
              .select()
              .eq('firebase_id', firebaseUser.uid)
              .maybeSingle();

      if (existing != null) {
        debugPrint('ℹ️ Utilisateur déjà enregistré dans Supabase');
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

      debugPrint('✅ Utilisateur créé dans Supabase');
    } catch (e) {
      debugPrint('❌ Erreur insertion Supabase: $e');
      // Ne pas propager l'erreur - Supabase optionnel
    }
  }

  // ========================================
  // GETTERS
  // ========================================

  /// Utilisateur Firebase actuel
  User? get currentUser => _auth?.currentUser;

  /// Utilisateur Firebase actuel (alias compatible ancien service)
  User? get currentFirebaseUser => _auth?.currentUser;

  /// Utilisateur Google actuel
  GoogleSignInAccount? get currentGoogleUser => _currentUser;

  /// Vérifier si un utilisateur est connecté
  bool get isSignedIn => _auth?.currentUser != null;

  /// Vérifier si Google est autorisé
  bool get isAuthorized => _isAuthorized;

  /// Stream des changements d'authentification
  Stream<User?> get authStateChanges {
    if (_auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  // ========================================
  // NETTOYAGE
  // ========================================

  /// Nettoyer les ressources
  void dispose() {
    _authSubscription?.cancel();
  }
}

// ========================================
// MODÈLES DE DONNÉES
// ========================================

enum IdentifierType { email, username, phone }

class AuthIdentifierResult {
  final bool exists;
  final IdentifierType type;
  final String identifier;
  final String? userId;
  final String? email;
  final List<String>? signInMethods;

  AuthIdentifierResult({
    required this.exists,
    required this.type,
    required this.identifier,
    this.userId,
    this.email,
    this.signInMethods,
  });

  @override
  String toString() {
    return 'AuthIdentifierResult(exists: $exists, type: $type, identifier: $identifier)';
  }
}

// ========================================
// FONCTION SUPABASE (externe pour compatibilité)
// ========================================

/// Création/mise à jour de l'utilisateur dans Supabase
/// Cette fonction est gardée pour compatibilité avec l'ancien code
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
      debugPrint('ℹ️ Utilisateur déjà enregistré dans Supabase');
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

    debugPrint('✅ Utilisateur créé dans Supabase');
  } catch (e) {
    debugPrint('❌ Erreur insertion Supabase: $e');
  }
}
