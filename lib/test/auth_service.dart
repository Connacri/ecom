import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  Future<void> initialize() async {
    _auth.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null)
      print(
        '*******************************NULL*********************************',
      );
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    user = result.user;
    // print('****************************************************************');
    // print(user);
    // print('****************************************************************');
    final docRef = FirebaseFirestore.instance
        .collection('userModel')
        .doc(user!.uid);
    final snapshot = await docRef.get();
    final data = {
      'name': user!.displayName ?? 'Utilisateur',
      'email': user!.email ?? '',
      'photos': user!.photoURL != null ? [user!.photoURL!] : [],
      'role': '',
      'lastLogin': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'editedAt': FieldValue.serverTimestamp(),
        'phone': '',
        'gender': '',
        'courses': [],
      }, SetOptions(merge: true));
    } else {
      await docRef.update(data);
    }
    notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    user = null;
    notifyListeners();
  }
}
