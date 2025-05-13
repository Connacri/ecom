import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'modèles.dart';

class ClubRegistrationScreen extends StatefulWidget {
  final UserModel? club;

  ClubRegistrationScreen({this.club});

  @override
  _ClubRegistrationScreenState createState() => _ClubRegistrationScreenState();
}

class _ClubRegistrationScreenState extends State<ClubRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _logoImage;
  List<ImageItem> _images = []; // Utilisez une seule liste pour les images
  List<Course> _courses = [];
  bool _isSubmitting = false;
  String? _logoUrl;
  bool _showAllPic = false;

  @override
  void initState() {
    super.initState();
    if (widget.club != null) {
      _nameController.text = widget.club!.name;
      _phoneController.text = widget.club!.phone!;
      _logoUrl = widget.club!.logoUrl;
      _images = widget.club!.photos!.map((url) => ImageItem(url: url)).toList();
      _courses = widget.club!.courses!;
    }
  }

  Future<void> _pickImage(ImageSource source, bool isLogo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 30);

    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = File(pickedFile.path);
        } else {
          _images.insert(
            0,
            ImageItem(file: File(pickedFile.path)),
          ); // Ajoute la nouvelle image au début de la liste
        }
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'clubs/${DateTime.now().toString()}',
      );
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Erreur d'upload : $e");
      rethrow;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true; // Show the progress indicator
      });

      try {
        String logoUrl =
            _logoImage != null ? await _uploadImage(_logoImage!) : _logoUrl!;
        List<String> photoUrls = [];
        for (var image in _images) {
          if (image.file != null) {
            photoUrls.add(await _uploadImage(image.file!));
          } else if (image.url != null) {
            photoUrls.add(image.url!);
          }
        }

        UserModel club = UserModel(
          id: widget.club?.id ?? DateTime.now().toString(),
          name: _nameController.text,
          phone: _phoneController.text,
          logoUrl: logoUrl,
          photos: photoUrls,
          courses: _courses,
          email: '',
          createdAt: null,
          lastLogin: null,
          editedAt: null,
          role: '',
        );

        if (widget.club == null) {
          // Create a new club
          await FirebaseFirestore.instance.collection('clubs').add({
            'name': club.name,
            'logoUrl': club.logoUrl,
            'photos': club.photos,
            'phone': club.phone,
            'courses':
                club.courses!
                    .map(
                      (course) => {
                        'name': course.name,
                        'description': course.description,
                        'schedules':
                            course.schedules
                                .map(
                                  (schedule) => {
                                    'startTime': schedule.startTime,
                                    'endTime': schedule.endTime,
                                    'days': schedule.days,
                                  },
                                )
                                .toList(),
                        'ageRange': course.ageRange,
                      },
                    )
                    .toList(),
          });
        } else {
          // Update the existing club
          await FirebaseFirestore.instance
              .collection('clubs')
              .doc(widget.club!.id)
              .update({
                'name': club.name,
                'phone': club.phone,
                'logoUrl': club.logoUrl,
                'photos': club.photos,
                'courses':
                    club.courses!
                        .map(
                          (course) => {
                            'name': course.name,
                            'description': course.description,
                            'schedules':
                                course.schedules
                                    .map(
                                      (schedule) => {
                                        'startTime': schedule.startTime,
                                        'endTime': schedule.endTime,
                                        'days': schedule.days,
                                      },
                                    )
                                    .toList(),
                            'ageRange': course.ageRange,
                          },
                        )
                        .toList(),
              });
        }

        Navigator.pop(context);
      } catch (e) {
        print("Error submitting form: $e");
      } finally {
        setState(() {
          _isSubmitting = false; // Hide the progress indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.club == null ? 'Inscription du Club' : 'Modifier le Club',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nom du Club'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'Numéro de tel'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un Numéro de tel';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery, true),
                  child: Stack(
                    children: [
                      _logoImage == null && _logoUrl == null
                          ? Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Icon(Icons.add_a_photo),
                          )
                          : _logoImage != null
                          ? Image.file(
                            _logoImage!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                          : Image.network(
                            _logoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                      if (_logoImage != null || _logoUrl != null)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _logoImage = null;
                                _logoUrl = null;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery, false),
                  child: Text('Ajouter des Photos'),
                ),
                SizedBox(height: 20),
                Stack(
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          _images
                              .take(_showAllPic ? _images.length : 3)
                              .map(
                                (image) => SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child:
                                            image.file != null
                                                ? Image.file(
                                                  image.file!,
                                                  fit: BoxFit.cover,
                                                  width: 100,
                                                  height: 100,
                                                )
                                                : Image.network(
                                                  image.url!,
                                                  fit: BoxFit.cover,
                                                  width: 100,
                                                  height: 100,
                                                ),
                                      ),
                                      Positioned(
                                        right: 5,
                                        top: 5,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _images.remove(image);
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                3.0,
                                              ),
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!_showAllPic &&
                                          _images.indexOf(image) == 2)
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _showAllPic = true;
                                                });
                                              },
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                    if (_showAllPic && _images.length > 3)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAllPic = false;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                top: 120,
                              ), // Ajustez cette valeur selon vos besoins
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.remove, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                _isSubmitting
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(
                        widget.club == null ? 'Soumettre' : 'Mettre à jour',
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class _ClubRegistrationScreenState extends State<ClubRegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   File? _logoImage;
//   List<File> _photos = [];
//   List<Course> _courses = [];
//   bool _isSubmitting = false;
//   String? _logoUrl;
//   List<String> _photoUrls = [];
//   bool _showAllPic = false;
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.club != null) {
//       _nameController.text = widget.club!.name;
//       _phoneController.text = widget.club!.phone;
//       _logoUrl = widget.club!.logoUrl;
//       _photoUrls = widget.club!.photos;
//       _courses = widget.club!.courses;
//     }
//   }
//
//   Future<void> _pickImage(ImageSource source, bool isLogo) async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: source, imageQuality: 30);
//
//     if (pickedFile != null) {
//       setState(() {
//         if (isLogo) {
//           _logoImage = File(pickedFile.path);
//         } else {
//           _photos.insert(
//             0,
//             File(pickedFile.path),
//           ); // Ajoute la nouvelle image au début de la liste
//         }
//       });
//     }
//   }
//
//   Future<String> _uploadImage(File image) async {
//     try {
//       final ref = FirebaseStorage.instance.ref().child(
//         'clubs/${DateTime.now().toString()}',
//       );
//       final uploadTask = ref.putFile(image);
//       final snapshot = await uploadTask;
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       print("Erreur d'upload : $e");
//       rethrow;
//     }
//   }
//
//   void _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isSubmitting = true; // Show the progress indicator
//       });
//
//       try {
//         String logoUrl =
//             _logoImage != null ? await _uploadImage(_logoImage!) : _logoUrl!;
//         List<String> photoUrls = _photoUrls;
//         if (_photos.isNotEmpty) {
//           photoUrls = await Future.wait(
//             _photos.map((photo) => _uploadImage(photo)).toList(),
//           );
//         }
//
//         Club club = Club(
//           id: widget.club?.id ?? DateTime.now().toString(),
//           name: _nameController.text,
//           phone: _phoneController.text,
//           logoUrl: logoUrl,
//           photos: photoUrls,
//           courses: _courses,
//         );
//
//         if (widget.club == null) {
//           // Create a new club
//           await FirebaseFirestore.instance.collection('clubs').add({
//             'name': club.name,
//             'logoUrl': club.logoUrl,
//             'photos': club.photos,
//             'phone': club.phone,
//             'courses':
//                 club.courses
//                     .map(
//                       (course) => {
//                         'name': course.name,
//                         'description': course.description,
//                         'schedules':
//                             course.schedules
//                                 .map(
//                                   (schedule) => {
//                                     'startTime': schedule.startTime,
//                                     'endTime': schedule.endTime,
//                                     'days': schedule.days,
//                                   },
//                                 )
//                                 .toList(),
//                         'ageRange': course.ageRange,
//                       },
//                     )
//                     .toList(),
//           });
//         } else {
//           // Update the existing club
//           await FirebaseFirestore.instance
//               .collection('clubs')
//               .doc(widget.club!.id)
//               .update({
//                 'name': club.name,
//                 'phone': club.phone,
//                 'logoUrl': club.logoUrl,
//                 'photos': club.photos,
//                 'courses':
//                     club.courses
//                         .map(
//                           (course) => {
//                             'name': course.name,
//                             'description': course.description,
//                             'schedules':
//                                 course.schedules
//                                     .map(
//                                       (schedule) => {
//                                         'startTime': schedule.startTime,
//                                         'endTime': schedule.endTime,
//                                         'days': schedule.days,
//                                       },
//                                     )
//                                     .toList(),
//                             'ageRange': course.ageRange,
//                           },
//                         )
//                         .toList(),
//               });
//         }
//
//         Navigator.pop(context);
//       } catch (e) {
//         print("Error submitting form: $e");
//       } finally {
//         setState(() {
//           _isSubmitting = false; // Hide the progress indicator
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.club == null ? 'Inscription du Club' : 'Modifier le Club',
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: InputDecoration(labelText: 'Nom du Club'),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Veuillez entrer un nom';
//                     }
//                     return null;
//                   },
//                 ),
//                 TextFormField(
//                   controller: _phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: InputDecoration(labelText: 'Numéro de tel'),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Veuillez entrer un Numéro de tel';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 GestureDetector(
//                   onTap: () => _pickImage(ImageSource.gallery, true),
//                   child: Stack(
//                     children: [
//                       _logoImage == null && _logoUrl == null
//                           ? Container(
//                             width: 100,
//                             height: 100,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.grey),
//                             ),
//                             child: Icon(Icons.add_a_photo),
//                           )
//                           : _logoImage != null
//                           ? Image.file(
//                             _logoImage!,
//                             width: 100,
//                             height: 100,
//                             fit: BoxFit.cover,
//                           )
//                           : Image.network(
//                             _logoUrl!,
//                             width: 100,
//                             height: 100,
//                             fit: BoxFit.cover,
//                           ),
//                       if (_logoImage != null || _logoUrl != null)
//                         Positioned(
//                           right: 10,
//                           top: 10,
//                           child: GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 _logoImage = null;
//                                 _logoUrl = null;
//                               });
//                             },
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(3.0),
//                                 child: Icon(
//                                   Icons.delete,
//                                   color: Colors.white,
//                                   size: 20,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () => _pickImage(ImageSource.gallery, false),
//                   child: Text('Ajouter des Photos'),
//                 ),
//                 SizedBox(height: 20),
//
//                 Stack(
//                   children: [
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 10,
//                       children:
//                           (_photos.isEmpty ? _photoUrls : _photos)
//                               .take(
//                                 _showAllPic
//                                     ? (_photos.isEmpty
//                                         ? _photoUrls.length
//                                         : _photos.length)
//                                     : 3,
//                               )
//                               .map(
//                                 (photo) => SizedBox(
//                                   width: 100,
//                                   height: 100,
//                                   child: Stack(
//                                     children: [
//                                       AspectRatio(
//                                         aspectRatio: 1,
//                                         child:
//                                             photo is File
//                                                 ? Image.file(
//                                                   photo,
//                                                   fit: BoxFit.cover,
//                                                   width: 100,
//                                                   height: 100,
//                                                 )
//                                                 : Image.network(
//                                                   photo as String,
//                                                   fit: BoxFit.cover,
//                                                   width: 100,
//                                                   height: 100,
//                                                 ),
//                                       ),
//                                       Positioned(
//                                         right: 10,
//                                         top: 10,
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             setState(() {
//                                               if (photo is File) {
//                                                 _photos.remove(photo);
//                                               } else {
//                                                 _photoUrls.remove(photo);
//                                               }
//                                             });
//                                           },
//                                           child: Container(
//                                             decoration: BoxDecoration(
//                                               color: Colors.red,
//                                               shape: BoxShape.circle,
//                                             ),
//                                             child: Padding(
//                                               padding: const EdgeInsets.all(
//                                                 3.0,
//                                               ),
//                                               child: Icon(
//                                                 Icons.delete,
//                                                 color: Colors.white,
//                                                 size: 20,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               )
//                               .toList(),
//                     ),
//                     if ((_photos.isEmpty ? _photoUrls.length : _photos.length) >
//                             3 &&
//                         !_showAllPic)
//                       Center(
//                         child: GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               _showAllPic = true;
//                             });
//                           },
//                           child: Container(
//                             width: 30,
//                             height: 30,
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.5),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(3.0),
//                               child: Icon(Icons.add, color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//
//                 SizedBox(height: 20),
//                 _isSubmitting
//                     ? Center(child: CircularProgressIndicator())
//                     : ElevatedButton(
//                       onPressed: _submitForm,
//                       child: Text(
//                         widget.club == null ? 'Soumettre' : 'Mettre à jour',
//                       ),
//                     ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
