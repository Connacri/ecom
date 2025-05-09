// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:provider/provider.dart';
//
// import 'auth_wrapper.dart';
//
// class MyAppAuth extends StatelessWidget {
//   const MyAppAuth({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AuthProvider2(),
//       child: MaterialApp(
//         title: 'Google Auth App',
//         home: const AuthWrapper(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }
//
// class AuthProvider2 extends ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//
//   User? _user;
//   User? get user => _user;
//
//   AuthProvider() {
//     _auth.authStateChanges().listen((User? user) {
//       _user = user;
//       notifyListeners();
//     });
//   }
//
//   Future<void> signInWithGoogle() async {
//     try {
//       final googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) return;
//
//       final googleAuth = await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       await _auth.signInWithCredential(credential);
//     } catch (e) {
//       debugPrint('Erreur Auth Google : $e');
//       rethrow;
//     }
//   }
//
//   Future<void> signOut() async {
//     await _auth.signOut();
//     await _googleSignIn.signOut();
//   }
//
//   bool get isLoggedIn => _user != null;
// }
