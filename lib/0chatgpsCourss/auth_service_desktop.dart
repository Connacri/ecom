/// Service d'authentification factice pour Desktop
/// Utilisé uniquement pour le développement/test
class DesktopAuthService {
  // Stockage en mémoire pour le développement
  static String? _mockUserId;
  static String? _mockUserEmail;

  Future<MockUser?> loginWithEmail(String email, String password) async {
    // Simulation d'une connexion pour le développement
    await Future.delayed(const Duration(seconds: 1));

    _mockUserId = 'desktop_user_${DateTime.now().millisecondsSinceEpoch}';
    _mockUserEmail = email;

    return MockUser(uid: _mockUserId!, email: email);
  }

  Future<void> signOut() async {
    _mockUserId = null;
    _mockUserEmail = null;
  }

  MockUser? get currentUser {
    if (_mockUserId == null) return null;
    return MockUser(uid: _mockUserId!, email: _mockUserEmail!);
  }

  Stream<MockUser?> get authStateChanges {
    // Pour Desktop, retourner un stream simple
    return Stream.value(currentUser);
  }
}

class MockUser {
  final String uid;
  final String email;

  MockUser({required this.uid, required this.email});
}
