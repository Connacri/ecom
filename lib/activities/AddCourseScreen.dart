import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'modèles.dart';

class AddCourseScreen extends StatefulWidget {
  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageRangeController = TextEditingController();
  Club? _selectedClub;
  List<Schedule> _schedules = [];
  List<Club> _availableClubs = [];
  List<Prof> _availableProfs = [];
  List<Prof> _selectedProfs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Chargement parallèle des clubs et des professeurs
      final clubsFuture = FirebaseFirestore.instance.collection('clubs').get();
      final profsFuture = FirebaseFirestore.instance.collection('profs').get();

      final results = await Future.wait([clubsFuture, profsFuture]);

      final clubDocs = results[0];
      final profDocs = results[1];

      // Traitement des clubs
      final clubs =
          clubDocs.docs.map((doc) {
            final data = doc.data();
            return Club.fromMap(data, doc.id);
          }).toList();

      // Traitement des professeurs
      final profs =
          profDocs.docs.map((doc) {
            final data = doc.data();
            return Prof.fromMap(data);
          }).toList();

      setState(() {
        _availableClubs = clubs;
        _availableProfs = profs;

        if (clubs.isNotEmpty) {
          _selectedClub = clubs.first;
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
      });

      // Afficher une erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des données')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedClub != null) {
      // Vérifications supplémentaires
      if (_schedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez ajouter au moins un horaire')),
        );
        return;
      }

      if (_selectedProfs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez sélectionner au moins un professeur'),
          ),
        );
        return;
      }

      // Génération d'un ID unique
      final courseId =
          Uuid()
              .v4(); // Assurez-vous d'ajouter la dépendance uuid au pubspec.yaml

      // Extraction des IDs de professeurs
      final profIds = _selectedProfs.map((prof) => prof.id).toList();

      Course newCourse = Course(
        id: courseId,
        name: _nameController.text,
        club: _selectedClub!, // Utilisation de l'objet Club
        description: _descriptionController.text,
        schedules: _schedules,
        ageRange: _ageRangeController.text,
        profIds: profIds,
      );

      FirebaseFirestore.instance.collection('courses').doc(courseId).set({
        'name': newCourse.name,
        'clubId': newCourse.club.id, // Stockage de l'ID du club
        'description': newCourse.description,
        'schedules':
            newCourse.schedules.map((schedule) => schedule.toMap()).toList(),
        'ageRange': newCourse.ageRange,
        'profIds': profIds,
      });

      Navigator.pop(context);
    }
  }

  void _addSchedule() {
    _showAddScheduleDialog();
  }

  void _showAddScheduleDialog() {
    final timeFormat = DateFormat('HH:mm');
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    Set<String> selectedDays = {};
    List<String> availableDays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    TimeOfDay? startTime;
    TimeOfDay? endTime;

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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                final isSelected = selectedDays.contains(day);
                                return FilterChip(
                                  label: Text(day),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedDays.add(day);
                                      } else {
                                        selectedDays.remove(day);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Heure de début:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          controller: startTimeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Sélectionner',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                startTime = picked;
                                startTimeController.text =
                                    '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Heure de fin:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          controller: endTimeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Sélectionner',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  startTime != null
                                      ? TimeOfDay(
                                        hour: (startTime!.hour + 1) % 24,
                                        minute: startTime!.minute,
                                      )
                                      : TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                endTime = picked;
                                endTimeController.text =
                                    '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
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
                              content: Text(
                                'Veuillez sélectionner au moins un jour',
                              ),
                            ),
                          );
                          return;
                        }

                        if (startTime == null || endTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Veuillez sélectionner les heures de début et de fin',
                              ),
                            ),
                          );
                          return;
                        }

                        // Créer un nouvel horaire
                        final now = DateTime.now();
                        final startDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          startTime!.hour,
                          startTime!.minute,
                        );
                        final endDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          endTime!.hour,
                          endTime!.minute,
                        );

                        final newSchedule = Schedule(
                          id: Uuid().v4(),
                          startTime: startDateTime,
                          endTime: endDateTime,
                          days: selectedDays.toList(),
                        );

                        this.setState(() {
                          _schedules.add(newSchedule);
                        });

                        Navigator.pop(context);
                      },
                      child: Text('Ajouter'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _toggleProfSelection(Prof prof) {
    setState(() {
      if (_selectedProfs.any((p) => p.id == prof.id)) {
        _selectedProfs.removeWhere((p) => p.id == prof.id);
      } else {
        _selectedProfs.add(prof);
      }
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
      appBar: AppBar(title: Text('Ajouter un Cours')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nom du Cours'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageRangeController,
                decoration: InputDecoration(
                  labelText: 'Tranche d\'âge (ex: 6-8 ans)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une tranche d\'âge';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Club:',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              if (_availableClubs.isEmpty)
                Text(
                  'Aucun club disponible',
                  style: TextStyle(color: Colors.red),
                )
              else
                DropdownButtonFormField<Club>(
                  value: _selectedClub,
                  isExpanded: true,
                  decoration: InputDecoration(hintText: 'Sélectionner un club'),
                  items:
                      _availableClubs.map((club) {
                        return DropdownMenuItem(
                          value: club,
                          child: Text(club.name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClub = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner un club';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 16),
              Text(
                'Professeurs:',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              if (_availableProfs.isEmpty)
                Text(
                  'Aucun professeur disponible',
                  style: TextStyle(color: Colors.red),
                )
              else
                Wrap(
                  spacing: 8,
                  children:
                      _availableProfs.map((prof) {
                        final isSelected = _selectedProfs.any(
                          (p) => p.id == prof.id,
                        );
                        return FilterChip(
                          label: Text(prof.name),
                          selected: isSelected,
                          onSelected: (_) => _toggleProfSelection(prof),
                        );
                      }).toList(),
                ),
              if (_selectedProfs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Professeurs sélectionnés: ${_selectedProfs.map((p) => p.name).join(", ")}',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Horaires:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addSchedule,
                    icon: Icon(Icons.add),
                    label: Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              if (_schedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Aucun horaire ajouté',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _schedules[index];
                    final days = schedule.days.join(', ');
                    final startTime =
                        '${schedule.startTime.hour}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
                    final endTime =
                        '${schedule.endTime.hour}:${schedule.endTime.minute.toString().padLeft(2, '0')}';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('$days'),
                        subtitle: Text('$startTime - $endTime'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _schedules.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),

              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Enregistrer le cours'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
