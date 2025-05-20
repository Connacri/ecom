// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// class ImageGrid extends StatefulWidget {
//   @override
//   _ImageGridState createState() => _ImageGridState();
// }
//
// class _ImageGridState extends State<ImageGrid> {
//   final ScrollController _scrollController = ScrollController();
//   List<DocumentSnapshot> _images = [];
//   DocumentSnapshot? _lastVisible;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_scrollListener);
//     _loadImages();
//   }
//
//   @override
//   void dispose() {
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _scrollListener() {
//     if (_scrollController.position.pixels ==
//         _scrollController.position.maxScrollExtent) {
//       _loadImages();
//     }
//   }
//
//   Future<void> _loadImages() async {
//     if (_isLoading) return;
//     setState(() {
//       _isLoading = true;
//     });
//
//     Query query = FirebaseFirestore.instance
//         .collection('storage')
//         .orderBy('createdAt');
//     // .limit(10);
//
//     if (_lastVisible != null) {
//       query = query.startAfterDocument(_lastVisible!);
//     }
//
//     QuerySnapshot querySnapshot = await query.get();
//     setState(() {
//       _images.addAll(querySnapshot.docs);
//       _lastVisible =
//           querySnapshot.docs.isNotEmpty
//               ? querySnapshot.docs.last
//               : _lastVisible;
//       _isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Image Grid')),
//       body: GridView.builder(
//         controller: _scrollController,
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           crossAxisSpacing: 4.0,
//           mainAxisSpacing: 4.0,
//         ),
//         itemCount: _images.length + (_isLoading ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == _images.length) {
//             return Center(child: CircularProgressIndicator());
//           }
//           String imageUrl = _images[index]['url'];
//           return CachedNetworkImage(
//             imageUrl: imageUrl,
//             fit: BoxFit.cover,
//             placeholder: (context, url) => Container(color: Colors.grey),
//             errorWidget: (context, url, error) => Icon(Icons.error),
//           );
//         },
//       ),
//     );
//   }
// }
