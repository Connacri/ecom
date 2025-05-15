import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../activities/modèles.dart';
import '../auth_service.dart';

class HomeParentPage extends StatefulWidget {
  final UserModel user;

  const HomeParentPage({Key? key, required this.user}) : super(key: key);
  @override
  State<HomeParentPage> createState() => _HomeParentPageState();
}

class _HomeParentPageState extends State<HomeParentPage> {
  final _childCol = FirebaseFirestore.instance.collection('children');
  final _courseCol = FirebaseFirestore.instance.collection('courses');
  List<Child> _myChildren = [];
  Map<String, List<Course>> _enrolledCourses = {};
  bool _loading = true;
  bool isSigningOut = false;
  bool isLoading = false;

  Future<void> _fetchData() async {
    final uid = widget.user.id;
    final childSnap = await _childCol.where('parentId', isEqualTo: uid).get();
    _myChildren =
        childSnap.docs.map((d) => Child.fromMap(d.data(), d.id)).toList();

    for (var child in _myChildren) {
      final q =
          await _courseCol.where('id', whereIn: child.enrolledCourses).get();
      _enrolledCourses[child.id] =
          q.docs.map((d) => Course.fromMap(d.data(), d.id)).toList();
    }
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext ctx) {
    final auth = Provider.of<AuthService>(ctx, listen: false);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Parent')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Parent'),
        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : () async {
                      await auth.signOut();
                    },
            icon:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _myChildren.length,
        itemBuilder: (_, i) {
          final child = _myChildren[i];
          final courses = _enrolledCourses[child.id] ?? [];
          return ExpansionTile(
            title: Text(child.name),
            subtitle: Text('Cours inscrits: ${courses.length}'),
            children:
                courses
                    .map(
                      (c) => ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.description),
                        onTap: () {},
                      ),
                    )
                    .toList(),
          );
        },
      ),
    );
  }
}
