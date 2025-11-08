import 'package:flutter/material.dart';

import '../../activities/modèles.dart';
import '../services/firestore_service.dart';

class UserProviderGpt with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get loading => _loading;

  /// Charger les données utilisateur depuis Firestore
  Future<void> loadUser(String uid) async {
    // Ne pas notifier pendant le chargement si déjà en cours
    if (_loading) return;

    _loading = true;
    notifyListeners();

    try {
      _user = await _firestoreService.getUser(uid);

      if (_user == null) {
        print('⚠️ Utilisateur non trouvé dans Firestore: $uid');
      }
    } catch (e) {
      print('❌ Erreur chargement utilisateur: $e');
      _user = null;
      rethrow; // Propager l'erreur pour la gestion dans l'UI
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Rafraîchir les données si nécessaire
  Future<void> refreshIfNeeded(String uid) async {
    await loadUser(uid);
  }

  /// Mettre à jour des champs spécifiques
  Future<void> updateFields(Map<String, dynamic> fields) async {
    if (_user == null) {
      print('⚠️ Aucun utilisateur à mettre à jour');
      return;
    }

    try {
      await _firestoreService.updateUserFields(_user!.id, fields);
      await loadUser(_user!.id);
    } catch (e) {
      print('❌ Erreur mise à jour champs: $e');
      rethrow;
    }
  }

  /// Mettre à jour la disponibilité
  Future<void> updateAvailability(bool isAvailable) async {
    if (_user == null) return;

    try {
      await _firestoreService.updateAvailability(_user!.id, isAvailable);
      await loadUser(_user!.id);
    } catch (e) {
      print('❌ Erreur mise à jour disponibilité: $e');
      rethrow;
    }
  }

  /// Ajouter une photo
  Future<void> addPhoto(String photoUrl) async {
    if (_user == null) return;

    try {
      await _firestoreService.addPhoto(_user!.id, photoUrl);
      await loadUser(_user!.id);
    } catch (e) {
      print('❌ Erreur ajout photo: $e');
      rethrow;
    }
  }

  /// Supprimer une photo
  Future<void> removePhoto(String photoUrl) async {
    if (_user == null) return;

    try {
      await _firestoreService.removePhoto(_user!.id, photoUrl);
      await loadUser(_user!.id);
    } catch (e) {
      print('❌ Erreur suppression photo: $e');
      rethrow;
    }
  }

  /// Ajouter un cours
  Future<void> addCourse(String courseId) async {
    if (_user == null) return;

    try {
      await _firestoreService.addCourse(_user!.id, courseId);
      await loadUser(_user!.id);
    } catch (e) {
      print('❌ Erreur ajout cours: $e');
      rethrow;
    }
  }

  /// Retirer un cours
  Future<void> removeCourse(String courseId) async {
    if (_user == null) return;

    try {
      await _firestoreService.removeCourse(_user!.id, courseId);
      await loadUser(_user!.id);
    } catch (e) {
      print('❌ Erreur retrait cours: $e');
      rethrow;
    }
  }

  /// Effacer les données (lors de la déconnexion)
  void clear() {
    _user = null;
    _loading = false;
    notifyListeners();
  }
}
