// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// import '../modèles.dart';
// import 'childDetail.dart';
//
// class ChildrenListScreen extends StatefulWidget {
//   @override
//   _ChildrenListScreenState createState() => _ChildrenListScreenState();
// }
//
// class _ChildrenListScreenState extends State<ChildrenListScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final List<Child> _children = [];
//   bool _isLoading = false;
//   bool _hasMore = true;
//   DocumentSnapshot? _lastDocument;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadChildren();
//     _scrollController.addListener(_onScroll);
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _onScroll() {
//     if (_scrollController.position.pixels ==
//         _scrollController.position.maxScrollExtent &&
//         !_isLoading &&
//         _hasMore) {
//       _loadChildren();
//     }
//   }
//
//   Future<void> _loadChildren() async {
//     if (_isLoading) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       Query query = FirebaseFirestore.instance
//           .collectionGroup('children')
//           .orderBy('name')
//           .limit(10);
//
//       if (_lastDocument != null) {
//         query = query.startAfterDocument(_lastDocument!);
//       }
//
//       final snapshot = await query.get();
//
//       if (snapshot.docs.isEmpty) {
//         setState(() => _hasMore = false);
//       } else {
//         _lastDocument = snapshot.docs.last;
//         _children.addAll(snapshot.docs.map((doc) => Child.fromMap(doc.data(), doc.id)));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur de chargement: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Tous les enfants')),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           setState(() {
//             _children.clear();
//             _lastDocument = null;
//             _hasMore = true;
//           });
//           await _loadChildren();
//         },
//         child: ListView.builder(
//           controller: _scrollController,
//           itemCount: _children.length + 1,
//           itemBuilder: (context, index) {
//             if (index < _children.length) {
//               final child = _children[index];
//               return _buildChildItem(child);
//             } else {
//               return _buildLoader();
//             }
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildChildItem(Child child) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundImage: NetworkImage('https://picsum.photos/seed/${child.id}/200'),
//       ),
//       title: Text(child.name),
//       subtitle: Text('${child.age} ans'),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ChildDetailScreen(child: child),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLoader() {
//     return _hasMore
//         ? Padding(
//       padding: EdgeInsets.symmetric(vertical: 16),
//       child: Center(child: CircularProgressIndicator()),
//     )
//         : Container();
//   }
// }
