// import 'package:ecom/activities/providers.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../test/profile_provider.dart';
// import 'ClubRegistrationScreen.dart';
// import 'modèles.dart';
//
// class ClubDetailScreen extends StatelessWidget {
//   final UserModel club;
//
//   ClubDetailScreen({required this.club});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(club.name)),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Image.network(
//                 club.logoUrl!,
//                 width: double.infinity,
//                 height: 200,
//                 fit: BoxFit.cover,
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Photos',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children:
//                     club.photos!
//                         .map(
//                           (photoUrl) => Image.network(
//                             photoUrl,
//                             width: 100,
//                             height: 100,
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                         .toList(),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Cours',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               ...club.courses!.map(
//                 (course) => Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       course.name,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 5),
//                     Text(course.description),
//                     SizedBox(height: 5),
//                     Text('Tranche d\'âge: ${course.ageRange}'),
//                     SizedBox(height: 5),
//                     Text('Horaires:'),
//                     ...course.schedules.map(
//                       (schedule) => Text(
//                         '${schedule.days.join(", ")}: ${schedule.startTime.toString().substring(11, 16)} - ${schedule.endTime.toString().substring(11, 16)}',
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class ClubsListScreen extends StatelessWidget {
//   const ClubsListScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gestion des Clubs'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed:
//                 () => Navigator.of(context).push(
//                   MaterialPageRoute(builder: (ctx) => ClubRegistrationScreen()),
//                 ),
//           ),
//         ],
//       ),
//       body: _buildClubList(context),
//     );
//   }
//
//   Widget _buildClubList(BuildContext context) {
//     final profileProvider = Provider.of<ProfileProvider>(context);
//
//     if (profileProvider.isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (profileProvider.user.isEmpty) {
//       return const Center(child: Text('Aucun club disponible'));
//     }
//
//     return ListView.builder(
//       itemCount: profileProvider.users.length,
//       itemBuilder: (context, index) {
//         final club = profileProvider.users[index];
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//           child: ListTile(
//             leading:
//                 club.logoUrl.isNotEmpty
//                     ? CircleAvatar(backgroundImage: NetworkImage(club.logoUrl))
//                     : const CircleAvatar(child: Icon(Icons.sports_soccer)),
//             title: Text(club.name),
//             subtitle: Text(
//               '${club.courses.length} cours • ${club.phone.isNotEmpty ? club.phone : 'Pas de téléphone'}',
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit, color: Colors.blue),
//                   onPressed: () => _navigateToEditClub(context, club),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => _confirmDeleteClub(context, club),
//                 ),
//               ],
//             ),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ClubDetailScreen(club: club),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   void _navigateToEditClub(BuildContext context, UserModel? user) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ClubRegistrationScreen(club: user),
//       ),
//     );
//   }
//
//   Future<void> _confirmDeleteClub(BuildContext context, UserModel user) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Confirmer la suppression'),
//             content: Text('Voulez-vous vraiment supprimer ${user.name} ?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Annuler'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text(
//                   'Supprimer',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//
//     if (confirmed == true) {
//       try {
//         await Provider.of<ProfileProvider>(
//           context,
//           listen: false,
//         ).deleteClub(club.id);
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('${user.name} a été supprimé')));
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur lors de la suppression: $e')),
//         );
//       }
//     }
//   }
// }
