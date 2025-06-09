import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> days;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Schedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.days,
    this.createdAt,
    this.editedAt,
  });

  // Added proper null checks and type safety
  factory Schedule.fromMap(Map<String, dynamic> data) {
    return Schedule(
      id: data['id'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      days: List<String>.from(data['days'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'days': days,
      'createdAt': createdAt,
      'editedAt': editedAt,
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
  final String clubId;
  final String description;
  final List<String>? photos;
  final List<Schedule> schedules;
  final String ageRange;
  final List<String> profIds;
  final DateTime? createdAt;
  final DateTime? saisonStart;
  final DateTime? saisonEnd;
  final DateTime? editedAt;
  final int? placeNumber;
  final GeoPoint? location;

  /// Nouveau champ : prix en fonction du type de cotisation
  final Map<String, double>? pricesByCotisationType;

  final String? cotisationType;

  Course({
    required this.id,
    required this.name,
    required this.clubId,
    this.photos,
    required this.description,
    required this.schedules,
    required this.ageRange,
    required this.profIds,
    this.createdAt,
    this.saisonStart,
    this.saisonEnd,
    this.editedAt,
    this.placeNumber,
    this.location,
    this.pricesByCotisationType,
    this.cotisationType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'placeNumber': placeNumber,
      'clubId': clubId,
      'description': description,
      'schedules': schedules.map((s) => s.toMap()).toList(),
      'ageRange': ageRange,
      'location': location,
      'pricesByCotisationType': pricesByCotisationType,
      'profIds': profIds,
      'createdAt': createdAt,
      'photos': photos,
      'editedAt': editedAt,
      'saisonStart': saisonStart,
      'saisonEnd': saisonEnd,
      'cotisationType': cotisationType,
    };
  }

  factory Course.fromMap(Map<String, dynamic> data, String id) {
    return Course(
      id: id,
      name: data['name'] ?? 'Sans nom',
      clubId: data['clubId'] ?? '',
      description: data['description'] ?? 'Pas de description',
      schedules:
          (data['schedules'] as List<dynamic>?)
              ?.map((e) => Schedule.fromMap(e))
              .toList() ??
          [],
      location:
          data['location'] is GeoPoint ? data['location'] as GeoPoint : null,
      pricesByCotisationType: Map<String, double>.from(
        data['pricesByCotisationType'] ?? {},
      ),
      placeNumber: data['placeNumber'] ?? 0,
      saisonEnd: (data['saisonEnd'] as Timestamp?)?.toDate(),
      saisonStart: (data['saisonStart'] as Timestamp?)?.toDate(),
      photos: List<String>.from(data['photos'] ?? []),
      ageRange: data['ageRange'] ?? 'Non spécifié',
      profIds: List<String>.from(data['profIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      cotisationType: data['cotisationType'] ?? 'unknown',
    );
  }

  double? getPrice(String type) {
    return pricesByCotisationType?[type];
  }

  @override
  String toString() {
    return 'Course(id: $id, name: $name, club: $clubId, profIds : $profIds, ageRange: $ageRange,)';
  }
}

class UserModel {
  final String id;
  final String name;
  List<String>? photos;
  final String? phone;
  final String email;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? editedAt;
  final String role;
  String? logoUrl;
  final List<Course>? courses;
  final bool? dispo;
  final DateTime? congeStart;
  final DateTime? congeEnd;

  UserModel({
    required this.id,
    required this.name,
    this.photos,
    this.phone,
    required this.email,
    this.gender,
    this.courses,
    this.logoUrl,
    required this.createdAt,
    required this.lastLogin,
    required this.editedAt,
    required this.role,
    this.dispo,
    this.congeEnd,
    this.congeStart,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      logoUrl: data['logoUrl'] ?? 'https://picsum.photos/200/300',
      photos: List<String>.from(data['photos'] ?? []),
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      courses: [],
      dispo: data['dispo'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      role: data['role'] ?? '',
      congeEnd: (data['congeEnd'] as Timestamp?)?.toDate(),
      congeStart: (data['congeStart'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'photos': photos,
      'email': email,
      'gender': gender,
      'logoUrl': logoUrl,
      'courses': (courses ?? []).map((e) => e.id).toList(),
      'createdAt': createdAt,
      'dispo': dispo,
      'congeStart': congeStart,
      'congeEnd': congeEnd,
      'lastLogin': lastLogin,
      'editedAt': editedAt,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, phone: $phone,photos: $photos email: $email, gender: $gender, role: $role, ';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Child {
  final String id;
  final String name;
  final String gender;
  final int age;
  final List<String> enrolledCourses;
  final String parentId;
  final DateTime? createdAt;

  final DateTime? editedAt;

  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.enrolledCourses,
    required this.parentId,
    this.createdAt,

    this.editedAt,
  });

  factory Child.fromMap(Map<String, dynamic> data, String id) {
    return Child(
      id: id,
      name: data['name'] ?? 'Sans nom',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      enrolledCourses: List<String>.from(data['enrolledCourses'] ?? []),
      parentId: data['parentId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),

      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'enrolledCourses': enrolledCourses,
      'parentId': parentId,
      'createdAt': createdAt,

      'editedAt': editedAt,
    };
  }

  @override
  String toString() {
    return 'Child(id: $id, name: $name, age: $age,gender:$gender, courses: ${enrolledCourses.length})';
  }
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

// class Prof {
//   final String id;
//   final List<String> photos;
//   final String name;
//   final String email;
//   final String phone;
//   final DateTime? createdAt;
//   final DateTime? editedAt;
//
//   Prof({
//     required this.id,
//     required this.name,
//     required this.photos,
//     required this.email,
//     required this.phone,
//     this.createdAt,
//     this.editedAt,
//   });
//
//   factory Prof.fromMap(Map<String, dynamic> map) {
//     return Prof(
//       id: map['id'] ?? '',
//       name: map['name'] ?? '',
//       photos: List<String>.from(map['photos'] ?? []),
//       email: map['email'] ?? '',
//       phone: map['phone'] ?? '',
//       createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
//       editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'photos': photos,
//       'email': email,
//       'phone': phone,
//       'createdAt': createdAt,
//       'editedAt': editedAt,
//     };
//   }
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is Prof && runtimeType == other.runtimeType && id == other.id;
//
//   @override
//   int get hashCode => id.hashCode;
// }

// class Club {
//   final String id;
//   final String name;
//   final String phone; // Nouveau champ ajouté
//   final String logoUrl;
//   final List<String> photos;
//   final List<Course> courses;
//   final DateTime? createdAt;
//   final DateTime? lastLogin;
//   final DateTime? editedAt;
//
//   Club({
//     required this.id,
//     required this.name,
//     required this.phone,
//     required this.logoUrl,
//     required this.photos,
//     required this.courses,
//     this.createdAt,
//     this.lastLogin,
//     this.editedAt,
//   });
//
//   factory Club.fromMap(Map<String, dynamic> data, String id) {
//     return Club(
//       id: id,
//       name: data['name'] ?? 'Sans nom',
//       phone: data['phone'] ?? '', // Valeur par défaut
//       logoUrl: data['logoUrl'] ?? 'https://picsum.photos/200/300',
//       photos: List<String>.from(data['photos'] ?? []),
//       courses: [],
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
//       lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
//       editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'phone': phone, // Ajouté dans la sérialisation
//       'logoUrl': logoUrl,
//       'photos': photos,
//       'courses': courses.map((e) => e.id).toList(), 'createdAt': createdAt,
//       'lastLogin': lastLogin,
//       'editedAt': editedAt,
//     };
//   }
//
//   @override
//   String toString() {
//     return 'Club(id: $id, name: $name, phone: $phone, courses: ${courses.length})';
//   }
// }
