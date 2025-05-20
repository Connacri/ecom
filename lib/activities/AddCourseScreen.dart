import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/activities/data_populator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'generated/multiphoto/photo_provider.dart';
import 'modèles.dart';
import 'providers.dart';

class AddCourseScreen extends StatefulWidget {
  final UserModel user;

  const AddCourseScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageRangeController = TextEditingController();
  final _profSearchController = TextEditingController();
  final _newProfNameController = TextEditingController();
  final _newProfEmailController = TextEditingController();
  RangeValues _ageRange = const RangeValues(5, 18);
  String? _ageRangeError;
  UserModel? _selectedClub;
  List<UserModel> _availableClubs = [];
  List<UserModel> _availableProfs = [];
  List<UserModel> _filteredProfs = [];
  List<UserModel> _selectedProfs = [];
  bool _isLoading = true;
  bool _showAddProfForm = false;
  bool _showAllPhotos = false;

  // Liste des URLs des photos sélectionnées
  List<String> _selectedPhotoUrls = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _profSearchController.addListener(_filterProfs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Schedule the call to clearcorses after the build phase is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).clearcorses();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ageRangeController.dispose();
    _profSearchController.dispose();
    _newProfNameController.dispose();
    _newProfEmailController.dispose();
    super.dispose();
  }

  void _filterProfs() {
    final query = _profSearchController.text.toLowerCase();
    setState(() {
      _filteredProfs =
          _availableProfs.where((prof) {
            return prof.name.toLowerCase().contains(query) ||
                prof.email.toLowerCase().contains(query);
          }).toList();
    });
  }

  // Future<void> _loadData() async {
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final clubsQuery = FirebaseFirestore.instance
  //         .collection('userModel')
  //         .where('role', isEqualTo: 'club');
  //     final profsQuery = FirebaseFirestore.instance
  //         .collection('userModel')
  //         .where('role', isEqualTo: 'professeur');
  //
  //     final results = await Future.wait([clubsQuery.get(), profsQuery.get()]);
  //
  //     final clubs =
  //         results[0].docs
  //             .map((doc) => UserModel.fromMap(doc.data(), doc.id))
  //             .toList();
  //     final profs =
  //         results[1].docs
  //             .map((doc) => UserModel.fromMap(doc.data(), doc.id))
  //             .toList();
  //
  //     setState(() {
  //       _availableClubs = clubs;
  //       _availableProfs = profs;
  //       _filteredProfs = profs;
  //       _selectedClub = clubs.isNotEmpty ? clubs.first : null;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
  //     );
  //     debugPrint('Erreur lors du chargement des données: $e');
  //   }
  // }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer les clubs
      final clubsQuery = FirebaseFirestore.instance
          .collection('userModel')
          .where('role', isEqualTo: 'club');

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

      // Récupérer les clubs
      final clubsSnapshot = await clubsQuery.get();
      final clubs =
          clubsSnapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();

      setState(() {
        _availableClubs = clubs;
        _availableProfs = profs;
        _filteredProfs = profs;
        _selectedClub = clubs.isNotEmpty ? clubs.first : null;
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
        role: 'professeur',
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

  // Utiliser le PhotoProvider pour sélectionner et télécharger des images
  Future<void> _pickImages() async {
    try {
      // Utiliser le PhotoProvider pour récupérer les images depuis la galerie
      await Provider.of<PhotoProvider>(
        context,
        listen: false,
      ).pickAndUploadMultipleImages();

      // Récupérer les URLs des images téléchargées
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

      // Ajouter uniquement les nouvelles images à notre liste
      if (photoProvider.images.isNotEmpty) {
        setState(() {
          // Ajouter les nouvelles URLs (on prend les plus récentes en premier)
          for (var image in photoProvider.images) {
            if (!_selectedPhotoUrls.contains(image['url'])) {
              _selectedPhotoUrls.add(image['url']);
            }

            // Limiter à 9 photos maximum
            if (_selectedPhotoUrls.length >= 9) break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la sélection des images: ${e.toString()}',
          ),
        ),
      );
      debugPrint('Erreur lors de la sélection des images: $e');
    }
  }

  // Prendre une photo avec l'appareil photo
  Future<void> _takePhoto() async {
    try {
      // Utiliser le PhotoProvider pour prendre et télécharger une photo
      await Provider.of<PhotoProvider>(
        context,
        listen: false,
      ).takeAndUploadPhoto();

      // Récupérer l'URL de la photo téléchargée
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

      // Ajouter la nouvelle photo à notre liste
      if (photoProvider.images.isNotEmpty) {
        setState(() {
          // Vérifier qu'on ne dépasse pas la limite de 9 photos
          if (_selectedPhotoUrls.length < 9) {
            // Ajouter la photo la plus récente (index 0)
            String photoUrl = photoProvider.images[0]['url'];
            if (!_selectedPhotoUrls.contains(photoUrl)) {
              _selectedPhotoUrls.add(photoUrl);
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la prise de photo: ${e.toString()}'),
        ),
      );
      debugPrint('Erreur lors de la prise de photo: $e');
    }
  }

  // Supprimer une photo de la liste
  void _removeImage(int index) {
    setState(() {
      _selectedPhotoUrls.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClub == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Veuillez sélectionner un club')));
      return;
    }
    if (Provider.of<CourseProvider>(context, listen: false).schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez ajouter au moins un horaire')),
      );
      return;
    }
    if (_selectedProfs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner au moins un Coach/Professeur'),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final courseId = Uuid().v4();
      final profIds = _selectedProfs.map((prof) => prof.id).toList();

      final newCourse = Course(
        id: courseId,
        name: _nameController.text.trim(),
        club: _selectedClub!,
        description: _descriptionController.text.trim(),
        schedules:
            Provider.of<CourseProvider>(context, listen: false).schedules,
        ageRange: '${_ageRange.start.round()}-${_ageRange.end.round()}',
        profIds: profIds,
      );

      await FirebaseFirestore.instance.collection('courses').doc(courseId).set({
        'name': newCourse.name,
        'club': _selectedClub!.toMap(),
        'clubId': _selectedClub!.id,
        'description': newCourse.description,
        'schedules': newCourse.schedules.map((s) => s.toMap()).toList(),
        'ageRange': newCourse.ageRange,
        'profIds': profIds,
        'photos':
            _selectedPhotoUrls, // Utiliser directement les URLs des photos
        'createdAt': FieldValue.serverTimestamp(),
        'editedAt': FieldValue.serverTimestamp(),
      });

      Provider.of<CourseProvider>(context, listen: false).addCourse(newCourse);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: ${e.toString()}')),
      );
      debugPrint('Erreur création cours: $e');
    }
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
                  title: Text('Ajouter un horaire'),
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

                        Provider.of<CourseProvider>(
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

  void _toggleProfSelection(UserModel prof) {
    setState(() {
      _selectedProfs.contains(prof)
          ? _selectedProfs.remove(prof)
          : _selectedProfs.add(prof);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Ajouter un Cours')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un Cours'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(child: Text(widget.user.name)),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du Cours*',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Ce champ est obligatoire'
                            : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
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
                        Text("Tranche d'âge*", style: TextStyle(fontSize: 16)),
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
              // Section des photos
              Text(
                'Photos du cours (max 9)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.photo_library),
                    label: Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Appareil photo'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              if (_selectedPhotoUrls.isNotEmpty) ...[
                Text(
                  'Photos sélectionnées:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount:
                      _showAllPhotos
                          ? _selectedPhotoUrls.length +
                              (_selectedPhotoUrls.length < 9 ? 0 : 1)
                          : (_selectedPhotoUrls.length > 3
                              ? 4 // 3 images + voir plus
                              : _selectedPhotoUrls.length),
                  itemBuilder: (context, index) {
                    if (index == 3 &&
                        !_showAllPhotos &&
                        _selectedPhotoUrls.length > 3) {
                      // Bouton "Voir plus"
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllPhotos = true;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 30),
                                Text(
                                  '${_selectedPhotoUrls.length - 3} de plus',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (_showAllPhotos &&
                        index == _selectedPhotoUrls.length) {
                      // Bouton "Voir moins"
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllPhotos = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.remove, size: 30),
                                Text('Réduire', textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Image normale
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(_selectedPhotoUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],

              SizedBox(height: 24),
              Text('Coach/Professeurs*', style: TextStyle(fontSize: 16)),
              TextFormField(
                controller: _profSearchController,
                decoration: InputDecoration(
                  labelText: 'Rechercher un Coach/Professeur',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _profSearchController.clear();
                      _filterProfs();
                    },
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              TextButton(
                onPressed:
                    () => setState(() => _showAddProfForm = !_showAddProfForm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_showAddProfForm ? Icons.remove : Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text(
                      _showAddProfForm
                          ? 'Masquer le formulaire'
                          : 'Ajouter un nouveau Coach/Professeur',
                    ),
                  ],
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
                ElevatedButton(
                  onPressed: _addNewProf,
                  child: Text('Enregistrer le Coach/Professeur'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                          profsToShow.map((prof) {
                            final isSelected = _selectedProfs.contains(prof);
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

              if (_selectedProfs.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Coachs/Professeurs sélectionnés:',
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
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addSchedule,
                child: Text('Ajouter un horaire'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              Consumer<CourseProvider>(
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
                                style: TextStyle(fontWeight: FontWeight.w500),
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
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Ajouter le Cours'),
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

class EditCourseScreen extends StatefulWidget {
  final Course course;

  const EditCourseScreen({Key? key, required this.course}) : super(key: key);

  @override
  _EditCourseScreenState createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _profSearchController = TextEditingController();
  final _newProfNameController = TextEditingController();
  final _newProfEmailController = TextEditingController();
  RangeValues _ageRange = const RangeValues(5, 18);
  String? _ageRangeError;
  UserModel? _selectedClub;
  List<Schedule> _schedules = [];
  List<UserModel> _filteredProfs = [];
  List<UserModel> _selectedProfs = [];
  bool _showAddProfForm = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.course.name;
    _descriptionController.text = widget.course.description;
    _initializeFormData();
    _profSearchController.addListener(_filterProfs);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _profSearchController.dispose();
    _newProfNameController.dispose();
    _newProfEmailController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    // Initialize age range
    _ageRange = RangeValues(
      double.parse(widget.course.ageRange.split('-')[0]),
      double.parse(widget.course.ageRange.split('-')[1]),
    );

    // Initialize schedules
    _schedules = widget.course.schedules;

    // This will run after the build is complete to ensure Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );

      // Set selected club
      if (courseProvider.clubs.isNotEmpty) {
        _selectedClub = courseProvider.clubs.firstWhere(
          (club) => club.id == widget.course.club.id,
          orElse: () => courseProvider.clubs.first,
        );
      }

      // Set selected professors
      _selectedProfs =
          courseProvider.professors
              .where((prof) => widget.course.profIds.contains(prof.id))
              .toList();

      // Initialize filtered professors list
      _filterProfs();

      setState(() {});
    });
  }

  void _filterProfs() {
    final query = _profSearchController.text.toLowerCase();
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    setState(() {
      _filteredProfs =
          courseProvider.professors.where((prof) {
            return prof.name.toLowerCase().contains(query) ||
                prof.email.toLowerCase().contains(query);
          }).toList();
    });
  }

  void _toggleProfSelection(UserModel prof) {
    setState(() {
      _selectedProfs.contains(prof)
          ? _selectedProfs.remove(prof)
          : _selectedProfs.add(prof);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClub == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Veuillez sélectionner un club')));
      return;
    }

    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez ajouter au moins un horaire')),
      );
      return;
    }

    if (_selectedProfs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner au moins un Coach/Professeur'),
        ),
      );
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final profIds = _selectedProfs.map((prof) => prof.id).toList();

    final updatedCourse = Course(
      id: widget.course.id,
      name: _nameController.text.trim(),
      club: _selectedClub!,
      description: _descriptionController.text.trim(),
      schedules: _schedules,
      ageRange: '${_ageRange.start.round()}-${_ageRange.end.round()}',
      profIds: profIds,
    );

    final success = await courseProvider.updateCourse(updatedCourse);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour du cours')),
      );
    }
  }

  Future<void> _addNewProf() async {
    final name = _newProfNameController.text.trim();
    final email = _newProfEmailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final newProf = await courseProvider.createProfessor(name, email);

    if (newProf != null) {
      setState(() {
        _selectedProfs.add(newProf);
        _newProfNameController.clear();
        _newProfEmailController.clear();
        _showAddProfForm = false;
      });

      // Refresh filtered professors list
      _filterProfs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création du Coach/Professeur'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        if (courseProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('Modifier un Cours')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text('Modifier un Cours')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du Cours*',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Ce champ est obligatoire'
                                : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tranche d'âge*", style: TextStyle(fontSize: 16)),
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
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text('Club*', style: TextStyle(fontSize: 16)),
                  DropdownButtonFormField<UserModel>(
                    value: _selectedClub,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Sélectionner un club',
                      errorText:
                          _selectedClub == null
                              ? 'Ce champ est obligatoire'
                              : null,
                      border: OutlineInputBorder(),
                    ),
                    items:
                        courseProvider.clubs.map((club) {
                          return DropdownMenuItem(
                            value: club,
                            child: Text(club.name),
                          );
                        }).toList(),
                    onChanged: (value) => setState(() => _selectedClub = value),
                  ),
                  SizedBox(height: 24),
                  Text('Coach/Professeurs*', style: TextStyle(fontSize: 16)),
                  TextFormField(
                    controller: _profSearchController,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un Coach/Professeur',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _profSearchController.clear();
                          _filterProfs();
                        },
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => setState(
                          () => _showAddProfForm = !_showAddProfForm,
                        ),
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
                              : 'Ajouter un nouveau Coach/Professeur',
                        ),
                      ],
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
                  if (_filteredProfs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Aucun Coach/Professeur trouvé',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Column(
                      children:
                          _filteredProfs.map((prof) {
                            final isSelected = _selectedProfs.contains(prof);
                            return CheckboxListTile(
                              title: Text(prof.name),
                              subtitle: Text(prof.email),
                              value: isSelected,
                              onChanged: (_) => _toggleProfSelection(prof),
                            );
                          }).toList(),
                    ),
                  if (_selectedProfs.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Coachs/Professeurs sélectionnés:',
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
                  ],
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Mettre à jour le Cours'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
