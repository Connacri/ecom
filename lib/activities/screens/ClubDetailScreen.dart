import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../test/widgets.dart';
import '../modèles.dart';

class ClubDetailScreen extends StatefulWidget {
  final UserModel club;

  const ClubDetailScreen({Key? key, required this.club}) : super(key: key);

  @override
  _ClubDetailScreenState createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  late Future<List<Course>> _coursesFuture;
  late Future<List<UserModel>> _profsFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadClubCourses();
    _profsFuture = _loadClubProfs();
  }

  Future<List<Course>> _loadClubCourses() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('courses')
            .where('clubId', isEqualTo: widget.club.id)
            .get();

    return snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UserModel>> _loadClubProfs() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('profs')
            .where('clubIds', arrayContains: widget.club.id)
            .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), widget.club.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.club.name),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.club.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pinned: true,
            actions: [
              IconButton(icon: Icon(Icons.share), onPressed: _shareClub),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(widget.club.phone!), iconLogout()],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text('Lorem ipsum description du club...'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Cours proposés',
                style: Theme.of(context).textTheme.bodyMedium,
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
                return SliverToBoxAdapter(
                  child: Center(child: Text('Aucun cours proposé')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCourseItem(snapshot.data![index]),
                  childCount: snapshot.data!.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Professeurs',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          FutureBuilder<List<UserModel>>(
            future: _profsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('Aucun professeur')),
                );
              }

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProfCard(snapshot.data![index]),
                  childCount: snapshot.data!.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(Course course) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(course.club.logoUrl!),
        ),
        title: Text(course.name),
        subtitle: Text(
          '${course.ageRange} • ${course.schedules.length} séances',
        ),
        onTap: () => _navigateToCourseDetail(course),
      ),
    );
  }

  Widget _buildProfCard(UserModel prof) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              child: Image.network(
                prof.photos!.isNotEmpty
                    ? prof.photos!.first
                    : 'https://picsum.photos/200',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(prof.name, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  void _navigateToCourseDetail(Course course) {
    // Implémentez la navigation vers le détail du cours
  }

  void _shareClub() {
    // Implémentez le partage du club
  }
}
