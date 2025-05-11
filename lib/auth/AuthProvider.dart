import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print('Connexion annulée par l\'utilisateur');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // 🔥 Insertion dans Supabase après 1re connexion
        //  await _createUserInSupabase(firebaseUser);
      }
      return userCredential.user;
    } catch (e, s) {
      print("Erreur lors de la connexion avec Google : ${e.toString()}");
      print("Stacktrace : $s");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

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
}

Future<void> _createUserInSupabase(User firebaseUser) async {
  final supabase = su.Supabase.instance.client;

  // Vérifie si le user existe déjà
  final existing =
      await supabase
          .from('users')
          .select()
          .eq('firebase_id', firebaseUser.uid)
          .maybeSingle();

  if (existing != null) return; // utilisateur déjà enregistré

  // Insertion
  final response = await supabase.from('users').upsert({
    'firebase_id': firebaseUser.uid,
    'email': firebaseUser.email,
    'full_name': firebaseUser.displayName,
    'phone': firebaseUser.phoneNumber,
    'created_at': DateTime.now().toIso8601String(),
    'metadata': {'photo_url': firebaseUser.photoURL},
  });

  if (response.error != null) {
    print('Erreur insertion Supabase : ${response.error!.message}');
  }
}
