// providers/child_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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

class CourseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // État de chargement
  bool _isLoading = false;

  // Données
  List<Course> _courses = [];
  List<UserModel> _clubs = [];
  List<UserModel> _professors = [];

  List<Schedule> _schedules = [];

  // Getters
  List<Course> get courses => _courses;
  List<UserModel> get clubs => _clubs;
  List<UserModel> get professors => _professors;
  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  // Constructeur - Charger les données au démarrage
  CourseProvider() {
    loadData();
  }

  // Charger toutes les données nécessaires
  Future<void> loadData() async {
    try {
      _setLoading(true);

      // Charger les clubs, les professeurs et les cours en parallèle
      final clubsQuery = _firestore
          .collection('userModel')
          .where('role', isEqualTo: 'club');

      final profsQuery = _firestore
          .collection('userModel')
          .where('role', isEqualTo: 'professeur');

      final coursesQuery = _firestore
          .collection('courses')
          .orderBy('editedAt', descending: true);

      final results = await Future.wait([
        clubsQuery.get(),
        profsQuery.get(),
        coursesQuery.get(),
      ]);

      // Transformer les documents en objets du modèle
      final clubs =
          results[0].docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();

      final professors =
          results[1].docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();

      final courses =
          results[2].docs.map((doc) {
            final data = doc.data();
            return Course.fromMap(data, doc.id);
          }).toList();

      // Mettre à jour l'état
      _clubs = clubs;
      _professors = professors;
      _courses = courses;

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter un nouveau professeur
  Future<void> addProfessor(UserModel professor) async {
    try {
      _setLoading(true);

      // Vérifier si le professeur existe déjà
      if (_professors.any((prof) => prof.id == professor.id)) {
        return;
      }

      // Ajouter à Firestore s'il n'existe pas encore
      await _firestore
          .collection('userModel')
          .doc(professor.id)
          .set(professor.toMap());

      // Ajouter à la liste locale
      _professors.add(professor);

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du professeur: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour un cours existant
  Future<bool> updateCourse(Course course) async {
    try {
      _setLoading(true);

      await _firestore.collection('courses').doc(course.id).update({
        'name': course.name,
        'club': course.club.toMap(),
        'clubId': course.club.id,
        'description': course.description,
        'schedules': course.schedules.map((s) => s.toMap()).toList(),
        'ageRange': course.ageRange,
        'profIds': course.profIds,
        'editedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour dans la liste locale
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = course;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du cours: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter un nouveau cours
  Future<bool> addCourse(Course course) async {
    try {
      _setLoading(true);

      final docRef = await _firestore.collection('courses').add({
        'name': course.name,
        'club': course.club.toMap(),
        'clubId': course.club.id,
        'description': course.description,
        'schedules': course.schedules.map((s) => s.toMap()).toList(),
        'ageRange': course.ageRange,
        'profIds': course.profIds,
        'createdAt': FieldValue.serverTimestamp(),
        'editedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'ID et ajouter à la liste locale
      final newCourse = Course(
        id: docRef.id,
        name: course.name,
        club: course.club,
        description: course.description,
        schedules: course.schedules,
        ageRange: course.ageRange,
        profIds: course.profIds,
      );

      _courses.insert(0, newCourse);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du cours: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un cours
  Future<bool> deleteCourse(String courseId) async {
    try {
      _setLoading(true);

      await _firestore.collection('courses').doc(courseId).delete();

      // Supprimer de la liste locale
      _courses.removeWhere((course) => course.id == courseId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du cours: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Créer un nouveau professeur
  Future<UserModel?> createProfessor(String name, String email) async {
    try {
      _setLoading(true);
      final profId = Uuid().v4();

      final newProf = UserModel(
        id: profId,
        name: name,
        email: email,
        role: 'professeur',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        editedAt: DateTime.now(),
        photos: [],
      );

      await _firestore.collection('userModel').doc(profId).set(newProf.toMap());

      // Ajouter à la liste locale
      _professors.add(newProf);

      notifyListeners();
      return newProf;
    } catch (e) {
      debugPrint('Erreur création professeur: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

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

  void addSchedule(Schedule schedule) {
    _schedules.add(schedule);
    notifyListeners();
  }

  void removeSchedule(Schedule schedule) {
    _schedules.remove(schedule);
    notifyListeners();
  }
}

class CourseProvider2 with ChangeNotifier {
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

  void addProfessor(UserModel professor) {
    _professors.add(professor);
    notifyListeners();
  }

  void removeSchedule(Schedule schedule) {
    _schedules.remove(schedule);
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
}
