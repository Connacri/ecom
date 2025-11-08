import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../PlatformUtils.dart';

class FirebaseWrapper {
  static FirebaseAuth? get authInstance {
    if (PlatformUtils.isDesktop) {
      debugPrint('⚠️ Firebase Auth non disponible sur Desktop');
      return null;
    }
    return FirebaseAuth.instance;
  }

  static User? get currentUser {
    if (PlatformUtils.isDesktop) {
      return null;
    }
    return FirebaseAuth.instance.currentUser;
  }

  static Stream<User?> get authStateChanges {
    if (PlatformUtils.isDesktop) {
      return Stream.value(null);
    }
    return FirebaseAuth.instance.authStateChanges();
  }

  static bool get isFirebaseAvailable {
    return !PlatformUtils.isDesktop;
  }
}
