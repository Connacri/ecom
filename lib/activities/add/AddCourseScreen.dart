import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/activities/data_populator.dart';
import 'package:ecom/pages/MyApp.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../modèles.dart';
import '../providers.dart';

class AddCourseScreen2 extends StatefulWidget {
  final UserModel user;

  const AddCourseScreen2({Key? key, required this.user}) : super(key: key);
  @override
  _AddCourseScreen2State createState() => _AddCourseScreen2State();
}

class _AddCourseScreen2State extends State<AddCourseScreen2> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeNumberController = TextEditingController();
  RangeValues _ageRange = const RangeValues(5, 18);
  String? _ageRangeError;
  List<String> _photos = [];
  // List<String> _profIds = [];
  List<String> _coachIds = [];
  List<Schedule> _schedules = [];
  UserModel? _selectedClub;
  final _profSearchController = TextEditingController();
  final _newProfNameController = TextEditingController();
  final _newProfEmailController = TextEditingController();

  List<UserModel> _availableProfs = [];
  List<UserModel> _filteredProfs = [];
  List<UserModel> _selectedProfs = [];
  bool _isLoading = true;
  bool _showAddProfForm = false;
  bool _showAllPhotos = false;

  // Variables à ajouter dans votre classe State
  String _selectedRole = 'professeur'; // Valeur par défaut
  final List<String> _roles = [
    'professeur',
    'coach',
    'entraineur',
    'instructeur',
    'moniteur',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfsList();
    _profSearchController.addListener(filterProfs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfProvider>(
        context,
        listen: false,
      ).fetchProfessorsFromFirestore();
    });
  }

  Future<void> _loadProfsList() async {
    setState(() => _isLoading = true);

    try {
      // // Récupérer les clubs
      // final clubsQuery = FirebaseFirestore.instance
      //     .collection('userModel')
      //     .where('role', isEqualTo: 'club');
      //
      // Liste des rôles de professeur
      List<String> professeurRoles = [
        'professeur',
        'prof',
        'enseignant suppléant',
        'conseiller pédagogique',
        'éducateur',
        'formateur',
        'coach',
        'animateur',
        'moniteur',
        'intervenant extérieur',
        'médiateur',
        'tuteur',
      ];

      // Récupérer les professeurs
      List<UserModel> profs = [];
      for (String role in professeurRoles) {
        final profsQuery = FirebaseFirestore.instance
            .collection('userModel')
            .where('role', isEqualTo: role);

        final profsSnapshot = await profsQuery.get();
        profs.addAll(
          profsSnapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
      }

      // // Récupérer les clubs
      // final clubsSnapshot = await clubsQuery.get();
      // final clubs =
      //     clubsSnapshot.docs
      //         .map((doc) => UserModel.fromMap(doc.data(), doc.id))
      //         .toList();

      setState(() {
        _availableProfs = profs;
        _filteredProfs = profs;
        //  _selectedClub = clubs.isNotEmpty ? clubs.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
      );
      debugPrint('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _addNewProf() async {
    final name = _newProfNameController.text.trim();
    final email = _newProfEmailController.text.trim();
    final role = _selectedRole;

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      //  setState(() => _isLoading = true);
      final profId = Uuid().v4();

      final newProf = UserModel(
        id: profId,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        editedAt: DateTime.now(),
        photos: [],
      );

      await FirebaseFirestore.instance
          .collection('userModel')
          .doc(profId)
          .set(newProf.toMap());

      Provider.of<ProfProvider>(context, listen: false).addProfessor(newProf);

      setState(() {
        _selectedProfs.add(
          newProf,
        ); // Add the new professor to the _selectedProfs list
        // _profIds.add(newProf.id);
        _newProfNameController.clear();
        _newProfEmailController.clear();
        _showAddProfForm = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: ${e.toString()}')),
      );
      debugPrint('Erreur création Coach/Professeur: $e');
    }
  }

  void _toggleProfSelection(UserModel prof) {
    setState(() {
      _selectedProfs.contains(prof)
          ? _selectedProfs.remove(prof)
          : _selectedProfs.add(prof);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Schedule the call to clearcorses after the build phase is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider2>(context, listen: false).clearcorses();
    });
  }

  final debutController = TextEditingController();
  final finController = TextEditingController();
  final saisonFormKey = GlobalKey<FormState>();

  DateTime? get dateDebut {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(debutController.text);
    } catch (_) {
      return null;
    }
  }

  DateTime? get dateFin {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(finController.text);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un cours')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 5) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              if (_formKey.currentState!.validate()) {
                // Sauvegarder le cours dans Firestore
                _saveCourse();
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: [
            Step(
              title:
              // _currentStep > 0
              //     ? SizedBox.shrink() //Icon(Icons.edit, color: Colors.grey)
              //     :
              Text('Informations de base'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _courseNameController,
                    decoration: InputDecoration(labelText: 'Nom du cours'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom de cours';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _placeNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Nombre de Place'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le Nombre de Place';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tranche d'âge*",
                              style: TextStyle(fontSize: 16),
                            ),
                            if (_ageRangeError != null)
                              Text(
                                _ageRangeError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            else
                              Text(
                                'De ${_ageRange.start.round()} à ${_ageRange.end.round()} ans',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      RangeSlider(
                        values: _ageRange,
                        min: 3,
                        max: 18,
                        divisions: 15,
                        labels: RangeLabels(
                          '${_ageRange.start.round()} ans',
                          '${_ageRange.end.round()} ans',
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _ageRange = values;
                            _ageRangeError = null;
                          });
                        },
                        onChangeEnd: (values) {
                          if (values.end - values.start < 1) {
                            setState(() {
                              _ageRangeError =
                                  'La plage doit être d\'au moins 1 an';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Photos des Cours'),
              content: ImageStep(
                photos: _photos,
                onImageAdded: (path) {
                  setState(() {
                    _photos.add(path);
                  });
                },
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Professeurs / Coachs'),
              content: Column(
                children: [
                  TextField(
                    controller: _profSearchController,
                    onChanged:
                        (value) => filterProfsWithDebounce(), // Avec debounce
                    // ou
                    //  onChanged: (value) => filterProfs(), // Version directe
                    decoration: InputDecoration(
                      hintText:
                          'Rechercher par nom, email, rôle ou initiales...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => setState(
                          () => _showAddProfForm = !_showAddProfForm,
                        ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showAddProfForm ? Icons.remove : Icons.add,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _showAddProfForm
                                ? 'Masquer le formulaire'
                                : 'Ajouter un nouveau Coach',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showAddProfForm) ...[
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _newProfNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du Coach/Professeur*',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Ce champ est obligatoire'
                                  : null,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _newProfEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email du Coach/Professeur*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Ce champ est obligatoire'
                                  : null,
                    ),
                    SizedBox(height: 8),
                    SizedBox(height: 12),

                    // Dropdown pour le rôle
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      items:
                          _roles.map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(
                                role.substring(0, 1).toUpperCase() +
                                    role.substring(1),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addNewProf,
                      child: Text('Enregistrer le Coach/Professeur'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Affichage des profs filtrés
                  Consumer<ProfProvider>(
                    builder: (context, professorsProvider, child) {
                      final profsToShow =
                          _filteredProfs.isEmpty
                              ? professorsProvider.professors
                              : _filteredProfs;

                      if (profsToShow.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Aucun Coach/Professeur trouvé',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      } else {
                        return Column(
                          children:
                              profsToShow.take(3).map((prof) {
                                final isSelected = _selectedProfs.contains(
                                  prof,
                                );
                                return CheckboxListTile(
                                  title: Text(
                                    prof.role.capitalize() +
                                        ' ' +
                                        prof.name.capitalize(),
                                  ),
                                  subtitle: Text(prof.email),
                                  value: isSelected,
                                  onChanged: (_) => _toggleProfSelection(prof),
                                );
                              }).toList(),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  if (_selectedProfs.isNotEmpty) ...[
                    // Text(
                    //   'Coachs/Professeurs sélectionnés:',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    Wrap(
                      spacing: 8,
                      children:
                          _selectedProfs.map((prof) {
                            return Chip(
                              avatar:
                                  prof.logoUrl != null
                                      ? CircleAvatar(
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                              prof.logoUrl!,
                                            ),
                                      )
                                      : CircleAvatar(child: Icon(Icons.person)),
                              label: Text(prof.name),
                              deleteIcon: Icon(Icons.close, size: 18),
                              onDeleted: () => _toggleProfSelection(prof),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 20),
                  ],
                ],
              ),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Les Jours & Horaires'),
              content: Column(
                children: [
                  ElevatedButton(
                    onPressed: _addSchedule,
                    child: Text('Ajouter un horaire'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Consumer<CourseProvider2>(
                    builder: (context, provider, child) {
                      if (provider.schedules.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            Text(
                              'Horaires ajoutés:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            ...provider.schedules.map((schedule) {
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  onLongPress:
                                      () => provider.removeSchedule(schedule),
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${DateFormat.Hm().format(schedule.startTime)}',
                                      ),
                                      Text(
                                        '${DateFormat.Hm().format(schedule.endTime)}',
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    schedule.days.join(", "),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  // subtitle: Text(
                                  //   '${DateFormat.Hm().format(schedule.startTime)} - ${DateFormat.Hm().format(schedule.endTime)}',
                                  // ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed:
                                        () => provider.removeSchedule(schedule),
                                  ),
                                ),
                              );
                            }).toList(),
                            SizedBox(height: 20),
                          ],
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                  // ListView.builder(
                  //   shrinkWrap: true,
                  //   itemCount: _schedules.length,
                  //   itemBuilder: (context, index) {
                  //     return ListTile(
                  //       title: Text(
                  //         'Horaire ${_schedules[index].days.join(', ')}',
                  //       ),
                  //     );
                  //   },
                  // ),
                  // ElevatedButton(
                  //   onPressed: _addSchedule,
                  //   child: Text('Ajouter un horaire'),
                  // ),
                ],
              ),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Saison'),
              content: Column(
                children: [
                  SaisonForm(
                    debutController: debutController,
                    finController: finController,
                    formKey: saisonFormKey,
                  ),
                ],
              ),
              isActive: _currentStep >= 4,
              state: _currentStep > 4 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('Aperçu'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nom du cours: ${_courseNameController.text}'),
                  Text('Description: ${_descriptionController.text}'),
                  Text('Nombre de Place: ${_placeNumberController.text}'),
                  Text(
                    'Tranche d\'âge: ${_ageRange.start.round()} - ${_ageRange.end.round()} ans',
                  ),

                  // Affichage des photos
                  SizedBox(height: 20),
                  Text(
                    'Photos des cours:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        _photos.map((photo) {
                          return Stack(
                            children: [
                              Image.file(
                                File(photo),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              // Positioned(
                              //   right: 0,
                              //   child: IconButton(
                              //     icon: Icon(
                              //       Icons.remove_circle,
                              //       color: Colors.red,
                              //     ),
                              //     onPressed: () {
                              //       setState(() {
                              //         _photos.remove(photo);
                              //       });
                              //     },
                              //   ),
                              // ),
                            ],
                          );
                        }).toList(),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_a_photo, color: Colors.black),
                    onPressed: () {
                      // Logique pour ajouter une photo
                    },
                  ),

                  // Affichage des professeurs
                  SizedBox(height: 20),
                  Text(
                    'Professeurs:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        _selectedProfs.map((prof) {
                          return Chip(
                            label: Text(prof.name),
                            deleteIcon: Icon(Icons.close, size: 18),
                            onDeleted: () => _toggleProfSelection(prof),
                          );
                        }).toList(),
                  ),

                  // Affichage des horaires
                  SizedBox(height: 20),
                  Text(
                    'Horaires:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Consumer<CourseProvider2>(
                    builder: (context, provider, child) {
                      if (provider.schedules.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            Text(
                              'Horaires ajoutés:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            ...provider.schedules.map((schedule) {
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    schedule.days.join(", "),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${DateFormat.Hm().format(schedule.startTime)} - ${DateFormat.Hm().format(schedule.endTime)}',
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed:
                                        () => provider.removeSchedule(schedule),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),

                  // Bouton pour sauvegarder
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveCourse,
                    child: Text('Submit to Storage'),
                  ),
                ],
              ),
              isActive: _currentStep >= 5,
              state: _currentStep > 5 ? StepState.complete : StepState.indexed,
            ),
          ],
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Row(
              children: <Widget>[
                if (_currentStep != 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Retour'),
                  ),
                TextButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 5 ? 'Terminer' : 'Suivant'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _addSchedule() {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final selectedDays = <String>{};
    final availableDays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: FittedBox(child: Text('Ajouter les Jours & horaire')),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Jours:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children:
                              availableDays.map((day) {
                                return FilterChip(
                                  label: Text(day),
                                  selected: selectedDays.contains(day),
                                  onSelected:
                                      (selected) => setState(() {
                                        selected
                                            ? selectedDays.add(day)
                                            : selectedDays.remove(day);
                                      }),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: startTimeController,
                          decoration: InputDecoration(
                            labelText: 'Heure de début',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                startTime = time;
                                startTimeController.text =
                                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: endTimeController,
                          decoration: InputDecoration(
                            labelText: 'Heure de fin',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final initialTime =
                                startTime != null
                                    ? TimeOfDay(
                                      hour: startTime!.hour + 1,
                                      minute: startTime!.minute,
                                    )
                                    : TimeOfDay.now();
                            final time = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );
                            if (time != null) {
                              setState(() {
                                endTime = time;
                                endTimeController.text =
                                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedDays.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sélectionnez au moins un jour'),
                            ),
                          );
                          return;
                        }
                        if (startTime == null || endTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sélectionnez les heures')),
                          );
                          return;
                        }

                        final newSchedule = Schedule(
                          id: Uuid().v4(),
                          startTime: DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            startTime!.hour,
                            startTime!.minute,
                          ),
                          endTime: DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            endTime!.hour,
                            endTime!.minute,
                          ),
                          days: selectedDays.toList(),
                          createdAt: DateTime.now(),
                        );

                        Provider.of<CourseProvider2>(
                          context,
                          listen: false,
                        ).addSchedule(newSchedule);

                        Navigator.pop(context);
                      },
                      child: Text('Ajouter'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _saveCourse() async {
    final courseProvider = Provider.of<CourseProvider2>(context, listen: false);
    // Afficher un indicateur de progression
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator(color: Colors.teal));
      },
    );

    try {
      List<String> photoUrls = [];

      // Téléchargez les images sur Firebase Storage et obtenez les URLs
      for (var photo in _photos) {
        if (!photo.startsWith('http')) {
          // Compresser l'image en WebP avant l'upload
          final compressedImageBytes = await _compressImageToWebP(photo);

          if (compressedImageBytes != null) {
            // Créer une référence avec extension .webp
            final ref = firebase_storage.FirebaseStorage.instance.ref().child(
              'course_photos/${DateTime.now().millisecondsSinceEpoch}.webp',
            );

            // Upload des bytes compressés
            await ref.putData(
              compressedImageBytes,
              firebase_storage.SettableMetadata(contentType: 'image/webp'),
            );

            final url = await ref.getDownloadURL();
            photoUrls.add(url);
          } else {
            // Si la compression échoue, utiliser l'image originale
            final file = File(photo);
            final ref = firebase_storage.FirebaseStorage.instance.ref().child(
              'course_photos/${DateTime.now().millisecondsSinceEpoch}',
            );
            await ref.putFile(file);
            final url = await ref.getDownloadURL();
            photoUrls.add(url);
          }
        } else {
          photoUrls.add(photo);
        }
      }

      final docRef = FirebaseFirestore.instance.collection('courses').doc();

      final course = Course(
        id: docRef.id,
        name: _courseNameController.text,
        clubId: widget.user.id,
        description: _descriptionController.text,
        schedules: courseProvider.schedules,
        ageRange: '${_ageRange.start.round()}-${_ageRange.end.round()}',
        profIds: _selectedProfs.map((user) => user.id).toList(),
        photos: photoUrls,
        placeNumber: int.parse(_placeNumberController.text),
        createdAt: DateTime.now(),
        saisonStart: DateFormat('dd/MM/yyyy').parseStrict(debutController.text),
        saisonEnd: DateFormat('dd/MM/yyyy').parseStrict(finController.text),
      );

      // Sauvegarder le cours
      await docRef.set(course.toMap());

      await FirebaseFirestore.instance
          .collection('userModel')
          .doc(widget.user.id)
          .set({
            'courses': FieldValue.arrayUnion([course.id]),
          }, SetOptions(merge: true));

      // Fermer l'indicateur de progression
      Navigator.of(context).pop();

      // Afficher un message de succès
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cours sauvegardé avec succès!')));

      // Naviguer vers l'écran d'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp1()),
      );
    } catch (e) {
      // Fermer l'indicateur de progression en cas d'erreur
      Navigator.of(context).pop();

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
        ),
      );
    }
  }

  // Méthode pour compresser l'image en WebP
  Future<Uint8List?> _compressImageToWebP(String imagePath) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        format: CompressFormat.heic,
        quality: 85, // Qualité élevée (0-100, 85 est un bon compromis)
        minWidth: 800, // Largeur minimale
        minHeight: 600, // Hauteur minimale
        keepExif:
            false, // Supprimer les métadonnées EXIF pour réduire la taille
      );

      return compressedBytes;
    } catch (e) {
      print('Erreur lors de la compression: $e');
      return null;
    }
  }

  void filterProfs() {
    final query = _profSearchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredProfs = List.from(_availableProfs);
        return;
      }

      _filteredProfs =
          _availableProfs.where((prof) {
            // Recherche fuzzy - Score de pertinence
            double score = 0.0;

            final name = prof.name.toLowerCase();
            final email = prof.email.toLowerCase();
            final role = prof.role?.toLowerCase() ?? '';

            // 1. Correspondance exacte (score maximum)
            if (name == query || email == query || role == query) {
              score += 100;
            }

            // 2. Commence par la requête (score élevé)
            if (name.startsWith(query)) score += 80;
            if (email.startsWith(query)) score += 70;
            if (role.startsWith(query)) score += 60;

            // 3. Contient la requête (score moyen)
            if (name.contains(query)) score += 50;
            if (email.contains(query)) score += 40;
            if (role.contains(query)) score += 30;

            // 4. Recherche par mots-clés séparés
            final queryWords = query
                .split(' ')
                .where((word) => word.isNotEmpty);
            for (String word in queryWords) {
              if (name.contains(word)) score += 25;
              if (email.contains(word)) score += 20;
              if (role.contains(word)) score += 15;
            }

            // 5. Recherche floue (caractères similaires)
            score += _calculateFuzzyScore(name, query) * 10;
            score += _calculateFuzzyScore(email, query) * 8;

            // 6. Recherche par initiales
            if (_matchesInitials(name, query)) score += 35;

            return score > 0;
          }).toList();

      // Trier par pertinence (optionnel - nécessite de stocker le score)
      _sortByRelevance(query);
    });
  }

  // Calcul du score de similarité floue (Levenshtein distance simplifiée)
  double _calculateFuzzyScore(String text, String query) {
    if (text.length < query.length) return 0.0;

    int matches = 0;
    int queryIndex = 0;

    for (int i = 0; i < text.length && queryIndex < query.length; i++) {
      if (text[i] == query[queryIndex]) {
        matches++;
        queryIndex++;
      }
    }

    return matches / query.length;
  }

  // Vérification des initiales (ex: "jd" pour "Jean Dupont")
  bool _matchesInitials(String name, String query) {
    final nameParts = name.split(' ');
    if (nameParts.length < 2 || query.length < 2) return false;

    final initials = nameParts
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join('');
    return initials.toLowerCase().startsWith(query);
  }

  // Tri par pertinence (version avancée)
  void _sortByRelevance(String query) {
    _filteredProfs.sort((a, b) {
      double scoreA = _calculateRelevanceScore(a, query);
      double scoreB = _calculateRelevanceScore(b, query);
      return scoreB.compareTo(scoreA); // Tri décroissant
    });
  }

  // Calcul détaillé du score de pertinence
  double _calculateRelevanceScore(UserModel prof, String query) {
    double score = 0.0;

    final name = prof.name.toLowerCase();
    final email = prof.email.toLowerCase();
    final role = prof.role?.toLowerCase() ?? '';

    // Pondération selon l'importance du champ
    if (name.startsWith(query))
      score += 100;
    else if (name.contains(query))
      score += 60;

    if (email.startsWith(query))
      score += 80;
    else if (email.contains(query))
      score += 40;

    if (role.startsWith(query))
      score += 70;
    else if (role.contains(query))
      score += 30;

    // Bonus pour les correspondances courtes (plus précises)
    if (name.length <= query.length + 3 && name.contains(query)) score += 20;

    // Bonus pour les initiales
    if (_matchesInitials(name, query)) score += 25;

    // Score fuzzy
    score += _calculateFuzzyScore(name, query) * 15;

    return score;
  }

  // Version alternative avec debounce pour de meilleures performances
  Timer? _debounceTimer;

  void filterProfsWithDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      filterProfs();
    });
  }

  // Méthode pour recherche avancée avec filtres multiples
  void advancedFilterProfs({
    String? nameQuery,
    String? emailQuery,
    String? roleFilter,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) {
    setState(() {
      _filteredProfs =
          _availableProfs.where((prof) {
            // Filtre par nom
            if (nameQuery != null && nameQuery.isNotEmpty) {
              if (!prof.name.toLowerCase().contains(nameQuery.toLowerCase())) {
                return false;
              }
            }

            // Filtre par email
            if (emailQuery != null && emailQuery.isNotEmpty) {
              if (!prof.email.toLowerCase().contains(
                emailQuery.toLowerCase(),
              )) {
                return false;
              }
            }

            // Filtre par rôle
            if (roleFilter != null &&
                roleFilter.isNotEmpty &&
                roleFilter != 'Tous') {
              if (prof.role?.toLowerCase() != roleFilter.toLowerCase()) {
                return false;
              }
            }

            // Filtre par date de création
            if (createdAfter != null) {
              if (prof.createdAt!.isBefore(createdAfter)) {
                return false;
              }
            }

            if (createdBefore != null) {
              if (prof.createdAt!.isAfter(createdBefore)) {
                return false;
              }
            }

            return true;
          }).toList();

      // Trier par pertinence si une recherche textuelle est active
      if (nameQuery?.isNotEmpty == true) {
        _sortByRelevance(nameQuery!);
      }
    });
  }
}

class ImageStep extends StatefulWidget {
  final List<String> photos;
  final Function(String) onImageAdded;

  ImageStep({required this.photos, required this.onImageAdded});

  @override
  _ImageStepState createState() => _ImageStepState();
}

class _ImageStepState extends State<ImageStep> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(spacing: 8.0, runSpacing: 8.0, children: _buildPhotoWidgets()),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.add_a_photo, color: Colors.black),
              onPressed: _pickImages,
            ),
            SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.black),
              onPressed: _takePhoto,
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildPhotoWidgets() {
    List<Widget> photoWidgets = [];

    int displayCount =
        _expanded
            ? widget.photos.length
            : (widget.photos.length > 4 ? 4 : widget.photos.length);

    for (int index = 0; index < displayCount; index++) {
      if (index == 3 && !_expanded && widget.photos.length > 4) {
        photoWidgets.add(
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 32) / 3,
                  height: 100,
                  child: Image.file(
                    File(widget.photos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Text(
                    '+${widget.photos.length - 3}',
                    style: TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (index == widget.photos.length - 1 && _expanded) {
        photoWidgets.add(
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = false;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 32) / 3,
                  height: 100,
                  child: Image.file(
                    File(widget.photos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.remove, size: 30, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      } else {
        photoWidgets.add(
          Stack(
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 32) / 3,
                height: 100,
                child: Image.file(
                  File(widget.photos[index]),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      widget.photos.removeAt(index);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }
    }

    return photoWidgets;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      for (var pickedFile in pickedFiles) {
        widget.onImageAdded(pickedFile.path);
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      widget.onImageAdded(pickedFile.path);
    }
  }
}

class SaisonForm extends StatelessWidget {
  final TextEditingController debutController;
  final TextEditingController finController;
  final GlobalKey<FormState> formKey;

  const SaisonForm({
    super.key,
    required this.debutController,
    required this.finController,
    required this.formKey,
  });

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      if (isDebut) {
        debutController.text = formatted;
      } else {
        finController.text = formatted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: debutController,
            readOnly: true,
            onTap: () => _selectDate(context, true),
            decoration: InputDecoration(labelText: 'Date début'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Obligatoire' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: finController,
            readOnly: true,
            onTap: () => _selectDate(context, false),
            decoration: InputDecoration(labelText: 'Date fin'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Obligatoire' : null,
          ),
        ],
      ),
    );
  }
}

// class ImageStep extends StatefulWidget {
//   @override
//   _ImageStepState createState() => _ImageStepState();
// }
//
// class _ImageStepState extends State<ImageStep> {
//   List<String> _photos = [];
//   bool _expanded = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Wrap(
//           spacing: 8.0, // Espace horizontal entre les images
//           runSpacing: 8.0, // Espace vertical entre les lignes
//           children: _buildPhotoWidgets(),
//         ),
//         ElevatedButton(onPressed: _pickImage, child: Text('Ajouter une photo')),
//       ],
//     );
//   }
//
//   List<Widget> _buildPhotoWidgets() {
//     List<Widget> photoWidgets = [];
//
//     int displayCount =
//         _expanded ? _photos.length : (_photos.length > 4 ? 4 : _photos.length);
//
//     for (int index = 0; index < displayCount; index++) {
//       if (index == 3 && !_expanded && _photos.length > 4) {
//         photoWidgets.add(
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 _expanded = true;
//               });
//             },
//             child: Stack(
//               children: [
//                 SizedBox(
//                   width: (MediaQuery.of(context).size.width - 40) / 4,
//                   height: 100,
//                   child: Image.file(File(_photos[index]), fit: BoxFit.cover),
//                 ),
//                 Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.add, size: 30, color: Colors.white),
//                       Text(
//                         '+${_photos.length - 4}',
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       } else if (index == _photos.length - 1 && _expanded) {
//         photoWidgets.add(
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 _expanded = false;
//               });
//             },
//             child: Stack(
//               children: [
//                 SizedBox(
//                   width: (MediaQuery.of(context).size.width - 40) / 4,
//                   height: 100,
//                   child: Image.file(File(_photos[index]), fit: BoxFit.cover),
//                 ),
//                 Center(
//                   child: Icon(Icons.remove, size: 30, color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//         );
//       } else {
//         photoWidgets.add(
//           Stack(
//             children: [
//               SizedBox(
//                 width: (MediaQuery.of(context).size.width - 40) / 4,
//                 height: 100,
//                 child: Image.file(File(_photos[index]), fit: BoxFit.cover),
//               ),
//               Positioned(
//                 right: 0,
//                 child: IconButton(
//                   icon: Icon(Icons.delete, color: Colors.red),
//                   onPressed: () {
//                     setState(() {
//                       _photos.removeAt(index);
//                     });
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       }
//     }
//
//     return photoWidgets;
//   }
//
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _photos.add(pickedFile.path);
//       });
//     }
//   }
// }
