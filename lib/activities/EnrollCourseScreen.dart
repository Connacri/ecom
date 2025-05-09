import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'modèles.dart';

class EnrollCourseScreen extends StatefulWidget {
  final Child child;

  EnrollCourseScreen({required this.child});

  @override
  _EnrollCourseScreenState createState() => _EnrollCourseScreenState();
}

class _EnrollCourseScreenState extends State<EnrollCourseScreen> {
  List<Course> availableCourses = [];

  @override
  void initState() {
    super.initState();
    fetchAvailableCourses();
  }

  Future<void> fetchAvailableCourses() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('courses').get();
    List<Course> courses =
        snapshot.docs.map((doc) {
          List<Schedule> schedules =
              (doc['schedules'] as List).map((scheduleData) {
                return Schedule(
                  id: scheduleData['id'],
                  startTime: (scheduleData['startTime'] as Timestamp).toDate(),
                  endTime: (scheduleData['endTime'] as Timestamp).toDate(),
                  days: List<String>.from(scheduleData['days']),
                );
              }).toList();
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return Course(
            id: doc.id,
            name: data['name'],
            club: data['club'],
            description: data['description'],
            schedules: schedules,
            ageRange:
                data.containsKey('ageRange')
                    ? data['ageRange']
                    : 'Non spécifié',
            profIds: [],
          );
        }).toList();

    setState(() {
      availableCourses = courses;
    });
  }

  void enrollCourse(Course course) {
    setState(() {
      widget.child.enrolledCourses.add(course.id);
    });
    FirebaseFirestore.instance
        .collection('children')
        .doc(widget.child.id)
        .update({'enrolledCourses': widget.child.enrolledCourses});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription aux Cours pour ${widget.child.name}'),
      ),
      body: ListView.builder(
        itemCount: availableCourses.length,
        itemBuilder: (context, index) {
          Course course = availableCourses[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text(
              '${course.club} - ${course.description} - ${course.ageRange}',
            ),
            onTap: () {
              enrollCourse(course);
            },
          );
        },
      ),
    );
  }
}
