// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:ecom/activities/ClubDetailScreen.dart';
// import 'package:ecom/auth/AuthProvider.dart';
// import 'package:ecom/pages/MyApp.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../fonctions/AppLocalizations.dart';
// import 'AddChildScreen.dart';
// import 'AddCourseScreen.dart';
// import 'ClubRegistrationScreen.dart';
// import 'ParentsScreen.dart';
// import 'coach.dart';
// import 'data_populator.dart';
// import 'modèles.dart';
// import 'providers.dart';
//
// class HomeScreenAct extends StatefulWidget {
//   const HomeScreenAct({Key? key}) : super(key: key);
//
//   @override
//   State<HomeScreenAct> createState() => _HomeScreenActState();
// }
//
// class _HomeScreenActState extends State<HomeScreenAct> {
//   bool _isLoading = false;
//   final AuthService _authService = AuthService();
//   User? _user = FirebaseAuth.instance.currentUser;
//   bool isLoading = false;
//   List<Map<String, dynamic>> _reportedNumbers = [];
//   bool hasMore = true;
//   int currentPage = 0;
//   final int pageSize = 10; // Nombre de résultats par page
//   bool isSigningOut = false;
//
//   // Logout handler with confirmation dialog
//   Future<void> _handleSignOut() async {
//     setState(() => isSigningOut = true);
//
//     try {
//       // On attend que les deux futures se terminent : la déconnexion + le délai
//       await Future.wait([
//         _authService.signOut(),
//         Future.delayed(const Duration(seconds: 2)), // 👈 délai imposé
//       ]);
//       Navigator.of(
//         context,
//       ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp()));
//       setState(() {
//         _user = null;
//         _reportedNumbers.clear();
//       });
//     } catch (e) {
//       print('Erreur déconnexion: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(AppLocalizations.of(context).translate('connexErreur')),
//         ),
//       );
//     } finally {
//       setState(() => isSigningOut = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer3<ClubProvider, UserProvider, CourseProvider>(
//       builder: (context, clubProvider, userProvider, courseProvider, child) {
//         if (clubProvider.isLoading ||
//             userProvider.isLoading ||
//             courseProvider.isLoading) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         return Scaffold(
//           appBar: AppBar(
//             automaticallyImplyLeading: false,
//             title: const Text('Gestion Parents et Enfants'),
//             actions: [
//               ClearDatabaseButton(),
//               // IconButton(
//               //   icon: const Icon(Icons.refresh),
//               //   onPressed: () {
//               //     // No need to call loadData or fetchCourses as streams are used
//               //   },
//               // ),
//               // IconButton(
//               //   onPressed: () async {
//               //     await DataPopulator().populateData();
//               //   },
//               //   icon: Icon(Icons.add_road, color: Colors.green),
//               // ),
//               IconButton(
//                 onPressed: () async {
//                   await DataPopulatorClaude().populateData();
//                 },
//                 icon: Icon(Icons.add_road, color: Colors.deepPurple),
//               ),
//               IconButton(
//                 onPressed: _isLoading ? null : _handleSignOut,
//                 icon:
//                     _isLoading
//                         ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                         : const Icon(Icons.logout),
//                 tooltip: 'Logout',
//               ),
//             ],
//           ),
//           drawer:
//               _user != null
//                   ? AppDrawer(
//                     userName: _user?.displayName ?? 'User',
//                     urlImage: _user?.photoURL! ?? '',
//                   )
//                   : null,
//           body: RefreshIndicator(
//             onRefresh: () async {},
//             child: CustomScrollView(
//               slivers: [
//                 SliverToBoxAdapter(
//                   child: ElevatedButton(
//                     onPressed:
//                         () => Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => ScreenButtons()),
//                         ),
//
//                     child: Text('Les Screens'),
//                   ),
//                 ),
//                 _user == null
//                     ? SliverToBoxAdapter(child: SizedBox.shrink())
//                     : SliverToBoxAdapter(
//                       child: Center(
//                         child: TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder:
//                                     (_) => ParentProfileScreen(
//                                       parentId: _user!.uid,
//                                     ), // Pass parentId
//                               ),
//                             );
//                           },
//                           child: Column(
//                             children: [
//                               Text(_user!.displayName ?? 'User'),
//                               FutureBuilder<UserModel?>(
//                                 future: userProvider.getUserData(_user!.uid),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return Center(
//                                       child: CircularProgressIndicator(),
//                                     );
//                                   }
//
//                                   if (!snapshot.hasData ||
//                                       snapshot.data == null) {
//                                     return Center(
//                                       child: Text('Utilisateur non trouvé'),
//                                     );
//                                   }
//
//                                   final userFire = snapshot.data!;
//                                   return Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(userFire.role.toUpperCase()),
//
//                                       Text(
//                                         'Créer le : ' +
//                                             DateFormat(
//                                               'dd/MM/yyyy HH:mm',
//                                             ).format(userFire.createdAt!),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                 SliverToBoxAdapter(
//                   child: SizedBox(
//                     height: 120,
//                     child: _buildCoursesList(courseProvider.courses, context),
//                   ),
//                 ),
//                 SliverList(
//                   delegate: SliverChildBuilderDelegate((context, index) {
//                     final parentWithChildren =
//                         userProvider.parentsWithChildren[index];
//
//                     return _buildParentCard(
//                       context,
//                       parentWithChildren.parent.id, // Pass parentId
//
//                       courseProvider,
//                     );
//                   }, childCount: userProvider.parentsWithChildren.length),
//                 ),
//               ],
//             ),
//           ),
//           floatingActionButton: Column(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               const SizedBox(height: 10),
//               FloatingActionButton(
//                 onPressed: () async {
//                   await Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => AddCourseScreen()),
//                   );
//                 },
//                 heroTag: 'addCourse',
//                 child: const Icon(Icons.add),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildCoursesList(List<Course> courses, BuildContext context) {
//     return ListView.builder(
//       scrollDirection: Axis.horizontal,
//       itemCount: courses.length,
//       itemBuilder: (context, index) {
//         final course = courses[index];
//         return Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: InkWell(
//             onTap:
//                 () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (_) => ClubDetailScreen(
//                           club: course.club,
//                         ), // Pass parentId
//                   ),
//                 ),
//             child: Chip(
//               backgroundColor: Theme.of(context).colorScheme.inverseSurface,
//               label: Text(course.name),
//               avatar: CircleAvatar(
//                 child: Text(course.ageRange.split('-').first),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildParentCard(
//     BuildContext context,
//     String parentId, // Accept parentId
//     CourseProvider courseProvider,
//   ) {
//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       color: Theme.of(context).colorScheme.onSecondary,
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) =>
//                       ParentProfileScreen(parentId: parentId), // Pass parentId
//             ),
//           );
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Consumer<UserProvider>(
//             builder: (context, userProvider, child) {
//               final parentWithChildren = userProvider.getParentWithChildrenById(
//                 parentId,
//               );
//
//               if (parentWithChildren == null) {
//                 return const SizedBox.shrink();
//               }
//
//               return Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 alignment: WrapAlignment.center,
//                 children: [
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: RichText(
//                       text: TextSpan(
//                         style: Theme.of(context).textTheme.titleLarge,
//                         children: [
//                           const WidgetSpan(
//                             alignment: PlaceholderAlignment.middle,
//                             child: const Icon(Icons.person, size: 30),
//                           ),
//                           TextSpan(
//                             text: '${parentWithChildren.parent.name}   ',
//                           ),
//                           const WidgetSpan(
//                             alignment: PlaceholderAlignment.middle,
//                             child: Icon(Icons.face),
//                           ),
//                           TextSpan(
//                             text: ' ${parentWithChildren.children.length}',
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   ...parentWithChildren.children.map((child) {
//                     final enrolledCourses =
//                         courseProvider.courses
//                             .where(
//                               (course) =>
//                                   child.enrolledCourses.contains(course.id),
//                             )
//                             .toList();
//
//                     return SizedBox(
//                       width: MediaQuery.of(context).size.width / 2.4,
//                       height: 250,
//                       child: Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 4,
//                         clipBehavior: Clip.antiAlias,
//                         child: InkWell(
//                           onLongPress: () async {
//                             final confirmed = await showDialog<bool>(
//                               context: context,
//                               builder:
//                                   (context) => AlertDialog(
//                                     title: const Text(
//                                       'Confirmer la suppression',
//                                     ),
//                                     content: const Text(
//                                       'Voulez-vous vraiment supprimer cet enfant ?',
//                                     ),
//                                     actions: [
//                                       TextButton(
//                                         onPressed:
//                                             () => Navigator.of(
//                                               context,
//                                             ).pop(false),
//                                         child: const Text('Annuler'),
//                                       ),
//                                       TextButton(
//                                         onPressed:
//                                             () =>
//                                                 Navigator.of(context).pop(true),
//                                         child: const Text(
//                                           'Supprimer',
//                                           style: TextStyle(color: Colors.red),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                             );
//
//                             if (confirmed == true) {
//                               await context.read<ClubProvider>().deleteChild(
//                                 child.id,
//                               );
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Enfant supprimé avec succès'),
//                                 ),
//                               );
//                             }
//                           },
//                           child: Stack(
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 20,
//                                 ),
//                                 child: Center(
//                                   child: Column(
//                                     children: [
//                                       CircleAvatar(
//                                         radius: 30,
//                                         backgroundColor:
//                                             child.gender == 'male'
//                                                 ? Colors.blue.shade100
//                                                 : child.gender == 'female'
//                                                 ? Colors.pink.shade100
//                                                 : Colors.grey.shade300,
//                                         child: Icon(
//                                           child.gender == 'male'
//                                               ? Icons.face
//                                               : child.gender == 'female'
//                                               ? Icons.face_3
//                                               : Icons.account_box,
//                                           size: 30,
//                                           color:
//                                               child.gender == 'male'
//                                                   ? Colors.blue
//                                                   : child.gender == 'female'
//                                                   ? Colors.pink
//                                                   : Colors.grey,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Text(
//                                         child.name,
//                                         textAlign: TextAlign.center,
//                                         style:
//                                             Theme.of(
//                                               context,
//                                             ).textTheme.titleMedium,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       Text(
//                                         '(${child.age} ans)',
//                                         style:
//                                             Theme.of(
//                                               context,
//                                             ).textTheme.bodySmall,
//                                       ),
//                                       const Spacer(),
//                                       if (enrolledCourses.isNotEmpty)
//                                         ...enrolledCourses.map(
//                                           (course) => Padding(
//                                             padding: const EdgeInsets.only(
//                                               top: 4.0,
//                                             ),
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   course.name,
//                                                   style:
//                                                       Theme.of(
//                                                         context,
//                                                       ).textTheme.bodyMedium,
//                                                 ),
//                                                 // Text(
//                                                 //   course.schedules.toString(),
//                                                 //   style:
//                                                 //       Theme.of(
//                                                 //         context,
//                                                 //       ).textTheme.bodySmall,
//                                                 // ),
//                                               ],
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 top: 4,
//                                 right: 0,
//                                 child: PopupMenuButton<String>(
//                                   icon: const Icon(Icons.more_vert),
//                                   tooltip: 'Actions',
//                                   onSelected: (value) async {
//                                     if (value == 'edit') {
//                                       await Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder:
//                                               (context) => AddChildScreen(
//                                                 parent:
//                                                     parentWithChildren.parent,
//                                                 child: child,
//                                               ),
//                                         ),
//                                       );
//                                     } else if (value == 'delete') {
//                                       final confirmed = await showDialog<bool>(
//                                         context: context,
//                                         builder:
//                                             (context) => AlertDialog(
//                                               title: const Text(
//                                                 'Confirmer la suppression',
//                                               ),
//                                               content: const Text(
//                                                 'Voulez-vous vraiment supprimer cet enfant ?',
//                                               ),
//                                               actions: [
//                                                 TextButton(
//                                                   onPressed:
//                                                       () => Navigator.of(
//                                                         context,
//                                                       ).pop(false),
//                                                   child: const Text('Annuler'),
//                                                 ),
//                                                 TextButton(
//                                                   onPressed:
//                                                       () => Navigator.of(
//                                                         context,
//                                                       ).pop(true),
//                                                   child: const Text(
//                                                     'Supprimer',
//                                                     style: TextStyle(
//                                                       color: Colors.red,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                       );
//
//                                       if (confirmed == true) {
//                                         await context
//                                             .read<ClubProvider>()
//                                             .deleteChild(child.id);
//                                         ScaffoldMessenger.of(
//                                           context,
//                                         ).showSnackBar(
//                                           const SnackBar(
//                                             content: Text(
//                                               'Enfant supprimé avec succès',
//                                             ),
//                                           ),
//                                         );
//                                       }
//                                     }
//                                   },
//                                   itemBuilder:
//                                       (context) => [
//                                         const PopupMenuItem(
//                                           value: 'edit',
//                                           child: ListTile(
//                                             leading: Icon(Icons.edit),
//                                             title: Text('Modifier'),
//                                           ),
//                                         ),
//                                         const PopupMenuItem(
//                                           value: 'delete',
//                                           child: ListTile(
//                                             leading: Icon(
//                                               Icons.delete,
//                                               color: Colors.red,
//                                             ),
//                                             title: Text(
//                                               'Supprimer',
//                                               style: TextStyle(
//                                                 color: Colors.red,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class AppDrawer extends StatelessWidget {
//   final String userName;
//   final String urlImage;
//
//   const AppDrawer({Key? key, required this.userName, required this.urlImage})
//     : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: <Widget>[
//           DrawerHeader(
//             decoration: BoxDecoration(
//               color: Colors.blue,
//               image: DecorationImage(
//                 image: CachedNetworkImageProvider(urlImage),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Text(
//               'Welcome, $userName',
//               style: TextStyle(color: Colors.white, fontSize: 24),
//             ),
//           ),
//           ListTile(
//             leading: Icon(Icons.home),
//             title: Text('Home'),
//             onTap: () {
//               Navigator.pop(context); // Close the drawer
//               // Navigate to the home screen
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => HomeScreenAct()),
//               );
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings),
//             title: Text('Settings'),
//             onTap: () {
//               Navigator.pop(context); // Close the drawer
//               // Navigate to the settings screen
//               // Navigator.push(
//               //   context,
//               //   MaterialPageRoute(builder: (context) => SettingsScreen()),
//               // );
//             },
//           ),
//           // ListTile(
//           //   leading: Icon(Icons.logout),
//           //   title: Text('Logout'),
//           //   onTap: () async {
//           //     Navigator.pop(context); // Close the drawer
//           //     // Perform logout
//           //     logout;
//           //   },
//           // ),
//         ],
//       ),
//     );
//   }
// }
//
// class ScreenButtons extends StatelessWidget {
//   const ScreenButtons({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () async {
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => AddCourseScreen()),
//                 );
//               },
//               child: Text('AddCourseScreen'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => ClubRegistrationScreen(),
//                   ),
//                 );
//               },
//               child: Text('ClubRegistrationScreen'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ClubsListScreen()),
//                 );
//               },
//               child: Text('ClubsListScreen'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ProfsListScreen()),
//                 );
//               },
//               child: Text('ProfsListScreen'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => AddCourseScreen()),
//                 );
//               },
//               child: Text(''),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
