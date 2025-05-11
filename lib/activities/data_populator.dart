import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'modèles.dart';

final faker = Faker();
final uuid = Uuid();

class DataPopulator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference clubs;
  final CollectionReference children;
  final CollectionReference users;
  final CollectionReference courses;
  final CollectionReference profs;

  DataPopulator()
    : clubs = FirebaseFirestore.instance.collection('clubs'),
      children = FirebaseFirestore.instance.collection('children'),
      users = FirebaseFirestore.instance.collection('userModel'),
      courses = FirebaseFirestore.instance.collection('courses'),
      profs = FirebaseFirestore.instance.collection('profs');

  // Données de référence
  static const List<String> sampleDays = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  static const List<String> sports = [
    "Football",
    "Basketball",
    "Natation",
    "Gymnastique",
    "Tennis",
    "Danse",
    "Judo",
    "Athlétisme",
  ];

  Future<void> populateData() async {
    print("🌱 Démarrage du peuplement des données...");

    final List<Prof> allProfs = await _generateProfs(8); // 👈 Génération ici
    final List<String> childIds = await _generateChildren(23);
    await _generateParents(12, childIds);
    await _generateClubsAndCourses(4, allProfs);

    print("✅ Peuplement terminé avec succès !");
  }

  Future<List<Prof>> _generateProfs(int count) async {
    print("👨‍🏫 Génération de $count professeurs...");
    final List<Prof> generatedProfs = [];

    for (int i = 0; i < count; i++) {
      final id = uuid.v4();
      final name = "${faker.person.firstName()} ${faker.person.lastName()}";
      final email = faker.internet.email();
      final phone = faker.phoneNumber.us();

      final prof = Prof(id: id, name: name, email: email, phone: phone);

      await profs.doc(id).set(prof.toMap());
      generatedProfs.add(prof);
    }

    return generatedProfs;
  }

  // In the _generateClubsAndCourses method, the issue is in how _generateRandomCourse is called
  // Here's the corrected version of this part:

  Future<void> _generateClubsAndCourses(
    int clubCount,
    List<Prof> allProfs,
  ) async {
    print("🏟️ Génération de $clubCount clubs et leurs cours...");

    for (int i = 1; i <= clubCount; i++) {
      final clubId = uuid.v4();
      final name = "Club ${faker.company.name()}";
      final phone = faker.phoneNumber.toString();
      final logoUrl = "https://picsum.photos/seed/$clubId/200/300";
      final photos = List<String>.generate(
        faker.randomGenerator.integer(4, min: 2),
        (index) => "https://picsum.photos/seed/${clubId}_$index/400/300",
      );

      // Create the club first
      final club = Club(
        id: clubId,
        name: name,
        logoUrl: logoUrl,
        photos: photos,
        courses: [],
        phone: phone, // Start with empty courses list
      );

      final courseCount = faker.randomGenerator.integer(4, min: 2);
      final List<Course> clubCourses = [];
      final List<String> courseIds = [];

      // Now generate courses with the club reference
      for (int j = 0; j < courseCount; j++) {
        // Pass both required arguments: profPool and club
        final course = _generateRandomCourse(allProfs, club);
        clubCourses.add(course);
        courseIds.add(course.id);
        await courses.doc(course.id).set(course.toMap());
      }

      // Update the club with the courses
      club.courses.addAll(clubCourses);
      await clubs.doc(clubId).set(club.toMap());
      await _assignChildrenToCourses(clubCourses);
    }
  }

  Course _generateRandomCourse(List<Prof> profPool, Club club) {
    final courseId = uuid.v4();
    final sport = faker.randomGenerator.element(sports);
    final courseName = "${faker.lorem.word().capitalize()} $sport";
    final description = faker.lorem.sentences(3).join(' ');
    final ageMin = faker.randomGenerator.integer(10, min: 3);
    final ageMax = ageMin + faker.randomGenerator.integer(6, min: 1);
    final ageRange = "$ageMin-$ageMax ans";

    final scheduleCount = faker.randomGenerator.integer(3, min: 1);
    final List<Schedule> schedules = [];

    for (int k = 0; k < scheduleCount; k++) {
      final hourStart = faker.randomGenerator.integer(18, min: 9);
      final duration = faker.randomGenerator.integer(2, min: 1) + 0.5;

      final availableDays = List<String>.from(sampleDays)..shuffle();
      final daysCount = faker.randomGenerator.integer(3, min: 1);
      final days = availableDays.take(daysCount).toList();

      schedules.add(
        Schedule(
          id: uuid.v4(),
          startTime: DateTime(2025, 1, 1, hourStart, 0),
          endTime: DateTime(
            2025,
            1,
            1,
            hourStart + duration.toInt(),
            ((duration % 1) * 60).toInt(),
          ),
          days: days,
        ),
      );
    }

    final profCount = faker.randomGenerator.integer(2, min: 1);
    final List<String> profIds =
        (List<Prof>.from(profPool)
          ..shuffle()).take(profCount).map((e) => e.id).toList();

    return Course(
      id: courseId,
      name: courseName,
      club: club,
      description: description,
      schedules: schedules,
      ageRange: ageRange,
      profIds: profIds,
    );
  }

  Future<void> _generateParents(int count, List<String> childIds) async {
    print("👨‍👩‍👧‍👦 Génération de $count parents...");
    final shuffledChildIds = List<String>.from(childIds)..shuffle();

    for (int i = 1; i <= count; i++) {
      if (shuffledChildIds.isEmpty) break;

      final parentId = uuid.v4();
      final name = "${faker.person.firstName()} ${faker.person.lastName()}";
      final email = faker.internet.email();
      final childrenPerParent = min(
        faker.randomGenerator.integer(3, min: 1),
        shuffledChildIds.length,
      );

      final randomRole = (lesRoles.toList()..shuffle()).first;
      final parentChildren = shuffledChildIds.take(childrenPerParent).toList();
      final gender = Random().nextBool() ? 'male' : 'female';
      final role = Random().nextBool() ? 'male' : 'female';
      final phone = faker.phoneNumber.random.toString();
      shuffledChildIds.removeRange(0, childrenPerParent);

      final batch = _firestore.batch();
      for (final childId in parentChildren) {
        batch.update(children.doc(childId), {'parentId': parentId});
      }
      await batch.commit();

      final parent = UserModel(
        id: parentId,
        name: name,
        email: email,
        childrenIds: parentChildren,
        gender: gender,
        phone: phone,
        createdAt: faker.date.dateTime(minYear: 2024, maxYear: 2024),
        lastLogin: DateTime.now(),
        editedAt: faker.date.dateTime(minYear: 2025, maxYear: 2025),
        role: randomRole,
        photos: [],
      );

      await users.doc(parentId).set(parent.toMap());
    }
  }

  // Future<List<String>> _generateChildren(int count) async {
  //   print("👶 Génération de $count enfants...");
  //   final List<String> childIds = [];
  //
  //   for (int i = 1; i <= count; i++) {
  //     final childId = uuid.v4();
  //     final name = "${faker.person.firstName()} ${faker.person.lastName()}";
  //     final age = faker.randomGenerator.integer(13, min: 3); // 3-16 ans
  //     final gender = Random().nextBool() ? 'male' : 'female';
  //
  //     final child = Child(
  //       id: childId,
  //       name: name,
  //       age: age,
  //       enrolledCourses: [],
  //       parentId: '',
  //       gender: gender,
  //     );
  //
  //     await children.doc(childId).set(child.toMap());
  //     childIds.add(childId);
  //   }
  //
  //   return childIds;
  // }
  Future<List<String>> _generateChildren(int count) async {
    print("👶 Génération de $count enfants...");
    final List<String> childIds = [];

    for (int i = 1; i <= count; i++) {
      final childId = uuid.v4();
      final name = "${faker.person.firstName()} ${faker.person.lastName()}";
      final age = faker.randomGenerator.integer(
        13,
        min: 4,
      ); // entre 4 et 13 ans
      final gender = Random().nextBool() ? 'male' : 'female';

      final child = Child(
        id: childId,
        name: name,
        age: age,
        enrolledCourses: [],
        parentId: '',
        gender: gender,
      );

      await children.doc(childId).set(child.toMap());
      childIds.add(childId);
    }

    return childIds;
  }

  Future<void> _assignChildrenToCourses(List<Course> courses) async {
    final snapshot = await children.get();
    final batch = _firestore.batch();

    for (final childDoc in snapshot.docs) {
      final childData = childDoc.data() as Map<String, dynamic>;
      final age = childData['age'] as int;
      final childId = childDoc.id;

      final suitableCourses =
          courses.where((course) {
            final ageParts = course.ageRange.split('-');
            final minAge = int.parse(ageParts[0]);
            final maxAge = int.parse(ageParts[1].split(' ')[0]);
            return age >= minAge && age <= maxAge;
          }).toList();

      if (suitableCourses.isNotEmpty) {
        final count = min(
          faker.randomGenerator.integer(2, min: 1),
          suitableCourses.length,
        );

        suitableCourses.shuffle();
        final enrolledCourses =
            suitableCourses.take(count).map((e) => e.id).toList();

        batch.update(children.doc(childId), {
          'enrolledCourses': enrolledCourses,
        });
      }
    }

    await batch.commit();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class DataPopulatorClaude {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference clubs;
  final CollectionReference parents;
  final CollectionReference courses;
  final CollectionReference profs;

  DataPopulatorClaude()
    : clubs = FirebaseFirestore.instance.collection('clubs'),
      parents = FirebaseFirestore.instance.collection('userModel'),
      courses = FirebaseFirestore.instance.collection('courses'),
      profs = FirebaseFirestore.instance.collection('profs');

  // Données de référence
  static const List<String> sampleDays = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  static const List<String> sports = [
    "Football",
    "Basketball",
    "Natation",
    "Gymnastique",
    "Tennis",
    "Danse",
    "Judo",
    "Athlétisme",
  ];

  Future<void> populateData() async {
    print("🌱 Démarrage du peuplement des données...");

    final List<Prof> allProfs = await _generateProfs(8);
    final List<Club> allClubs = await _generateClubs(4);
    final List<Course> allCourses = await _generateCourses(allClubs, allProfs);
    await _generateParents(12); // Génère les parents et leurs enfants
    await _assignChildrenToCourses(allCourses);

    print("✅ Peuplement terminé avec succès !");
  }

  Future<List<Prof>> _generateProfs(int count) async {
    print("👨‍🏫 Génération de $count professeurs...");
    final List<Prof> generatedProfs = [];

    for (int i = 0; i < count; i++) {
      final id = uuid.v4();
      final name = "${faker.person.firstName()} ${faker.person.lastName()}";
      final email = faker.internet.email();
      final phone = faker.phoneNumber.us();

      final prof = Prof(id: id, name: name, email: email, phone: phone);

      await profs.doc(id).set(prof.toMap());
      generatedProfs.add(prof);
    }

    return generatedProfs;
  }

  Future<List<Club>> _generateClubs(int clubCount) async {
    print("🏟️ Génération de $clubCount clubs...");
    final List<Club> generatedClubs = [];

    for (int i = 1; i <= clubCount; i++) {
      final clubId = uuid.v4();
      final name = "Club ${faker.company.name()}";
      final phone = faker.phoneNumber.us();
      final logoUrl = "https://picsum.photos/seed/$clubId/200/300";
      final photos = List<String>.generate(
        faker.randomGenerator.integer(4, min: 2),
        (index) => "https://picsum.photos/seed/${clubId}_$index/400/300",
      );

      final club = Club(
        id: clubId,
        name: name,
        logoUrl: logoUrl,
        photos: photos,
        courses: [],
        phone: phone,
      );

      await clubs.doc(clubId).set(club.toMap());
      generatedClubs.add(club);
    }

    return generatedClubs;
  }

  Future<List<Course>> _generateCourses(
    List<Club> allClubs,
    List<Prof> allProfs,
  ) async {
    print("📚 Génération des cours pour ${allClubs.length} clubs...");
    final List<Course> allCourses = [];

    for (final club in allClubs) {
      final courseCount = faker.randomGenerator.integer(5, min: 2);
      final List<String> courseIds = [];

      for (int j = 0; j < courseCount; j++) {
        final course = await _generateRandomCourse(allProfs, club);
        allCourses.add(course);
        courseIds.add(course.id);
      }

      await clubs.doc(club.id).update({'courses': courseIds});
    }

    return allCourses;
  }

  Future<Course> _generateRandomCourse(List<Prof> profPool, Club club) async {
    final courseId = uuid.v4();
    final sport = faker.randomGenerator.element(sports);
    final courseName = "${faker.lorem.word().capitalize()} $sport";
    final description = faker.lorem.sentences(3).join(' ');
    final ageMin = faker.randomGenerator.integer(10, min: 3);
    final ageMax = ageMin + faker.randomGenerator.integer(6, min: 1);
    final ageRange = "$ageMin-$ageMax ans";

    final scheduleCount = faker.randomGenerator.integer(3, min: 1);
    final List<Schedule> schedules = [];

    for (int k = 0; k < scheduleCount; k++) {
      final hourStart = faker.randomGenerator.integer(18, min: 9);
      final duration = faker.randomGenerator.integer(2, min: 1) + 0.5;

      final availableDays = List<String>.from(sampleDays)..shuffle();
      final daysCount = faker.randomGenerator.integer(3, min: 1);
      final days = availableDays.take(daysCount).toList();

      schedules.add(
        Schedule(
          id: uuid.v4(),
          startTime: DateTime(2025, 1, 1, hourStart, 0),
          endTime: DateTime(
            2025,
            1,
            1,
            hourStart + duration.toInt(),
            ((duration % 1) * 60).toInt(),
          ),
          days: days,
        ),
      );
    }

    final profCount = faker.randomGenerator.integer(3, min: 1);
    final List<String> profIds =
        (List<Prof>.from(profPool)
          ..shuffle()).take(profCount).map((e) => e.id).toList();

    final course = Course(
      id: courseId,
      name: courseName,
      club: club,
      description: description,
      schedules: schedules,
      ageRange: ageRange,
      profIds: profIds,
    );

    await courses.doc(courseId).set(course.toMap());
    return course;
  }

  Future<void> _generateParents(int count) async {
    print("👨‍👩‍👧‍👦 Génération de $count parents...");

    for (int i = 1; i <= count; i++) {
      final parentId = uuid.v4();
      final name = "${faker.person.firstName()} ${faker.person.lastName()}";
      final email = faker.internet.email();
      final childrenCount = faker.randomGenerator.integer(3, min: 1);
      final gender = Random().nextBool() ? 'male' : 'female';
      final phone = faker.phoneNumber.us();
      final randomRole = _getRandomRole();

      // Générer les enfants pour ce parent (sous-collection)
      final List<String> childrenIds = [];
      for (int j = 0; j < childrenCount; j++) {
        final childId = uuid.v4();
        final childName =
            "${faker.person.firstName()} ${faker.person.lastName()}";
        final age = faker.randomGenerator.integer(13, min: 3);
        final childGender = Random().nextBool() ? 'male' : 'female';

        final child = Child(
          id: childId,
          name: childName,
          age: age,
          enrolledCourses: [],
          gender: childGender,
          parentId: parentId,
        );

        // Ajouter l'enfant à la sous-collection du parent
        await parents
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set(child.toMap());
        childrenIds.add(childId);
      }

      // Créer le parent avec la liste des IDs des enfants
      final parent = UserModel(
        id: parentId,
        name: name,
        email: email,
        childrenIds: childrenIds,
        gender: gender,
        phone: phone,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        editedAt: DateTime.now(),
        role: randomRole,
        photos: [],
      );

      await parents.doc(parentId).set(parent.toMap());
    }
  }

  String _getRandomRole() {
    return (List<String>.from(lesRoles)..shuffle()).first;
  }

  Future<void> _assignChildrenToCourses(List<Course> courses) async {
    print("🔄 Attribution des cours aux enfants...");

    final parentsSnapshot = await parents.get();

    for (final parentDoc in parentsSnapshot.docs) {
      final childrenSnapshot =
          await parentDoc.reference.collection('children').get();

      for (final childDoc in childrenSnapshot.docs) {
        final childData = childDoc.data();
        final age = childData['age'] as int;

        // Trouver les cours appropriés
        final suitableCourses =
            courses.where((course) {
              final ageParts = course.ageRange.split('-');
              final minAge = int.parse(ageParts[0]);
              final maxAge = int.parse(ageParts[1].split(' ')[0]);
              return age >= minAge && age <= maxAge;
            }).toList();

        if (suitableCourses.isNotEmpty) {
          final count = min(
            faker.randomGenerator.integer(2, min: 1),
            suitableCourses.length,
          );
          suitableCourses.shuffle();
          final enrolledCourses =
              suitableCourses.take(count).map((e) => e.id).toList();

          // Mettre à jour l'enfant avec les cours
          await parentDoc.reference
              .collection('children')
              .doc(childDoc.id)
              .update({'enrolledCourses': enrolledCourses});
        }
      }
    }
  }

  bool _schedulesOverlap(Schedule a, Schedule b) {
    // Check if schedules occur on the same day
    bool sameDays = a.days.any((day) => b.days.contains(day));
    if (!sameDays) return false;

    // Check if time periods overlap
    final aStart = a.startTime.hour * 60 + a.startTime.minute;
    final aEnd = a.endTime.hour * 60 + a.endTime.minute;
    final bStart = b.startTime.hour * 60 + b.startTime.minute;
    final bEnd = b.endTime.hour * 60 + b.endTime.minute;

    return (aStart < bEnd && aEnd > bStart);
  }
}

class ClearDatabaseButton extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of collections to clear
  final List<String> collectionsToClear = [
    'courses',
    'clubs',
    'children',
    'parents',
    'profs',
  ];

  // Future<void> _clearDatabase() async {
  //   try {
  //     for (final collectionName in collectionsToClear) {
  //       final collectionRef = _firestore.collection(collectionName);
  //       final snapshot = await collectionRef.get();
  //
  //       // Delete each document
  //       for (final doc in snapshot.docs) {
  //         await doc.reference.delete();
  //       }
  //     }
  //
  //     print('Specified collections cleared successfully.');
  //   } catch (e) {
  //     print('Error clearing database: $e');
  //   }
  // }
  Future<void> _clearDatabase() async {
    try {
      // Supprimer les parents et leurs sous-collections
      final parentsSnapshot = await _firestore.collection('parents').get();
      for (final doc in parentsSnapshot.docs) {
        // Supprimer les enfants (sous-collection)
        final childrenSnapshot =
            await doc.reference.collection('children').get();
        for (final childDoc in childrenSnapshot.docs) {
          await childDoc.reference.delete();
        }
        // Supprimer le parent
        await doc.reference.delete();
      }

      // Supprimer les autres collections
      final otherCollections = ['courses', 'clubs', 'profs'];
      for (final collectionName in otherCollections) {
        final snapshot = await _firestore.collection(collectionName).get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }

      print('Database cleared successfully.');
    } catch (e) {
      print('Error clearing database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        bool confirm = await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirm'),
                content: Text(
                  'Are you sure you want to clear the specified collections?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Confirm'),
                  ),
                ],
              ),
        );

        if (confirm == true) {
          await _clearDatabase();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Specified collections cleared successfully.'),
            ),
          );
        }
      },
      icon: Icon(Icons.delete_sweep, color: Colors.red),
    );
  }
}
