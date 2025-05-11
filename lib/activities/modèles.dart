import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> days;

  Schedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.days,
  });

  factory Schedule.fromMap(Map<String, dynamic> data) {
    return Schedule(
      id: data['id'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      days: List<String>.from(data['days'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'days': days,
    };
  }

  @override
  String toString() {
    return 'Schedule(id: $id, startTime: $startTime, endTime: $endTime, days: $days)';
  }
}

class Course {
  final String id;
  final String name;
  final Club club;
  final String description;
  final List<Schedule> schedules;
  final String ageRange;
  final List<String> profIds;

  Course({
    required this.id,
    required this.name,
    required this.club,
    required this.description,
    required this.schedules,
    required this.ageRange,
    required this.profIds,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'club': club.toMap(), // Ensure the club is converted to a map
      'clubId': club.id, // Include the club ID for reference
      'description': description,
      'schedules':
          schedules.map((s) => s.toMap()).toList(), // Convert schedules to maps
      'ageRange': ageRange,
      'profIds': profIds,
    };
  }

  factory Course.fromMap(Map<String, dynamic> data, String id) {
    return Course(
      id: id,
      name: data['name'] ?? 'Sans nom',
      club:
          data['club'] != null
              ? Club.fromMap(
                data['club'] as Map<String, dynamic>,
                data['clubId'],
              )
              : Club(
                id: 'unknown',
                name: 'Sans club',
                phone: '',
                logoUrl: '',
                photos: [],
                courses: [],
              ),
      description: data['description'] ?? 'Pas de description',
      schedules:
          (data['schedules'] as List<dynamic>?)
              ?.map((e) => Schedule.fromMap(e))
              .toList() ??
          [],
      ageRange: data['ageRange'] ?? 'Non spécifié',
      profIds: List<String>.from(data['profIds'] ?? []),
    );
  }

  @override
  String toString() {
    return 'Course(id: $id, name: $name, club: $club, profIds : $profIds,ageRange: $ageRange,)';
  }
}

class Club {
  final String id;
  final String name;
  final String phone; // Nouveau champ ajouté
  final String logoUrl;
  final List<String> photos;
  final List<Course> courses;

  Club({
    required this.id,
    required this.name,
    required this.phone, // Ajouté dans le constructeur
    required this.logoUrl,
    required this.photos,
    required this.courses,
  });

  factory Club.fromMap(Map<String, dynamic> data, String id) {
    return Club(
      id: id,
      name: data['name'] ?? 'Sans nom',
      phone: data['phone'] ?? '', // Valeur par défaut
      logoUrl: data['logoUrl'] ?? 'https://picsum.photos/200/300',
      photos: List<String>.from(data['photos'] ?? []),
      courses: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone, // Ajouté dans la sérialisation
      'logoUrl': logoUrl,
      'photos': photos,
      'courses': courses.map((e) => e.id).toList(),
    };
  }

  @override
  String toString() {
    return 'Club(id: $id, name: $name, phone: $phone, courses: ${courses.length})';
  }
}

class UserModel {
  final String id;
  final String name;
  final List<String> photos;
  final String phone;
  final String email;
  final String gender;
  final List<String> childrenIds;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? editedAt;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.photos,
    required this.phone,
    required this.email,
    required this.gender,
    required this.childrenIds,
    required this.createdAt,
    required this.lastLogin,
    required this.editedAt,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      childrenIds: List<String>.from(data['childrenIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      role: data['role'] ?? 'parent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'logoUrl': photos,
      'email': email,
      'gender': gender,
      'childrenIds': childrenIds,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'editedAt': editedAt,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, phone: $phone,photos: $photos email: $email, gender: $gender, role: $role, children: ${childrenIds.length})';
  }
}

class ParentWithChildren {
  final UserModel parent;
  final List<Child> children;

  ParentWithChildren({required this.parent, required this.children});

  @override
  String toString() {
    return 'ParentWithChildren(parent: $parent, children: ${children.length})';
  }
}

class Child {
  final String id;
  final String name;
  final String gender;
  final int age;
  final List<String> enrolledCourses;
  final String parentId;

  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.enrolledCourses,
    required this.parentId,
  });

  factory Child.fromMap(Map<String, dynamic> data, String id) {
    return Child(
      id: id,
      name: data['name'] ?? 'Sans nom',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      enrolledCourses: List<String>.from(data['enrolledCourses'] ?? []),
      parentId: data['parentId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'enrolledCourses': enrolledCourses,
      'parentId': parentId,
    };
  }

  @override
  String toString() {
    return 'Child(id: $id, name: $name, age: $age,gender:$gender, courses: ${enrolledCourses.length})';
  }
}

class Prof {
  final String id;
  final String name;
  final String email;
  final String phone;

  Prof({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Prof.fromMap(Map<String, dynamic> map) {
    return Prof(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'phone': phone};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prof && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ImageItem {
  final File? file;
  final String? url;

  ImageItem({this.file, this.url});
}

const lesRoles = [
  'club',
  'association',
  'ecole',
  'parent',
  'professeur',
  'coach',
  'animateur',
  'formateur',
  'moniteur',
  'intervenant extérieur',
  'médiateur',
  'tuteur',
  'grand-parent',
  'oncle/tante',
  'frère/sœur',
  'famille d’accueil',
  'éducateur',
  'enseignant suppléant',
  'conseiller pédagogique',
  'autre',
];
