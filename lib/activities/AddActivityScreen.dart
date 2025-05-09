// import 'package:flutter/material.dart';
//
// import 'modèles.dart';
//
// class AddActivityScreen extends StatefulWidget {
//   final Function(SportActivity) addActivity;
//
//   AddActivityScreen({required this.addActivity});
//
//   @override
//   _AddActivityScreenState createState() => _AddActivityScreenState();
// }
//
// class _AddActivityScreenState extends State<AddActivityScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   DateTime? _selectedDate;
//
//   void _submitForm() {
//     if (_formKey.currentState!.validate()) {
//       SportActivity newActivity = SportActivity(
//         id: DateTime.now().toString(),
//         title: _titleController.text,
//         description: _descriptionController.text,
//         date: _selectedDate!,
//         isCompleted: false,
//       );
//       widget.addActivity(newActivity);
//       Navigator.pop(context);
//     }
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Ajouter une Activité')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _titleController,
//                 decoration: InputDecoration(labelText: 'Titre'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Veuillez entrer un titre';
//                   }
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 controller: _descriptionController,
//                 decoration: InputDecoration(labelText: 'Description'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Veuillez entrer une description';
//                   }
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 readOnly: true,
//                 decoration: InputDecoration(labelText: 'Date'),
//                 onTap: () => _selectDate(context),
//                 validator: (value) {
//                   if (_selectedDate == null) {
//                     return 'Veuillez sélectionner une date';
//                   }
//                   return null;
//                 },
//                 controller: TextEditingController(
//                   text:
//                       _selectedDate == null
//                           ? ''
//                           : _selectedDate.toString().substring(0, 10),
//                 ),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(onPressed: _submitForm, child: Text('Ajouter')),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
