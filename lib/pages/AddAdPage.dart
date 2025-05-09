// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:ecom/pages/profile_page.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../auth/AuthProvider.dart';
//
// class CreatePostScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<AuthProvider>(context);
//     final user = userProvider.user;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Create Post'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               // Logic for posting
//             },
//             child: Text('Post', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: InkWell(
//                     onTap: () async {
//                       Navigator.of(context).push(
//                         MaterialPageRoute(builder: (ctx) => ProfilePage()),
//                       );
//                     },
//                     child: CircleAvatar(
//                       backgroundImage: CachedNetworkImageProvider(
//                         user!.photoURL ?? '',
//                       ),
//                       radius: 20, // Important : plus petit pour AppBar
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Tirex Cut',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text('Public', style: TextStyle(color: Colors.grey)),
//                   ],
//                 ),
//                 Spacer(),
//                 IconButton(
//                   icon: Icon(Icons.public),
//                   onPressed: () {
//                     // Logic for changing audience
//                   },
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             TextField(
//               decoration: InputDecoration(
//                 hintText: "What's on your mind, Cut?",
//                 border: InputBorder.none,
//               ),
//               maxLines: null,
//             ),
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.photo),
//                   onPressed: () {
//                     // Logic for adding photo
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.tag_faces),
//                   onPressed: () {
//                     // Logic for tagging friends
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.sentiment_satisfied_alt),
//                   onPressed: () {
//                     // Logic for adding emojis
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.location_on),
//                   onPressed: () {
//                     // Logic for adding location
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.gif),
//                   onPressed: () {
//                     // Logic for adding GIF
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // class AddAdPage extends StatefulWidget {
// //   const AddAdPage({super.key});
// //
// //   @override
// //   State<AddAdPage> createState() => _AddAdPageState();
// // }
// //
// // class _AddAdPageState extends State<AddAdPage> {
// //   final _titleController = TextEditingController();
// //   final _descController = TextEditingController();
// //   final List<XFile> _images = [];
// //   final picker = ImagePicker();
// //   bool _isUploading = false;
// //
// //   Future<void> _pickImages() async {
// //     final picked = await picker.pickMultiImage(imageQuality: 70);
// //     if (picked != null) {
// //       setState(() {
// //         _images.addAll(picked);
// //       });
// //     }
// //   }
// //
// //   Future<List<String>> _uploadImages(String adId) async {
// //     final List<String> downloadUrls = [];
// //     for (int i = 0; i < _images.length; i++) {
// //       final file = File(_images[i].path);
// //       final ref = FirebaseStorage.instance.ref().child(
// //         'ads/$adId/image_$i.jpg',
// //       );
// //
// //       await ref.putFile(file);
// //       final url = await ref.getDownloadURL();
// //       downloadUrls.add(url);
// //     }
// //     return downloadUrls;
// //   }
// //
// //   Future<void> _submitAd() async {
// //     final title = _titleController.text.trim();
// //     final desc = _descController.text.trim();
// //     final user = Provider.of<AuthProvider>(context, listen: false).user;
// //
// //     if (title.isEmpty || desc.isEmpty || _images.isEmpty || user == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             '${AppLocalizations.of(context).translate('fillAllFields')}',
// //           ),
// //         ),
// //       );
// //       return;
// //     }
// //
// //     setState(() => _isUploading = true);
// //
// //     final docRef = FirebaseFirestore.instance.collection('ads').doc();
// //     final imageUrls = await _uploadImages(docRef.id);
// //
// //     await docRef.set({
// //       'id': docRef.id,
// //       'title': title,
// //       'description': desc,
// //       'imageUrls': imageUrls,
// //       'userId': user.uid,
// //       'createdAt': FieldValue.serverTimestamp(),
// //     });
// //
// //     setState(() => _isUploading = false);
// //     Navigator.pop(context);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text("${AppLocalizations.of(context).translate('newAd')}"),
// //       ),
// //       body:
// //           _isUploading
// //               ? const Center(child: CircularProgressIndicator())
// //               : SingleChildScrollView(
// //                 padding: const EdgeInsets.all(16),
// //                 child: Column(
// //                   children: [
// //                     TextField(
// //                       controller: _titleController,
// //                       decoration: InputDecoration(
// //                         labelText:
// //                             '${AppLocalizations.of(context).translate('title')}',
// //                       ),
// //                     ),
// //                     TextField(
// //                       controller: _descController,
// //                       decoration: InputDecoration(
// //                         labelText:
// //                             '${AppLocalizations.of(context).translate('description')}',
// //                       ),
// //                       maxLines: 3,
// //                     ),
// //                     const SizedBox(height: 12),
// //                     ElevatedButton.icon(
// //                       onPressed: _pickImages,
// //                       icon: const Icon(Icons.photo_library),
// //                       label: Text(
// //                         "${AppLocalizations.of(context).translate('choosePhotos')}",
// //                       ),
// //                     ),
// //                     const SizedBox(height: 10),
// //                     Wrap(
// //                       spacing: 8,
// //                       children:
// //                           _images
// //                               .map(
// //                                 (xfile) => Stack(
// //                                   alignment: Alignment.topRight,
// //                                   children: [
// //                                     Image.file(
// //                                       File(xfile.path),
// //                                       width: 100,
// //                                       height: 100,
// //                                       fit: BoxFit.cover,
// //                                     ),
// //                                     IconButton(
// //                                       icon: const Icon(
// //                                         Icons.cancel,
// //                                         color: Colors.red,
// //                                       ),
// //                                       onPressed: () {
// //                                         setState(() => _images.remove(xfile));
// //                                       },
// //                                     ),
// //                                   ],
// //                                 ),
// //                               )
// //                               .toList(),
// //                     ),
// //                     const SizedBox(height: 20),
// //                     ElevatedButton.icon(
// //                       onPressed: _submitAd,
// //                       icon: const Icon(Icons.check),
// //                       label: Text(
// //                         "${AppLocalizations.of(context).translate('publish')}",
// //                       ),
// //                       style: ElevatedButton.styleFrom(
// //                         minimumSize: const Size.fromHeight(50),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //     );
// //   }
// // }
