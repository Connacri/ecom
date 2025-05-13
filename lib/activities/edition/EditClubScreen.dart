import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../modèles.dart';

class EditClubScreen extends StatefulWidget {
  final UserModel club;

  const EditClubScreen({Key? key, required this.club}) : super(key: key);

  @override
  _EditClubScreenState createState() => _EditClubScreenState();
}

class _EditClubScreenState extends State<EditClubScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  List<XFile> _selectedPhotos = [];
  XFile? _selectedLogo;

  late String _selectedRole;

  List<String> getAvailableRoles(String initialRole) {
    switch (initialRole) {
      case 'club':
      case 'association':
      case 'ecole':
        return ['club', 'association', 'ecole'];
      default:
        return lesRoles
            .where(
              (role) =>
                  role != 'club' && role != 'association' && role != 'ecole',
            )
            .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.club.role;
    _nameController = TextEditingController(text: widget.club.name);
    _emailController = TextEditingController(text: widget.club.email);
    _phoneController = TextEditingController(text: widget.club.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedLogo = image;
      });
    }
  }

  Future<void> _pickPhotos() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? images = await _picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _selectedPhotos = images;
      });
    }
  }

  Future<String> _uploadImage(XFile image, String path) async {
    final FirebaseStorage _storage = FirebaseStorage.instance;
    final Reference ref = _storage.ref().child(path);
    await ref.putFile(File(image.path));
    return await ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? logoUrl;
        if (_selectedLogo != null) {
          logoUrl = await _uploadImage(
            _selectedLogo!,
            'logos/${widget.club.id}',
          );
        }

        List<String> photoUrls = [];
        for (var photo in _selectedPhotos) {
          String url = await _uploadImage(
            photo,
            'photos/${widget.club.id}/${DateTime.now().millisecondsSinceEpoch}',
          );
          photoUrls.add(url);
        }

        await FirebaseFirestore.instance
            .collection('userModel')
            .doc(widget.club.id)
            .update({
              'name': _nameController.text,
              'email': _emailController.text,
              'phone': _phoneController.text,
              'logoUrl': logoUrl,
              'photos': photoUrls,
            });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Club mis à jour avec succès')));

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRoles = getAvailableRoles(widget.club.role);
    return Scaffold(
      appBar: AppBar(title: Text('Modifier le Club')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du Club',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du club';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le numéro de téléphone';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              DropdownButton<String>(
                value: _selectedRole,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                items:
                    availableRoles.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Handle role update logic here
                  print('Selected Role: $_selectedRole');
                },
                child: Text('Mettre à jour le Rôle'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickLogo,
                child: Text('Sélectionner un Logo'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              if (_selectedLogo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(
                    File(_selectedLogo!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickPhotos,
                child: Text('Sélectionner des Photos'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              if (_selectedPhotos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Image.file(
                          File(_selectedPhotos[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Mettre à jour'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
