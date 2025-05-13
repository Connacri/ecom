// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';
//
// import '../modèles.dart';
//
// class AddCourseScreen extends StatefulWidget {
//   final UserModel club;
//
//   const AddCourseScreen({Key? key, required this.club}) : super(key: key);
//
//   @override
//   _AddCourseScreenState createState() => _AddCourseScreenState();
// }
//
// class _AddCourseScreenState extends State<AddCourseScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _ageRangeController = TextEditingController();
//   final List<Schedule> _schedules = [];
//   final List<ImageItem> _photos = [];
//   final List<String> _selectedProfIds = [];
//   bool _isLoading = false;
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _ageRangeController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Ajouter un cours'),
//         actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveCourse)],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildPhotosSection(),
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(labelText: 'Nom du cours'),
//                 validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
//               ),
//               TextFormField(
//                 controller: _descriptionController,
//                 decoration: InputDecoration(labelText: 'Description'),
//                 maxLines: 3,
//               ),
//               TextFormField(
//                 controller: _ageRangeController,
//                 decoration: InputDecoration(
//                   labelText: 'Tranche d\'âge (ex: 5-10 ans)',
//                 ),
//               ),
//               SizedBox(height: 20),
//               _buildSchedulesSection(),
//               SizedBox(height: 20),
//               _buildProfsSection(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPhotosSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Photos du cours', style: Theme.of(context).textTheme.titleMedium),
//         SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: [
//             ..._photos.map((item) => _buildPhotoItem(item)).toList(),
//             GestureDetector(
//               onTap: _addPhoto,
//               child: Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(Icons.add_a_photo, size: 30),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPhotoItem(ImageItem item) {
//     return Stack(
//       children: [
//         Container(
//           width: 80,
//           height: 80,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             image: DecorationImage(
//               image:
//                   item.file != null
//                       ? FileImage(item.file!)
//                       : NetworkImage(item.url!) as ImageProvider,
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         Positioned(
//           top: 0,
//           right: 0,
//           child: GestureDetector(
//             onTap: () => _removePhoto(item),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.black54,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(Icons.close, color: Colors.white, size: 20),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSchedulesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Emploi du temps',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             IconButton(icon: Icon(Icons.add), onPressed: _addSchedule),
//           ],
//         ),
//         ..._schedules.map((schedule) => _buildScheduleItem(schedule)).toList(),
//       ],
//     );
//   }
//
//   Widget _buildScheduleItem(Schedule schedule) {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(12),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(child: Text('Jours: ${schedule.days.join(', ')}')),
//                 IconButton(
//                   icon: Icon(Icons.edit),
//                   onPressed: () => _editSchedule(schedule),
//                 ),
//               ],
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     'De: ${DateFormat.Hm().format(schedule.startTime)}',
//                   ),
//                 ),
//                 Expanded(
//                   child: Text('À: ${DateFormat.Hm().format(schedule.endTime)}'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProfsSection() {
//     return FutureBuilder<List<UserModel>>(
//       future: _loadClubProfs(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }
//
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Text('Aucun professeur disponible');
//         }
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Professeurs', style: Theme.of(context).textTheme.titleMedium),
//             Wrap(
//               spacing: 8,
//               children:
//                   snapshot.data!
//                       .map(
//                         (prof) => FilterChip(
//                           label: Text(prof.name),
//                           selected: _selectedProfIds.contains(prof.id),
//                           onSelected: (selected) {
//                             setState(() {
//                               if (selected) {
//                                 _selectedProfIds.add(prof.id);
//                               } else {
//                                 _selectedProfIds.remove(prof.id);
//                               }
//                             });
//                           },
//                         ),
//                       )
//                       .toList(),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<List<UserModel>> _loadClubProfs() async {
//     final snapshot =
//         await FirebaseFirestore.instance
//             .collection('profs')
//             .where('clubIds', arrayContains: widget.club.id)
//             .get();
//
//     return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), userDoc.id)).toList();
//   }
//
//   Future<void> _addPhoto() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _photos.add(ImageItem(file: File(pickedFile.path)));
//       });
//     }
//   }
//
//   void _removePhoto(ImageItem item) {
//     setState(() => _photos.remove(item));
//   }
//
//   Future<void> _addSchedule() async {
//     final result = await showDialog<Schedule>(
//       context: context,
//       builder: (context) => AddScheduleDialog(),
//     );
//
//     if (result != null) {
//       setState(() => _schedules.add(result));
//     }
//   }
//
//   void _editSchedule(Schedule schedule) async {
//     final index = _schedules.indexOf(schedule);
//     final result = await showDialog<Schedule>(
//       context: context,
//       builder: (context) => AddScheduleDialog(schedule: schedule),
//     );
//
//     if (result != null) {
//       setState(() => _schedules[index] = result);
//     }
//   }
//
//   Future<void> _saveCourse() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       // 1. Upload des photos
//       final photoUrls = await _uploadPhotos();
//
//       // 2. Création du cours
//       final newCourse = Course(
//         id: '',
//         name: _nameController.text,
//         club: widget.club,
//         description: _descriptionController.text,
//         schedules: _schedules,
//         ageRange: _ageRangeController.text,
//         profIds: _selectedProfIds,
//         createdAt: DateTime.now(),
//         editedAt: DateTime.now(),
//       );
//
//       // 3. Sauvegarde dans Firestore
//       final docRef = await FirebaseFirestore.instance
//           .collection('courses')
//           .add(newCourse.toMap());
//
//       // 4. Mise à jour du club
//       await FirebaseFirestore.instance
//           .collection('clubs')
//           .doc(widget.club.id)
//           .update({
//             'courses': FieldValue.arrayUnion([docRef.id]),
//           });
//
//       Navigator.pop(context, true);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<List<String>> _uploadPhotos() async {
//     final List<String> urls = [];
//     final storage = FirebaseStorage.instance;
//
//     for (final item in _photos) {
//       if (item.file != null) {
//         final ref = storage.ref().child(
//           'courses/${DateTime.now().millisecondsSinceEpoch}',
//         );
//         await ref.putFile(item.file!);
//         urls.add(await ref.getDownloadURL());
//       } else if (item.url != null) {
//         urls.add(item.url!);
//       }
//     }
//
//     return urls;
//   }
// }
//
// class AddScheduleDialog extends StatefulWidget {
//   final Schedule? schedule;
//
//   const AddScheduleDialog({Key? key, this.schedule}) : super(key: key);
//
//   @override
//   _AddScheduleDialogState createState() => _AddScheduleDialogState();
// }
//
// class _AddScheduleDialogState extends State<AddScheduleDialog> {
//   late TimeOfDay _startTime;
//   late TimeOfDay _endTime;
//   final List<String> _selectedDays = [];
//   final List<String> _days = [
//     'Lundi',
//     'Mardi',
//     'Mercredi',
//     'Jeudi',
//     'Vendredi',
//     'Samedi',
//     'Dimanche',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.schedule != null) {
//       _startTime = TimeOfDay.fromDateTime(widget.schedule!.startTime);
//       _endTime = TimeOfDay.fromDateTime(widget.schedule!.endTime);
//       _selectedDays.addAll(widget.schedule!.days);
//     } else {
//       _startTime = TimeOfDay(hour: 9, minute: 0);
//       _endTime = TimeOfDay(hour: 10, minute: 0);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(
//         widget.schedule == null ? 'Ajouter un horaire' : 'Modifier horaire',
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               title: Text('De ${_formatTime(_startTime)}'),
//               trailing: Icon(Icons.access_time),
//               onTap: () async {
//                 final time = await showTimePicker(
//                   context: context,
//                   initialTime: _startTime,
//                 );
//                 if (time != null) setState(() => _startTime = time);
//               },
//             ),
//             ListTile(
//               title: Text('À ${_formatTime(_endTime)}'),
//               trailing: Icon(Icons.access_time),
//               onTap: () async {
//                 final time = await showTimePicker(
//                   context: context,
//                   initialTime: _endTime,
//                 );
//                 if (time != null) setState(() => _endTime = time);
//               },
//             ),
//             Divider(),
//             Text('Jours de la semaine'),
//             Wrap(
//               spacing: 8,
//               children:
//                   _days
//                       .map(
//                         (day) => FilterChip(
//                           label: Text(day),
//                           selected: _selectedDays.contains(day),
//                           onSelected: (selected) {
//                             setState(() {
//                               if (selected) {
//                                 _selectedDays.add(day);
//                               } else {
//                                 _selectedDays.remove(day);
//                               }
//                             });
//                           },
//                         ),
//                       )
//                       .toList(),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           child: Text('Annuler'),
//           onPressed: () => Navigator.pop(context),
//         ),
//         ElevatedButton(
//           child: Text('Valider'),
//           onPressed:
//               _selectedDays.isEmpty ? null : () => _submitSchedule(context),
//         ),
//       ],
//     );
//   }
//
//   String _formatTime(TimeOfDay time) {
//     return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
//   }
//
//   void _submitSchedule(BuildContext context) {
//     final now = DateTime.now();
//     final schedule = Schedule(
//       id: widget.schedule?.id ?? Uuid().v4(),
//       startTime: DateTime(
//         now.year,
//         now.month,
//         now.day,
//         _startTime.hour,
//         _startTime.minute,
//       ),
//       endTime: DateTime(
//         now.year,
//         now.month,
//         now.day,
//         _endTime.hour,
//         _endTime.minute,
//       ),
//       days: _selectedDays,
//       createdAt: widget.schedule?.createdAt ?? DateTime.now(),
//       editedAt: DateTime.now(),
//     );
//
//     Navigator.pop(context, schedule);
//   }
// }
