import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;

import '../activities/providers.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChildProvider? childProvider;

  // Variables pour gérer l'état de connexion Google
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  // Constructeur conservé identique
  AuthService({this.childProvider}) {
    _initializeGoogleSignIn();
  }

  // Initialisation de Google Sign In avec la nouvelle API
  Future<void> _initializeGoogleSignIn() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      await signIn.initialize();

      // Écouter les événements d'authentification
      _authSubscription = signIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
      )..onError(_handleAuthenticationError);

      // Tentative de connexion silencieuse
      await signIn.attemptLightweightAuthentication();
    } catch (e) {
      print('Erreur lors de l\'initialisation Google Sign In: $e');
    }
  }

  // Gestion des événements d'authentification
  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    _currentUser = user;
    _isAuthorized = user != null;
  }

  // Gestion des erreurs d'authentification
  Future<void> _handleAuthenticationError(Object e) async {
    print('Erreur d\'authentification Google: $e');
    _currentUser = null;
    _isAuthorized = false;
  }

  // MÉTHODE ORIGINALE CORRIGÉE - Nouvelle API uniquement
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      // Vérifier si l'authentification est supportée
      if (!signIn.supportsAuthenticate()) {
        print(
          'L\'authentification Google n\'est pas supportée sur cette plateforme',
        );
        return null;
      }

      // Authentifier l'utilisateur avec la nouvelle API
      await signIn.authenticate();

      // Attendre que l'événement soit traité
      await Future.delayed(const Duration(milliseconds: 500));

      if (_currentUser == null) {
        print('Connexion annulée par l\'utilisateur');
        return null;
      }

      // Obtenir l'authentication token
      final GoogleSignInAuthentication googleAuth =
          await _currentUser!.authentication;

      if (googleAuth.idToken == null) {
        print('Impossible d\'obtenir le token ID');
        return null;
      }

      // Créer le credential Firebase avec l'idToken uniquement
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        print('Connexion Firebase réussie: ${firebaseUser.email}');
        // 🔥 Insertion dans Supabase après 1re connexion
        await createUserInSupabase(firebaseUser);
      }
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      String errorMessage = switch (e.code) {
        GoogleSignInExceptionCode.canceled =>
          'Connexion annulée par l\'utilisateur',
        _ => 'Erreur Google Sign In ${e.code}: ${e.description}',
      };
      print(errorMessage);
      return null;
    } catch (e, s) {
      print("Erreur lors de la connexion avec Google : ${e.toString()}");
      print("Stacktrace : $s");
      return null;
    }
  }

  // MÉTHODE ORIGINALE CORRIGÉE
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
      await _auth.signOut();

      childProvider?.clearCache();

      _currentUser = null;
      _isAuthorized = false;

      // notifyListeners();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // MÉTHODE ORIGINALE CONSERVÉE
  Future<bool> deleteUserAccountPermanently() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Suppression Supabase
      await su.Supabase.instance.client
          .from('signalements')
          .delete()
          .eq('user', user.uid);

      await su.Supabase.instance.client
          .from('users')
          .delete()
          .eq('firebase_id', user.uid);

      // Suppression Firebase
      await user.delete();
      await signOut();

      return true;
    } catch (e) {
      print('Erreur suppression compte: $e');
      return false;
    }
  }

  // Getters utiles pour compatibilité
  GoogleSignInAccount? get currentGoogleUser => _currentUser;
  User? get currentFirebaseUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  // Nettoyage des ressources
  void dispose() {
    _authSubscription?.cancel();
  }
}

// FONCTION ORIGINALE CORRIGÉE
Future<void> createUserInSupabase(User firebaseUser) async {
  try {
    final supabase = su.Supabase.instance.client;

    // Vérifie si le user existe déjà
    final existing =
        await supabase
            .from('users')
            .select()
            .eq(
              'firebase_id',
              firebaseUser.uid,
            ) // CORRECTION: firebase_id au lieu de firebase*id
            .maybeSingle();

    if (existing != null) return; // utilisateur déjà enregistré

    // Insertion
    await supabase.from('users').upsert({
      'firebase_id': firebaseUser.uid,
      'email': firebaseUser.email,
      'full_name': firebaseUser.displayName,
      'phone': firebaseUser.phoneNumber,
      'created_at': DateTime.now().toIso8601String(),
      'metadata': {'photo_url': firebaseUser.photoURL},
    });

    print('Utilisateur créé dans Supabase avec succès');
  } catch (e) {
    print('Erreur insertion Supabase : $e');
  }
}
