import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'modèles.dart';

class ClubProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Child> _children = [];
  List<Club> _clubs = [];
  bool _isLoading = false;
  bool _hasData = false;

  List<Child> get children => List.unmodifiable(_children);
  List<Club> get clubs => List.unmodifiable(_clubs);
  bool get isLoading => _isLoading;
  bool get hasData => _hasData;

  ClubProvider() {
    _listenToChildren();
    _listenToClubs();
  }

  void _listenToChildren() {
    _firestore
        .collection('children')
        .snapshots()
        .listen(
          (snapshot) {
            _children =
                snapshot.docs
                    .map((doc) => Child.fromMap(doc.data(), doc.id))
                    .toList();
            _hasData = true;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Erreur _listenToChildren: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _listenToClubs() {
    _firestore
        .collection('clubs')
        .snapshots()
        .listen(
          (clubsSnapshot) async {
            final clubsTemp = <Club>[];
            final allCourseIds =
                clubsSnapshot.docs
                    .expand(
                      (doc) => List<String>.from(doc.data()['courses'] ?? []),
                    )
                    .toSet()
                    .toList();
            final courseChunks = _chunkList(allCourseIds, 30);
            final coursesMap = <String, Course>{};

            final futures = courseChunks.map(
              (chunk) =>
                  _firestore
                      .collection('courses')
                      .where(FieldPath.documentId, whereIn: chunk)
                      .get(),
            );

            final results = await Future.wait(futures);

            for (final snapshot in results) {
              for (final doc in snapshot.docs) {
                coursesMap[doc.id] = Course.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              }
            }

            for (final clubDoc in clubsSnapshot.docs) {
              final clubData = clubDoc.data() as Map<String, dynamic>;
              final club = Club.fromMap(clubData, clubDoc.id);
              final courseIds = List<String>.from(clubData['courses'] ?? []);
              club.courses.addAll(
                courseIds.map((id) => coursesMap[id]).whereType<Course>(),
              );
              clubsTemp.add(club);
            }

            _clubs = clubsTemp;
            _hasData = true;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Erreur _listenToClubs: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  Future<void> addChild(Child child) async {
    try {
      final batch = _firestore.batch();
      final childDocRef = _firestore.collection('children').doc();
      batch.set(childDocRef, {
        'id': childDocRef.id,
        'name': child.name,
        'age': child.age,
        'enrolledCourses': child.enrolledCourses,
        'parentId': child.parentId,
        'gender': child.gender,
      });

      final parentDocRef = _firestore
          .collection('userModel')
          .doc(child.parentId);
      batch.update(parentDocRef, {
        'childrenIds': FieldValue.arrayUnion([childDocRef.id]),
      });

      await batch.commit();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur addChild: $e');
      rethrow;
    }
  }

  Future<void> updateChild(Child child) async {
    try {
      await _firestore
          .collection('children')
          .doc(child.id)
          .update(child.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur updateChild: $e');
      rethrow;
    }
  }

  Future<void> deleteChild(String id) async {
    try {
      final batch = _firestore.batch();
      final childRef = _firestore.collection('children').doc(id);

      final child = _children.firstWhere((c) => c.id == id);
      if (child.parentId.isNotEmpty) {
        final parentRef = _firestore
            .collection('userModel')
            .doc(child.parentId);
        batch.update(parentRef, {
          'childrenIds': FieldValue.arrayRemove([id]),
        });
      }

      batch.delete(childRef);
      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur deleteChild: $e');
      rethrow;
    }
  }

  Future<void> addClub(Club club) async {
    try {
      final batch = _firestore.batch();
      final clubRef = _firestore.collection('clubs').doc(club.id);

      for (final course in club.courses) {
        final courseRef = _firestore.collection('courses').doc(course.id);
        batch.set(courseRef, course.toMap());
      }

      batch.set(clubRef, club.toMap());

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur addClub: $e');
      rethrow;
    }
  }

  Future<void> updateClub(Club club) async {
    try {
      await _firestore.collection('clubs').doc(club.id).update(club.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur updateClub: $e');
      rethrow;
    }
  }

  Future<void> deleteClub(String id) async {
    try {
      final club = _clubs.firstWhere((c) => c.id == id);
      final batch = _firestore.batch();

      for (final course in club.courses) {
        batch.delete(_firestore.collection('courses').doc(course.id));
      }

      batch.delete(_firestore.collection('clubs').doc(id));

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur deleteClub: $e');
      rethrow;
    }
  }

  Future<void> addCourse(String clubId, Course course) async {
    try {
      final batch = _firestore.batch();
      final courseRef = _firestore.collection('courses').doc(course.id);

      batch.set(courseRef, course.toMap());
      batch.update(_firestore.collection('clubs').doc(clubId), {
        'courses': FieldValue.arrayUnion([course.id]),
      });

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur addCourse: $e');
      rethrow;
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      await _firestore
          .collection('courses')
          .doc(course.id)
          .update(course.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur updateCourse: $e');
      rethrow;
    }
  }

  Future<void> deleteCourse(String clubId, String courseId) async {
    try {
      final batch = _firestore.batch();

      batch.delete(_firestore.collection('courses').doc(courseId));
      batch.update(_firestore.collection('clubs').doc(clubId), {
        'courses': FieldValue.arrayRemove([courseId]),
      });

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur deleteCourse: $e');
      rethrow;
    }
  }

  // Ajoutez ces getters pour les Streams
  Stream<List<Child>> get childrenStream {
    return _firestore
        .collection('children')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Child.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Stream des clubs avec leurs cours
  Stream<List<Club>> get clubsStream {
    return _firestore.collection('clubs').snapshots().asyncMap((
      clubsSnapshot,
    ) async {
      final coursesMap = await _fetchCoursesMap(clubsSnapshot);
      return clubsSnapshot.docs.map((doc) {
        final club = Club.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        final courseIds = List<String>.from(doc.data()['courses'] ?? []);
        club.courses.addAll(
          courseIds.map((id) => coursesMap[id]).whereType<Course>(),
        );
        return club;
      }).toList();
    });
  }

  // Méthode pour récupérer les cours par lots (batch)
  Future<Map<String, Course>> _fetchCoursesMap(
    QuerySnapshot clubsSnapshot,
  ) async {
    final allCourseIds =
        clubsSnapshot.docs
            .expand((doc) => List<String>.from(doc['courses'] ?? []))
            .toSet()
            .toList();

    final courseChunks = _chunkList(
      allCourseIds,
      10,
    ); // Limite Firestore whereIn à 10
    final coursesMap = <String, Course>{};

    // Exécute les requêtes par lots
    final futures = courseChunks.map(
      (chunk) =>
          _firestore
              .collection('courses')
              .where(FieldPath.documentId, whereIn: chunk)
              .get(),
    );

    final results = await Future.wait(futures);

    // Remplit la map des cours
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        coursesMap[doc.id] = Course.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
    }

    return coursesMap;
  }
}

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _users = [];
  List<ParentWithChildren> _parentsWithChildren = [];
  bool _isLoading = false;
  bool _hasData = false;

  List<UserModel> get users => List.unmodifiable(_users);
  List<ParentWithChildren> get parentsWithChildren =>
      List.unmodifiable(_parentsWithChildren);
  bool get isLoading => _isLoading;
  bool get hasData => _hasData;

  UserProvider() {
    _listenToUsers();
    _listenToParentChildRelations();
  }

  void _listenToUsers() {
    _firestore
        .collection('userModel')
        .orderBy('name')
        .snapshots()
        .listen(
          (snapshot) {
            _users =
                snapshot.docs
                    .map((doc) => UserModel.fromMap(doc.data(), doc.id))
                    .toList();
            _hasData = true;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Erreur _listenToUsers: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _listenToParentChildRelations() {
    _firestore
        .collection('children')
        .snapshots()
        .listen(
          (childSnapshot) {
            final allChildren =
                childSnapshot.docs
                    .map((doc) => Child.fromMap(doc.data(), doc.id))
                    .toList();
            final parents =
                _users.where((u) => u.childrenIds.isNotEmpty).toList();

            final result =
                parents.map((parent) {
                  final children =
                      allChildren
                          .where(
                            (child) => parent.childrenIds.contains(child.id),
                          )
                          .toList();
                  return ParentWithChildren(parent: parent, children: children);
                }).toList();

            _parentsWithChildren = result;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Erreur _listenToParentChildRelations: $e');
            notifyListeners();
          },
        );
  }

  // Future<void> loadUser(String userId) async {
  //   try {
  //     _isLoading = true;
  //     notifyListeners();
  //
  //     // 1. Recharge le parent
  //     final parentDoc =
  //         await _firestore.collection('userModel').doc(userId).get();
  //     final updatedUser = UserModel.fromMap(parentDoc.data()!, parentDoc.id);
  //
  //     // 2. Met à jour la liste locale
  //     final index = _users.indexWhere((u) => u.id == userId);
  //     if (index != -1) {
  //       _users[index] = updatedUser;
  //     }
  //
  //     // 3. Recharge les enfants associés
  //     final childrenSnapshot =
  //         await _firestore
  //             .collection('children')
  //             .where('parentId', isEqualTo: userId)
  //             .get();
  //
  //     final updatedChildren =
  //         childrenSnapshot.docs
  //             .map((doc) => Child.fromMap(doc.data(), doc.id))
  //             .toList();
  //
  //     // 4. Met à jour parentsWithChildren
  //     final parentWithChildrenIndex = _parentsWithChildren.indexWhere(
  //       (p) => p.parent.id == userId,
  //     );
  //
  //     if (parentWithChildrenIndex != -1) {
  //       _parentsWithChildren[parentWithChildrenIndex] = ParentWithChildren(
  //         parent: updatedUser,
  //         children: updatedChildren,
  //       );
  //     }
  //
  //     _isLoading = false;
  //     notifyListeners();
  //   } catch (e) {
  //     _isLoading = false;
  //     debugPrint('Erreur loadUser: $e');
  //     notifyListeners();
  //     rethrow;
  //   }
  // }
  // Ajoutez ce stream
  Stream<List<ParentWithChildren>> get parentsWithChildrenStream {
    return _firestore.collection('userModel').snapshots().asyncMap((
      snapshot,
    ) async {
      final parents =
          snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();

      final children = await _firestore.collection('children').get();
      final allChildren =
          children.docs
              .map((doc) => Child.fromMap(doc.data(), doc.id))
              .toList();

      return parents.map((parent) {
        return ParentWithChildren(
          parent: parent,
          children:
              allChildren
                  .where((c) => parent.childrenIds.contains(c.id))
                  .toList(),
        );
      }).toList();
    });
  }

  Future<void> addUser(UserModel user) async {
    try {
      await _firestore.collection('userModel').doc(user.id).set(user.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur addUser: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('userModel')
          .doc(user.id)
          .update(user.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur updateUser: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final user = _users.firstWhere((u) => u.id == id);
      final batch = _firestore.batch();

      final userRef = _firestore.collection('userModel').doc(id);
      batch.delete(userRef);

      for (final childId in user.childrenIds) {
        final childRef = _firestore.collection('children').doc(childId);
        batch.update(childRef, {'parentId': FieldValue.delete()});
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur deleteUser: $e');
      rethrow;
    }
  }

  Future<void> assignChildToParent(String childId, String parentId) async {
    try {
      final batch = _firestore.batch();

      final parentRef = _firestore.collection('userModel').doc(parentId);
      final childRef = _firestore.collection('children').doc(childId);

      batch.update(parentRef, {
        'childrenIds': FieldValue.arrayUnion([childId]),
      });

      batch.update(childRef, {'parentId': parentId});

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur assignChildToParent: $e');
      rethrow;
    }
  }

  // Method to get children by user ID
  List<Child> getChildrenByUserId(String userId) {
    try {
      final parentWithChildren = _parentsWithChildren.firstWhere(
        (parent) => parent.parent.id == userId,
        orElse:
            () => ParentWithChildren(
              parent: UserModel(
                id: '',
                name: '',
                email: '',
                childrenIds: [],
                gender: '',
                phone: '',
                createdAt: null,
                lastLogin: null,
                editedAt: null,
                role: '',
                photos: [],
              ),
              children: [],
            ),
      );
      return parentWithChildren.children;
    } catch (e) {
      debugPrint('Erreur getChildrenByUserId: $e');
      return [];
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection(
                'userModel',
              ) // ou la collection où sont stockés vos users
              .doc(userId)
              .get();

      if (userDoc.exists) {
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id,
        );
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération: $e');
      return null;
    }
  }

  ParentWithChildren? getParentWithChildrenById(String parentId) {
    try {
      return _parentsWithChildren.firstWhere(
        (parent) => parent.parent.id == parentId,
      );
    } catch (e) {
      return null;
    }
  }
}

class CourseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Course> _courses = [];
  bool _isLoading = false;

  List<Course> get courses => List.unmodifiable(_courses);
  bool get isLoading => _isLoading;

  CourseProvider() {
    _listenToCourses();
  }

  void _listenToCourses() {
    _firestore
        .collection('courses')
        .snapshots()
        .listen(
          (snapshot) {
            _courses =
                snapshot.docs
                    .map((doc) {
                      final data = doc.data();
                      if (data == null) {
                        debugPrint(
                          'Document data is null for course ID: ${doc.id}',
                        );
                        return null;
                      }
                      return Course.fromMap(data, doc.id);
                    })
                    .whereType<Course>()
                    .toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Erreur _listenToCourses: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }
}

class ProfProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Prof> _profs = [];
  bool _isLoading = false;

  List<Prof> get profs => List.unmodifiable(_profs);
  bool get isLoading => _isLoading;

  ProfProvider() {
    _listenToProfs();
  }

  void _listenToProfs() {
    _firestore
        .collection('profs')
        .snapshots()
        .listen(
          (snapshot) {
            _profs =
                snapshot.docs.map((doc) {
                  return Prof.fromMap(doc.data());
                }).toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Erreur _listenToProfs: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> addProf(Prof prof) async {
    try {
      await _firestore.collection('profs').doc(prof.id).set(prof.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur addProf: $e');
      rethrow;
    }
  }

  Future<void> updateProf(Prof prof) async {
    try {
      await _firestore.collection('profs').doc(prof.id).update(prof.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur updateProf: $e');
      rethrow;
    }
  }

  Future<void> deleteProf(String id) async {
    try {
      await _firestore.collection('profs').doc(id).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur deleteProf: $e');
      rethrow;
    }
  }

  Future<List<Prof>> getProfsByIds(List<String> profIds) async {
    if (profIds.isEmpty) return [];

    try {
      _isLoading = true;
      notifyListeners();

      // Utilisation du cache local si disponible
      final cachedProfs =
          _profs.where((prof) => profIds.contains(prof.id)).toList();
      if (cachedProfs.length == profIds.length) {
        return cachedProfs;
      }

      // Récupération depuis Firestore par lots (limite whereIn à 10)
      final profChunks = _chunkList(profIds, 10);
      final List<Prof> result = [];

      for (final chunk in profChunks) {
        final snapshot =
            await _firestore
                .collection('profs')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

        result.addAll(snapshot.docs.map((doc) => Prof.fromMap(doc.data())));
      }

      return result;
    } catch (e) {
      debugPrint('Erreur getProfsByIds: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  // Stream pour les profs
  Stream<List<Prof>> get profsStream {
    return _firestore
        .collection('profs')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Prof.fromMap(doc.data())).toList(),
        );
  }
}
