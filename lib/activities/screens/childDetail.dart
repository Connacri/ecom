import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modèles.dart';

class ChildDetailScreen extends StatefulWidget {
  final Child child;

  const ChildDetailScreen({Key? key, required this.child}) : super(key: key);

  @override
  _ChildDetailScreenState createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadChildCourses();
  }

  Future<List<Course>> _loadChildCourses() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('courses')
            .where('enrolledChildren', arrayContains: widget.child.id)
            .get();

    return snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.child.name),
              background: Hero(
                tag: 'child-${widget.child.id}',
                child: Image.network(
                  'https://picsum.photos/seed/${widget.child.id}/600/400',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            pinned: true,
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Âge: ${widget.child.age}'),
                  Text('Genre: ${widget.child.gender}'),
                  SizedBox(height: 16),
                  Text(
                    'Emploi du temps',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Course>>(
            future: _coursesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(child: Text('Aucun cours inscrit')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final course = snapshot.data![index];
                  return _buildScheduleCard(course);
                }, childCount: snapshot.data!.length),
              );
            },
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => AddCourseScreen(club: club),
      //     ),
      //   ),
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Widget _buildScheduleCard(Course course) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.name, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...course.schedules
                .map(
                  (schedule) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_formatDayRange(schedule.days)}'),
                      Text(
                        '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                      ),
                      Divider(),
                    ],
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  String _formatDayRange(List<String> days) {
    return days.join(', ');
  }

  String _formatTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }
}
