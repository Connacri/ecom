// providers/child_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;

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
  StreamSubscription<User?>? _authSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    // Écoute les changements d'état d'authentification
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadCurrentUser(user.uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userStream?.cancel(); // <-- il manque ça
    super.dispose();
  }

  Future<void> loadCurrentUser(String userId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('userModel')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      } else {
        _error = "Profil utilisateur non trouvé";
      }
    } catch (e) {
      _error = "Erreur de chargement: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Modifier UserProvider pour écouter les changements
  StreamSubscription<UserModel?>? _userStream;

  void loadCurrentUserS(String userId) {
    _userStream = FirebaseFirestore.instance
        .collection('userModel')
        .doc(userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists
                  ? UserModel.fromMap(snapshot.data()!, userId)
                  : null,
        )
        .listen(
          (user) {
            _user = user;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> updateProfilePhoto(String newUrl) async {
    if (_user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('userModel')
        .doc(_user!.id);

    try {
      // Update the single photo URL in Firestore
      await userRef.update({'logoUrl': newUrl});

      // Update the local user object with the new photo URL
      _user!.logoUrl = newUrl;

      // Notify listeners of the change
      notifyListeners();
    } catch (e) {
      // Handle any errors that occur during the update
      print('Error updating profile photo: $e');
    }
  }

  Future<void> updateListPhoto(String newUrl) async {
    if (_user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('userModel')
        .doc(_user!.id);

    // 1) Construire la nouvelle liste de photos
    List<String> updatedPhotos;
    if (_user!.photos == null || _user!.photos!.isEmpty) {
      updatedPhotos = [newUrl];
    } else {
      // Ajouter la nouvelle URL à la liste existante
      updatedPhotos = List.from(_user!.photos!);
      updatedPhotos.add(newUrl);
    }

    try {
      // 2) Mettre à jour dans Firestore
      await userRef.update({'photos': updatedPhotos});

      // 3) Mettre à jour en local (dans _user)
      _user!.photos = updatedPhotos;

      // 4) Notifier les écouteurs
      notifyListeners();
    } catch (e) {
      // Gérer les erreurs ici
      print('Error updating photo list: $e');
    }
  }
}

class CourseProvider with ChangeNotifier {
  List<Course> _courses = [];
  List<Schedule> _schedules = [];
  List<UserModel> _professors = [];

  List<Course> get courses => _courses;
  List<Schedule> get schedules => _schedules;
  List<UserModel> get professors => _professors;

  void clearcorses() {
    _courses.clear();
    _schedules.clear();

    // Clear the courses list
    _courses.clear();
    // Notify listeners after the build phase is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addCourse(Course course) {
    _courses.add(course);
    notifyListeners();
  }

  void deleteCourse(Course course) {
    _courses.remove(course);
    notifyListeners();
  }

  void addSchedule(Schedule schedule) {
    _schedules.add(schedule);
    notifyListeners();
  }

  void removeSchedule(Schedule schedule) {
    _schedules.remove(schedule);
    notifyListeners();
  }

  void addProfessor(UserModel professor) {
    _professors.add(professor);
    notifyListeners();
  }

  // Add other CRUD operations as needed
}

class ProfProvider with ChangeNotifier {
  List<UserModel> _professors = [];

  List<UserModel> get professors => _professors;

  void addProfessor(UserModel professor) {
    _professors.add(professor);
    notifyListeners();
  }

  Future<void> fetchProfessorsFromFirestore() async {
    try {
      final List<String> _roles = [
        'professeur',
        'coach',
        'entraineur',
        'instructeur',
        'moniteur',
      ];

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', whereIn: _roles)
              .get();

      _professors =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromMap(data, doc.id);
          }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du fetch des professeurs : $e');
    }
  }
}

class StepProvider with ChangeNotifier {
  int _currentStep = 0;

  int get currentStep => _currentStep;

  void nextStep() {
    if (_currentStep < 6) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = 0;
    notifyListeners();
  }
}

class StepProvider1 extends ChangeNotifier {
  int _currentStep = 0;

  // Propriétés pour le formulaire
  String? _nom;
  String? _description;
  int? _nombrePlaces;
  RangeValues? _ageRange;
  osm.GeoPoint? _location;
  Map<String, double>? _prices;

  // Getters
  int get currentStep => _currentStep;
  String? get nom => _nom;
  String? get description => _description;
  int? get nombrePlaces => _nombrePlaces;
  RangeValues? get ageRange => _ageRange;
  osm.GeoPoint? get location => _location;
  Map<String, double>? get prices => _prices;

  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  // Méthodes de mise à jour pour le formulaire
  void updateNom(String nom) {
    _nom = nom;
    notifyListeners();
  }

  void updateDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void updateNombrePlaces(int nombrePlaces) {
    _nombrePlaces = nombrePlaces;
    notifyListeners();
  }

  void updateAgeRange(RangeValues ageRange) {
    _ageRange = ageRange;

    notifyListeners();
  }

  void updateLocation(osm.GeoPoint location) {
    _location = location;
    notifyListeners();
  }

  void updatePrices(Map<String, double> prices) {
    _prices = Map<String, double>.from(prices);
    notifyListeners();
  }

  // Méthode pour réinitialiser les données
  void reset() {
    _currentStep = 0;
    _nom = null;
    _description = null;
    _nombrePlaces = null;
    _ageRange = null;
    _location = null;
    _prices = null;
    notifyListeners();
  }
}
