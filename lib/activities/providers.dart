// providers/child_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'modèles.dart';

class ChildProvider with ChangeNotifier {
  final FirebaseFirestore _firestore;
  List<Child> _children = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded =
      false; // Nouveau flag pour suivre si les données ont été chargées

  List<Child> get children => _children;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? _currentParentId; // Stocke l'ID du parent actuel

  ChildProvider({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  void clearCache() {
    _children.clear();
    _hasLoaded = false;
    _currentParentId = null;
    _error = null;
    notifyListeners();
    print("Cache vidé avec succès");
  }

  Future<void> loadChildren(
    String parentId, {
    bool forceRefresh = false,
  }) async {
    // Si l'utilisateur a changé, vide le cache
    if (_currentParentId != null && _currentParentId != parentId) {
      clearCache();
    }

    if ((_hasLoaded && !forceRefresh) || _isLoading) return;

    _currentParentId = parentId;
    _isLoading = true;
    notifyListeners();

    try {
      final query =
          await _firestore
              .collection('userModel')
              .doc(parentId)
              .collection('children')
              .where('parentId', isEqualTo: parentId)
              .get();

      _children =
          query.docs.map((doc) => Child.fromMap(doc.data(), doc.id)).toList();
      _hasLoaded = true;
    } catch (e) {
      _error = "Erreur lors du chargement: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addChild(Child newChild, String parentId) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('userModel')
          .doc(parentId)
          .collection('children')
          .add({
            ...newChild.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      _children.add(
        Child(
          id: docRef.id,
          name: newChild.name,
          age: newChild.age,
          gender: newChild.gender,
          enrolledCourses: newChild.enrolledCourses,
          parentId: newChild.parentId,
          editedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      throw Exception("Erreur lors de l'ajout: ${e.toString()}");
    }
  }

  Future<bool> updateChild(Child updatedChild, String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('userModel')
          .doc(parentId)
          .collection('children')
          .doc(updatedChild.id)
          .update({
            ...updatedChild.toMap(),
            'editedAt': FieldValue.serverTimestamp(),
          });

      final index = _children.indexWhere((c) => c.id == updatedChild.id);
      if (index != -1) {
        _children[index] = updatedChild;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = "Erreur lors de la mise à jour: ${e.toString()}";
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChild(String childId, String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('userModel')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .delete();
      _children.removeWhere((child) => child.id == childId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Erreur lors de la suppression: ${e.toString()}";
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrentUser(String firebaseUser) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    try {
      if (firebaseUser != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('userModel')
                .doc(firebaseUser)
                .get();

        if (userDoc.exists) {
          _user = UserModel.fromMap(userDoc.data()!, userDoc.id);
        } else {
          _error = "Profil utilisateur non trouvé";
        }
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
}
