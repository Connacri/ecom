import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilitaires pour la détection de plateforme
class PlatformUtils {
  /// Vérifie si on est sur mobile (Android ou iOS)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Vérifie si on est sur desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Vérifie si on est sur le web
  static bool get isWeb => kIsWeb;

  /// Vérifie si Google Sign-In est supporté
  static bool get supportsGoogleSignIn {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Vérifie si l'authentification par téléphone est supportée
  static bool get supportsPhoneAuth {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Nom de la plateforme actuelle
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Méthodes d'authentification disponibles sur cette plateforme
  static List<String> get availableAuthMethods {
    final methods = <String>['Email/Password'];

    if (supportsGoogleSignIn) {
      methods.add('Google');
    }

    if (supportsPhoneAuth) {
      methods.add('Phone');
    }

    return methods;
  }
}