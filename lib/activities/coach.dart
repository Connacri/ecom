// import 'package:ecom/activities/providers.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import 'modèles.dart';
//
// class ProfsListScreen extends StatelessWidget {
//   const ProfsListScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gestion des Professeurs'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () => _navigateToEditProf(context, null),
//           ),
//         ],
//       ),
//       body: _buildProfList(context),
//     );
//   }
//
//   Widget _buildProfList(BuildContext context) {
//     final profProvider = Provider.of<ProfProvider>(context);
//
//     if (profProvider.isLoading && profProvider.profs.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (profProvider.profs.isEmpty) {
//       return const Center(child: Text('Aucun professeur disponible'));
//     }
//
//     return ListView.builder(
//       itemCount: profProvider.profs.length,
//       itemBuilder: (context, index) {
//         final prof = profProvider.profs[index];
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//           child: ListTile(
//             leading: const CircleAvatar(child: Icon(Icons.person)),
//             title: Text(prof.name),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [Text(prof.email), Text(prof.phone)],
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit, color: Colors.blue),
//                   onPressed: () => _navigateToEditProf(context, prof),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => _confirmDeleteProf(context, prof),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _navigateToEditProf(BuildContext context, Prof? prof) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => ProfEditScreen(prof: prof)),
//     );
//   }
//
//   Future<void> _confirmDeleteProf(BuildContext context, Prof prof) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Confirmer la suppression'),
//             content: Text('Voulez-vous vraiment supprimer ${prof.name} ?'),
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
//         await Provider.of<ProfProvider>(
//           context,
//           listen: false,
//         ).deleteProf(prof.id);
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('${prof.name} a été supprimé')));
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur lors de la suppression: $e')),
//         );
//       }
//     }
//   }
// }
//
// class ProfEditScreen extends StatefulWidget {
//   final Prof? prof;
//
//   const ProfEditScreen({Key? key, this.prof}) : super(key: key);
//
//   @override
//   _ProfEditScreenState createState() => _ProfEditScreenState();
// }
//
// class _ProfEditScreenState extends State<ProfEditScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late String _name;
//   late String _email;
//   late String _phone;
//
//   @override
//   void initState() {
//     super.initState();
//     _name = widget.prof?.name ?? '';
//     _email = widget.prof?.email ?? '';
//     _phone = widget.prof?.phone ?? '';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.prof == null
//               ? 'Ajouter un professeur'
//               : 'Modifier le professeur',
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 initialValue: _name,
//                 decoration: const InputDecoration(labelText: 'Nom complet'),
//                 validator:
//                     (value) =>
//                         value?.isEmpty ?? true
//                             ? 'Ce champ est obligatoire'
//                             : null,
//                 onSaved: (value) => _name = value!,
//               ),
//               TextFormField(
//                 initialValue: _email,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
//                   if (!value!.contains('@')) return 'Email invalide';
//                   return null;
//                 },
//                 onSaved: (value) => _email = value!,
//               ),
//               TextFormField(
//                 initialValue: _phone,
//                 decoration: const InputDecoration(labelText: 'Téléphone'),
//                 keyboardType: TextInputType.phone,
//                 validator:
//                     (value) =>
//                         value?.isEmpty ?? true
//                             ? 'Ce champ est obligatoire'
//                             : null,
//                 onSaved: (value) => _phone = value!,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _saveProf,
//                 child: const Text('Enregistrer'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _saveProf() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       _formKey.currentState?.save();
//
//       final profProvider = Provider.of<ProfProvider>(context, listen: false);
//       try {
//         if (widget.prof == null) {
//           // Création d'un nouveau prof
//           final newProf = Prof(
//             id: DateTime.now().millisecondsSinceEpoch.toString(),
//             name: _name,
//             email: _email,
//             phone: _phone,
//           );
//           await profProvider.addProf(newProf);
//         } else {
//           // Mise à jour d'un prof existant
//           final updatedProf = Prof(
//             id: widget.prof!.id,
//             name: _name,
//             email: _email,
//             phone: _phone,
//           );
//           await profProvider.updateProf(updatedProf);
//         }
//
//         Navigator.pop(context);
//       } catch (e) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
//       }
//     }
//   }
// }
