// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:ecom/pages/profile_page.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../activities/HomeScreen.dart';
// import '../ads_provider.dart';
// import '../auth/AuthProvider.dart';
// import '../fonctions/AppLocalizations.dart';
// import '../fonctions/LanguageDropdownFlag.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     final provider = Provider.of<AdsProvider>(context, listen: false);
//     provider.fetchAds();
//
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels >=
//               _scrollController.position.maxScrollExtent - 200 &&
//           provider.hasMore &&
//           !provider.isLoading) {
//         provider.fetchAds();
//       }
//     });
//   }
//
//   Future<void> _onRefresh() async {
//     await Provider.of<AdsProvider>(
//       context,
//       listen: false,
//     ).fetchAds(refresh: true);
//   }
//
//   void _requireAuth(BuildContext context, Widget page) {
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     if (auth.isAuthenticated) {
//       Navigator.push(context, MaterialPageRoute(builder: (_) => page));
//     } else {
//       auth.signInWithGoogle().then((_) {
//         if (auth.isAuthenticated) {
//           Navigator.push(context, MaterialPageRoute(builder: (_) => page));
//         }
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final adsProvider = Provider.of<AdsProvider>(context);
//     final ads = adsProvider.ads;
//     final userProvider = Provider.of<AuthProvider>(context);
//     final user = userProvider.user;
//
//     return RefreshIndicator(
//       onRefresh: _onRefresh,
//       child: CustomScrollView(
//         controller: _scrollController,
//         slivers: [
//           SliverAppBar(
//             leadingWidth: 50,
//             titleSpacing: 0,
//             floating: true,
//             snap: true,
//             //expandedHeight: 200.0,
//             leading:
//                 user?.displayName != null
//                     ? InkWell(
//                       onTap: () async {
//                         Navigator.of(context).push(
//                           MaterialPageRoute(builder: (ctx) => ProfilePage()),
//                         );
//                       },
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(30),
//                           child: CachedNetworkImage(
//                             imageUrl: user!.photoURL!,
//                             width: 60,
//                             height: 60,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                     )
//                     : Padding(
//                       padding: const EdgeInsets.only(left: 16),
//                       child: IconButton(
//                         onPressed: () async {
//                           await userProvider.signInWithGoogle();
//                         },
//                         icon: Icon(Icons.account_circle, size: 35),
//                       ),
//                     ),
//             title: Text.rich(
//               overflow: TextOverflow.ellipsis,
//               TextSpan(
//                 children: [
//                   TextSpan(
//                     text: AppLocalizations.of(context).translate('hello'),
//                   ),
//                   TextSpan(text: ' '),
//                   TextSpan(
//                     text: user?.displayName ?? '',
//                     style: TextStyle(fontFamily: 'oswald'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               IconButton(
//                 onPressed:
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => HomeScreenAct()),
//                     ),
//
//                 icon: Icon(Icons.fitness_center),
//               ),
//               LanguageDropdownFlag(),
//             ],
//           ),
//           SliverToBoxAdapter(
//             child: Container(
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Row(
//                       children: [
//                         CircleAvatar(
//                           backgroundImage: NetworkImage(user?.photoURL ?? ''),
//                           radius: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextField(
//                             decoration: InputDecoration(
//                               hintText: "What's on your mind?",
//                               border: InputBorder.none,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.video_call, color: Colors.red),
//                           onPressed: () {},
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.photo, color: Colors.green),
//                           onPressed: () {},
//                         ),
//                         IconButton(
//                           icon: Icon(
//                             Icons.sentiment_satisfied,
//                             color: Colors.amber,
//                           ),
//                           onPressed: () {},
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           Consumer2<AuthProvider, AdsProvider>(
//             builder: (context, authProvider, adsProvider, _) {
//               if (!authProvider.isAuthenticated) {
//                 return SliverToBoxAdapter(
//                   child: Center(
//                     child: Text(
//                       "${AppLocalizations.of(context).translate('loginPrompt')}",
//                     ),
//                   ),
//                 );
//               }
//
//               final ads = adsProvider.ads;
//
//               return ads.isEmpty
//                   ? SliverToBoxAdapter(
//                     child: Center(
//                       child: Text(
//                         '${AppLocalizations.of(context).translate('noAds')}',
//                       ),
//                     ),
//                   )
//                   : SliverList(
//                     delegate: SliverChildBuilderDelegate((context, index) {
//                       if (index == ads.length && adsProvider.hasMore) {
//                         return const Padding(
//                           padding: EdgeInsets.symmetric(vertical: 16),
//                           child: Center(child: CircularProgressIndicator()),
//                         );
//                       }
//
//                       final ad = ads[index];
//                       final image =
//                           ad['imageUrls']?.isNotEmpty == true
//                               ? ad['imageUrls'][0]
//                               : null;
//
//                       return Card(
//                         margin: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: ListTile(
//                           leading:
//                               image != null
//                                   ? ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: CachedNetworkImage(
//                                       imageUrl: image,
//                                       width: 60,
//                                       height: 60,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   )
//                                   : const Icon(Icons.image_not_supported),
//                           title: Text(
//                             ad['title'] ??
//                                 '${AppLocalizations.of(context).translate('untitled')}',
//                           ),
//                           subtitle: Text(
//                             ad['description'] ?? '',
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       );
//                     }, childCount: ads.length + (adsProvider.hasMore ? 1 : 0)),
//                   );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // import 'package:cached_network_image/cached_network_image.dart';
// // import 'package:ecom/pages/profile_page.dart';
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// //
// // import '../ads_provider.dart';
// // import '../auth/AuthProvider.dart';
// // import '../fonctions/AppLocalizations.dart';
// // import '../fonctions/LanguageDropdownFlag.dart';
// // import 'AddAdPage.dart';
// //
// // class HomePage extends StatefulWidget {
// //   const HomePage({super.key});
// //
// //   @override
// //   State<HomePage> createState() => _HomePageState();
// // }
// //
// // class _HomePageState extends State<HomePage> {
// //   final ScrollController _scrollController = ScrollController();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     final provider = Provider.of<AdsProvider>(context, listen: false);
// //     provider.fetchAds();
// //
// //     _scrollController.addListener(() {
// //       if (_scrollController.position.pixels >=
// //               _scrollController.position.maxScrollExtent - 200 &&
// //           provider.hasMore &&
// //           !provider.isLoading) {
// //         provider.fetchAds();
// //       }
// //     });
// //   }
// //
// //   Future<void> _onRefresh() async {
// //     await Provider.of<AdsProvider>(
// //       context,
// //       listen: false,
// //     ).fetchAds(refresh: true);
// //   }
// //
// //   void _requireAuth(BuildContext context, Widget page) {
// //     final auth = Provider.of<AuthProvider>(context, listen: false);
// //     if (auth.isAuthenticated) {
// //       Navigator.push(context, MaterialPageRoute(builder: (_) => page));
// //     } else {
// //       auth.signInWithGoogle().then((_) {
// //         if (auth.isAuthenticated) {
// //           Navigator.push(context, MaterialPageRoute(builder: (_) => page));
// //         }
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final adsProvider = Provider.of<AdsProvider>(context);
// //     final ads = adsProvider.ads;
// //     final userProvider = Provider.of<AuthProvider>(context);
// //     final user = userProvider.user;
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         leadingWidth: 50,
// //         titleSpacing: 0,
// //         leading:
// //             user?.displayName != null
// //                 ? Padding(
// //                   padding: const EdgeInsets.all(8.0),
// //                   child: InkWell(
// //                     onTap: () async {
// //                       Navigator.of(context).push(
// //                         MaterialPageRoute(builder: (ctx) => ProfilePage()),
// //                       );
// //                     },
// //                     child: CircleAvatar(
// //                       backgroundImage: CachedNetworkImageProvider(
// //                         user!.photoURL ?? '',
// //                       ),
// //                       radius: 20, // Important : plus petit pour AppBar
// //                     ),
// //                   ),
// //                 )
// //                 : Padding(
// //                   padding: const EdgeInsets.only(left: 16),
// //                   child: IconButton(
// //                     onPressed: () async {
// //                       await userProvider.signInWithGoogle();
// //                     },
// //                     icon: Icon(Icons.account_circle, size: 35),
// //                   ),
// //                 ),
// //
// //         // user == null
// //         //     ? IconButton(
// //         //       icon: Icon(Icons.account_box),
// //         //       onPressed: () async {
// //         //         await userProvider.signInWithGoogle();
// //         //       },
// //         //     )
// //         //     : Padding(
// //         //       padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
// //         //       child: CircleAvatar(
// //         //         backgroundImage: CachedNetworkImageProvider(user.photoURL!),
// //         //       ),
// //         //     ),
// //         title: Text.rich(
// //           overflow: TextOverflow.ellipsis,
// //           TextSpan(
// //             children: [
// //               TextSpan(text: AppLocalizations.of(context).translate('hello')),
// //               TextSpan(text: ' '),
// //               TextSpan(
// //                 text: user?.displayName ?? '',
// //                 style: TextStyle(fontFamily: 'oswald'),
// //               ),
// //             ],
// //           ),
// //         ),
// //
// //         actions: [
// //           // IconButton(
// //           //   onPressed: () {
// //           //     ajouterAnnoncesFacticesAvecImages();
// //           //   },
// //           //   icon: const Icon(Icons.add),
// //           // ),
// //           LanguageDropdownFlag(),
// //         ],
// //       ),
// //       body: Consumer2<AuthProvider, AdsProvider>(
// //         builder: (context, authProvider, adsProvider, _) {
// //           if (!authProvider.isAuthenticated) {
// //             return Center(
// //               child: Text(
// //                 "${AppLocalizations.of(context).translate('loginPrompt')}",
// //               ),
// //             );
// //           }
// //
// //           final ads = adsProvider.ads;
// //
// //           return RefreshIndicator(
// //             onRefresh: adsProvider.fetchAds,
// //             child:
// //                 ads.isEmpty
// //                     ? RefreshIndicator(
// //                       onRefresh: adsProvider.fetchAds,
// //                       child: Center(
// //                         child: Text(
// //                           '${AppLocalizations.of(context).translate('noAds')}',
// //                         ),
// //                       ),
// //                     )
// //                     : ListView.builder(
// //                       controller: _scrollController,
// //                       itemCount: ads.length + (adsProvider.hasMore ? 1 : 0),
// //                       itemBuilder: (context, index) {
// //                         if (index == ads.length) {
// //                           return const Padding(
// //                             padding: EdgeInsets.symmetric(vertical: 16),
// //                             child: Center(child: CircularProgressIndicator()),
// //                           );
// //                         }
// //
// //                         final ad = ads[index];
// //                         final image =
// //                             ad['imageUrls']?.isNotEmpty == true
// //                                 ? ad['imageUrls'][0]
// //                                 : null;
// //
// //                         return Card(
// //                           margin: const EdgeInsets.symmetric(
// //                             horizontal: 12,
// //                             vertical: 6,
// //                           ),
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(16),
// //                           ),
// //                           child: ListTile(
// //                             leading:
// //                                 image != null
// //                                     ? ClipRRect(
// //                                       borderRadius: BorderRadius.circular(8),
// //                                       child: Image.network(
// //                                         image,
// //                                         width: 60,
// //                                         height: 60,
// //                                         fit: BoxFit.cover,
// //                                       ),
// //                                     )
// //                                     : const Icon(Icons.image_not_supported),
// //                             title: Text(
// //                               ad['title'] ??
// //                                   '${AppLocalizations.of(context).translate('untitled')}',
// //                             ),
// //                             subtitle: Text(
// //                               ad['description'] ?? '',
// //                               maxLines: 2,
// //                               overflow: TextOverflow.ellipsis,
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //           );
// //         },
// //       ),
// //
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () => _requireAuth(context, CreatePostScreen()),
// //         //label: const Text("Ajouter une annonce"),
// //         child: const Icon(Icons.add),
// //       ),
// //     );
// //   }
// // }
