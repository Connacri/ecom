import 'package:ecom/activities/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'modèles.dart';

class AddChildScreen extends StatefulWidget {
  final UserModel parent;
  final Child? child; // Optional child parameter for editing

  const AddChildScreen({Key? key, required this.parent, this.child})
    : super(key: key);

  @override
  _AddChildScreenState createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill the form fields
    if (widget.child != null) {
      _nameController.text = widget.child!.name;
      _ageController.text = widget.child!.age.toString();
      _selectedGender = widget.child!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.parent.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un parent')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un genre')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final child = Child(
        id: widget.child?.id ?? '', // Use existing ID if editing
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        enrolledCourses: widget.child?.enrolledCourses ?? [],
        parentId: widget.parent.id,
        gender: _selectedGender!,
      );

      if (widget.child == null) {
        // Add new child
        await context.read<ClubProvider>().addChild(child);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${child.name} a été ajouté(e)')),
          );
        }
      } else {
        // Update existing child
        await context.read<ClubProvider>().updateChild(child);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${child.name} a été mis(e) à jour')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.child == null ? 'Ajouter un Enfant' : 'Modifier un Enfant',
        ),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${widget.parent.name}',
                    style: const TextStyle(fontSize: 30),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  if (value.trim().length < 2) {
                    return 'Le nom doit contenir au moins 2 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Âge',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un âge';
                  }
                  final age = int.tryParse(value);
                  if (age == null) {
                    return 'Âge invalide';
                  }
                  if (age < 1 || age > 18) {
                    return 'Âge doit être entre 1 et 18';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('Male'),
                value: 'male',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Female'),
                value: 'female',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : Text(
                          widget.child == null
                              ? 'AJOUTER L\'ENFANT'
                              : 'MISE À JOUR',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
