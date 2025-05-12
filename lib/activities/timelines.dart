// import 'package:ecom/activities/providers.dart';
// import 'package:flutter/material.dart';
//
// import 'modèles.dart';
//
// class TimelineScreen extends StatelessWidget {
//   TimelineScreen({
//     Key? key,
//     required this.children,
//     required this.courses,
//
//   }) : super(key: key);
//
//   final List<Child> children;
//   final List<Course> courses;
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Children Timeline')),
//       body: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Column(
//           children: [
//             // Header row
//             Row(
//               children: [
//                 Container(width: 80, child: Text('Time')),
//                 ...children.map(
//                   (child) => Container(width: 150, child: Text(child.name)),
//                 ),
//               ],
//             ),
//             // Time slots
//             ...List.generate(12, (hourIndex) {
//               final hour = 8 + hourIndex;
//               return Row(
//                 children: [
//                   Container(width: 80, child: Text('$hour:00')),
//                   ...children.map((child) {
//                     final childCourses =
//                         courses
//                             .where((c) => child.enrolledCourses.contains(c.id))
//                             .toList();
//                     Schedule? foundSchedule;
//                     Course? foundCourse;
//
//                     for (final course in childCourses) {
//                       for (final schedule in course.schedules) {
//                         if (schedule.startTime.hour <= hour &&
//                             schedule.endTime.hour > hour) {
//                           foundSchedule = schedule;
//                           foundCourse = course;
//                           break;
//                         }
//                       }
//                       if (foundSchedule != null) break;
//                     }
//
//                     if (foundSchedule != null &&
//                         foundSchedule.startTime.hour == hour) {
//                       final duration =
//                           foundSchedule.endTime.hour -
//                           foundSchedule.startTime.hour;
//
//                       return FutureBuilder<List<Prof>>(
//                         future: profProvider.getProfsByIds(
//                           foundCourse!.profIds,
//                         ),
//                         builder: (context, snapshot) {
//                           final profs = snapshot.data ?? [];
//                           final prof =
//                               profs.isNotEmpty
//                                   ? profs.first
//                                   : Prof(
//                                     id: 'unknown',
//                                     name: 'Prof inconnu',
//                                     email: '',
//                                     phone: '', photos: [],
//                                   );
//
//                           return Container(
//                             width: 150,
//                             height: 50.0 * duration,
//                             color: Colors.blue,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(foundCourse!.name),
//                                 Text(prof.name),
//                               ],
//                             ),
//                           );
//                         },
//                       );
//                     } else if (foundSchedule != null &&
//                         foundSchedule.startTime.hour < hour) {
//                       return Container(width: 0, height: 0);
//                     } else {
//                       return Container(
//                         width: 150,
//                         height: 50,
//                         color: Colors.grey[200],
//                       );
//                     }
//                   }),
//                 ],
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }
// }
