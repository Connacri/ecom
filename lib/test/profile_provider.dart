import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../activities/modèles.dart';
import 'auth_service.dart';

class ProfileProvider extends ChangeNotifier {
  AuthService _auth;
  UserModel? _user;
  bool _isLoading = false;
  bool _isNewUser = false;
  String? _error;

  // Getters publics
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isNewUser => _isNewUser;
  String? get error => _error;

  ProfileProvider({required AuthService auth}) : _auth = auth;

  // Met à jour l'instance AuthService et recharge le profil si nécessaire
  Future<void> updateAuth(AuthService auth) async {
    if (_auth.user?.uid != auth.user?.uid) {
      _auth = auth;
      await init();
    }
  }

  Future<void> loadCurrentUser(String firebaseUser) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    try {
      //   if (firebaseUser != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('userModel')
              .doc(firebaseUser)
              .get();

      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data()!, userDoc.id);
        // } else {
        //   _error = "Profil utilisateur non trouvé";
        // }
      }
    } catch (e) {
      _error = "Erreur de chargement: ${e.toString()}";
    } finally {
      _isLoading = false;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  // Charge ou crée l'utilisateur dans Firestore
  Future<void> init() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final firebaseUser = _auth.user;

    if (firebaseUser == null) {
      _user = null;
      _isNewUser = false;
      _isLoading = false;
      notifyListeners();
      print('User Firebase est null');
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('userModel')
              .doc(firebaseUser.uid)
              .get();

      if (!doc.exists) {
        _isNewUser = true;
        final data = {
          'name': firebaseUser.displayName ?? '',
          'email': firebaseUser.email ?? '',
          'photos': [firebaseUser.photoURL ?? ''],
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        };

        await doc.reference.set(data);

        _user = UserModel.fromMap(
          data.cast<String, dynamic>(),
          firebaseUser.uid,
        );
        print('Nouvel utilisateur créé: ${_user?.id}');
      } else {
        _isNewUser = false;
        if (doc.data() != null) {
          _user = UserModel.fromMap(doc.data()!, firebaseUser.uid);
          print('Utilisateur existant chargé: ${_user?.id}');
        } else {
          _error = "Le document utilisateur est vide.";
          print(_error);
        }
      }
    } catch (e) {
      _error = "Erreur lors du chargement du profil : $e";
      _user = null;
      _isNewUser = false;
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Met à jour les champs de l'utilisateur Firestore
  Future<void> updateUser(Map<String, dynamic> fields) async {
    if (_user == null) {
      print('Impossible de mettre à jour, utilisateur est null');
      return;
    }

    _error = null;
    final uid = _user!.id;
    fields['editedAt'] = FieldValue.serverTimestamp();

    final docRef = FirebaseFirestore.instance.collection('userModel').doc(uid);

    try {
      await docRef.set(fields, SetOptions(merge: true));
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        _user = UserModel.fromMap(doc.data()!, uid);
        _isNewUser = false;
        notifyListeners();
        print('Utilisateur mis à jour: ${_user?.id}');
      } else {
        _error = "Le document utilisateur n'existe pas ou est vide.";
        print(_error);
      }
    } catch (e) {
      _error = "Erreur lors de la mise à jour de l'utilisateur : $e";
      print(_error);
    }
  }
}
