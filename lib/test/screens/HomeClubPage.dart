import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../activities/modèles.dart';
import '../widgets.dart';

class HomeClubPage extends StatefulWidget {
  const HomeClubPage({super.key});
  @override
  State<HomeClubPage> createState() => _HomeClubPageState();
}

class _HomeClubPageState extends State<HomeClubPage> {
  final _col = FirebaseFirestore.instance.collection('courses');
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  final List<Course> _items = [];

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    Query q = _col.orderBy('createdAt').limit(10);
    if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
    final snap = await q.get();
    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      for (var d in snap.docs) {
        _items.add(Course.fromMap(d.data() as Map<String, dynamic>, d.id));
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours du club'),
        actions: [iconLogout()],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notif) {
          if (notif.metrics.pixels >= notif.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: _items.length + (_hasMore ? 1 : 0),
          itemBuilder: (c, i) {
            if (i == _items.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final course = _items[i];
            return ListTile(
              title: Text(course.name),
              subtitle: Text(course.description),
              onTap: () {
                // CRUD en temps réel : open détails, etc.
              },
            );
          },
        ),
      ),
    );
  }
}
