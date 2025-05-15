import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/test/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../activities/modèles.dart';

class HomeProfPage extends StatefulWidget {
  final UserModel user;

  const HomeProfPage({Key? key, required this.user}) : super(key: key);
  @override
  State<HomeProfPage> createState() => _HomeProfPageState();
}

class _HomeProfPageState extends State<HomeProfPage> {
  final _col = FirebaseFirestore.instance.collection('courses');
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  final List<Course> _items = [];

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    Query q = _col
        .where('profIds', arrayContains: widget.user.id)
        .orderBy('createdAt')
        .limit(10);
    if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
    final snap = await q.get();
    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _items.addAll(
        snap.docs.map(
          (d) => Course.fromMap(d.data() as Map<String, dynamic>, d.id),
        ),
      );
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
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(widget.user.logoUrl!),
          radius: 30,
          maxRadius: 30,
        ),
        title: Text('Professeur ${widget.user.name}'),
        actions: [iconLogout()],
      ),
      body:
          _items.length == 0
              ? Center(child: Lottie.asset('assets/lotties/kids (7).json'))
              : NotificationListener<ScrollNotification>(
                onNotification: (notif) {
                  if (notif.metrics.pixels >=
                      notif.metrics.maxScrollExtent - 200) {
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
                        // Ouvrir détails, CRUD en temps réel via snapshots
                      },
                    );
                  },
                ),
              ),
    );
  }
}
