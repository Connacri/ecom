import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Wrapper pour gérer Firebase selon la plateforme
class FirebaseWrapper {
  static bool _initialized = false;
  static bool debugMode = false;

  /// Initialiser Firebase selon la plateforme
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (isDesktop) {
        debugPrint('⚠️ Firebase non initialisé sur Desktop - Mode Offline');
      } else {
        // Initialiser Firebase normalement sur mobile/web
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialisé avec succès');
      }
      _initialized = true;
    } catch (e) {
      debugPrint('❌ Erreur initialisation Firebase: $e');
      _initialized = true; // Continuer quand même
    }
  }

  /// Vérifier si on est sur Desktop
  static bool get isDesktop {
    try {
      return !kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si Firebase est disponible
  static bool get isFirebaseAvailable => !isDesktop && _initialized;

  /// Instance FirebaseAuth (null sur Desktop)
  static FirebaseAuth? get authInstance {
    if (!isFirebaseAvailable) {
      if (debugMode)
        debugPrint('⚠️ Firebase Auth non disponible sur cette plateforme');
      return null;
    }
    return FirebaseAuth.instance;
  }

  /// Utilisateur actuel (null sur Desktop ou si non connecté)
  static User? get currentUser {
    return authInstance?.currentUser;
  }

  /// Stream des changements d'authentification
  static Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable) {
      return Stream.value(null);
    }
    return authInstance!.authStateChanges();
  }

  /// Déconnexion
  static Future<void> signOut() async {
    if (!isFirebaseAvailable) return;
    await authInstance?.signOut();
  }

  /// Afficher les infos de plateforme
  static void printInfo() {
    if (!debugMode) return;

    debugPrint('════════════════════════════════════');
    debugPrint('Firebase Wrapper Info:');
    debugPrint('Platform: ${_getPlatformName()}');
    debugPrint('Desktop: $isDesktop');
    debugPrint('Firebase Available: $isFirebaseAvailable');
    debugPrint('Initialized: $_initialized');
    debugPrint('════════════════════════════════════');
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isMacOS) return 'macOS';
    } catch (e) {
      return 'Unknown';
    }
    return 'Unknown';
  }
}
