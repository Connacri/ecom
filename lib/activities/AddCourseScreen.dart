import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'modèles.dart';
import 'providers.dart';

class AddCourseScreen extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _loadData();
    _profSearchController.addListener(_filterProfs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access Provider here
    Provider.of<CourseProvider>(context, listen: false).clearcorses();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final clubsQuery = FirebaseFirestore.instance
          .collection('userModel')
          .where('role', isEqualTo: 'club');
      final profsQuery = FirebaseFirestore.instance
          .collection('userModel')
          .where('role', isEqualTo: 'professeur');

      final results = await Future.wait([clubsQuery.get(), profsQuery.get()]);

      final clubs =
          results[0].docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();
      final profs =
          results[1].docs
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
      setState(() => _isLoading = true);
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

      Provider.of<CourseProvider>(context, listen: false).addProfessor(newProf);

      setState(() {
        _availableProfs.add(newProf);
        _filteredProfs.add(newProf);
        _selectedProfs.add(newProf);
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
      debugPrint('Erreur création professeur: $e');
    }
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
        SnackBar(content: Text('Veuillez sélectionner au moins un professeur')),
      );
      return;
    }

    try {
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      Provider.of<CourseProvider>(context, listen: false).addCourse(newCourse);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
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
    //  Provider.of<CourseProvider>(context).clearcorses();
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
                      _selectedClub == null ? 'Ce champ est obligatoire' : null,
                  border: OutlineInputBorder(),
                ),
                items:
                    _availableClubs.map((club) {
                      return DropdownMenuItem(
                        value: club,
                        child: Text(club.name),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedClub = value),
              ),
              SizedBox(height: 24),
              Text('Professeurs*', style: TextStyle(fontSize: 16)),
              TextFormField(
                controller: _profSearchController,
                decoration: InputDecoration(
                  labelText: 'Rechercher un professeur',
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
                          : 'Ajouter un nouveau professeur',
                    ),
                  ],
                ),
              ),
              if (_showAddProfForm) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _newProfNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du professeur*',
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
                    labelText: 'Email du professeur*',
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
                  child: Text('Enregistrer le professeur'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (_filteredProfs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Aucun professeur trouvé',
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
                  'Professeurs sélectionnés:',
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

  const EditCourseScreen({required this.course});

  @override
  _EditCourseScreenState createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
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
  List<Schedule> _schedules = [];
  List<UserModel> _availableClubs = [];
  List<UserModel> _availableProfs = [];
  List<UserModel> _filteredProfs = [];
  List<UserModel> _selectedProfs = [];
  bool _isLoading = true;
  bool _showAddProfForm = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _profSearchController.addListener(_filterProfs);
    _nameController.text = widget.course.name;
    _descriptionController.text = widget.course.description;
    _ageRange = RangeValues(
      double.parse(widget.course.ageRange.split('-')[0]),
      double.parse(widget.course.ageRange.split('-')[1]),
    );
    _schedules = widget.course.schedules;
    _selectedProfs =
        _availableProfs
            .where((prof) => widget.course.profIds.contains(prof.id))
            .toList();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final clubsQuery = FirebaseFirestore.instance
          .collection('userModel')
          .where('role', isEqualTo: 'club');
      final profsQuery = FirebaseFirestore.instance
          .collection('userModel')
          .where('role', isEqualTo: 'professeur');

      final results = await Future.wait([clubsQuery.get(), profsQuery.get()]);

      final clubs =
          results[0].docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();
      final profs =
          results[1].docs
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
        SnackBar(content: Text('Veuillez sélectionner au moins un professeur')),
      );
      return;
    }

    try {
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

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .update({
            'name': updatedCourse.name,
            'club': _selectedClub!.toMap(),
            'clubId': _selectedClub!.id,
            'description': updatedCourse.description,
            'schedules': updatedCourse.schedules.map((s) => s.toMap()).toList(),
            'ageRange': updatedCourse.ageRange,
            'profIds': profIds,
            'editedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
        ),
      );
      debugPrint('Erreur mise à jour cours: $e');
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
      setState(() => _isLoading = true);
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

      Provider.of<CourseProvider>(context, listen: false).addProfessor(newProf);

      setState(() {
        _availableProfs.add(newProf);
        _filteredProfs.add(newProf);
        _selectedProfs.add(newProf);
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
      debugPrint('Erreur création professeur: $e');
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
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                      _selectedClub == null ? 'Ce champ est obligatoire' : null,
                  border: OutlineInputBorder(),
                ),
                items:
                    _availableClubs.map((club) {
                      return DropdownMenuItem(
                        value: club,
                        child: Text(club.name),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedClub = value),
              ),
              SizedBox(height: 24),
              Text('Professeurs*', style: TextStyle(fontSize: 16)),
              TextFormField(
                controller: _profSearchController,
                decoration: InputDecoration(
                  labelText: 'Rechercher un professeur',
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
                          : 'Ajouter un nouveau professeur',
                    ),
                  ],
                ),
              ),
              if (_showAddProfForm) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _newProfNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du professeur*',
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
                    labelText: 'Email du professeur*',
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
                  child: Text('Enregistrer le professeur'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (_filteredProfs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Aucun professeur trouvé',
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
                  'Professeurs sélectionnés:',
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
