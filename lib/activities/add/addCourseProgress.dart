import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:ecom/pages/MyApp.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../aGeo/map/LocationAppExample.dart';
import '../modèles.dart';
import '../providers.dart';

class CheckoutScreen extends StatefulWidget {
  final UserModel user;

  const CheckoutScreen({Key? key, required this.user}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeNumberController = TextEditingController();
  RangeValues _ageRange = const RangeValues(5, 18);
  String? _ageRangeError;
  List<String> _photos = [];
  // List<String> _profIds = [];
  List<String> _coachIds = [];

  UserModel? _selectedClub;
  List<Schedule> _schedules = [];
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
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    _resetState();
    _loadProfsList();
    _profSearchController.addListener(filterProfs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfProvider>(
        context,
        listen: false,
      ).fetchProfessorsFromFirestore();
    });
  }

  void _resetState() {
    _currentStep = 0;
    _courseNameController.clear();
    _descriptionController.clear();
    _placeNumberController.clear();
    _ageRange = const RangeValues(5, 18);
    _ageRangeError = null;
    _photos = [];
    _coachIds = [];
    _schedules = [];
    _selectedClub = null;
    _profSearchController.clear();
    _newProfNameController.clear();
    _newProfEmailController.clear();
    _availableProfs = [];
    _filteredProfs = [];
    _selectedProfs = [];
    _isLoading = true;
    _showAddProfForm = false;
    _showAllPhotos = false;
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _descriptionController.dispose();
    _placeNumberController.dispose();
    _profSearchController.dispose();
    _newProfNameController.dispose();
    _newProfEmailController.dispose();
    notifier.dispose();
    super.dispose();
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
        final profsQuery = firestore.FirebaseFirestore.instance
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

      await firestore.FirebaseFirestore.instance
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
    // // Schedule the call to clearcorses after the build phase is complete
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<CourseProvider>(context, listen: false).clearcorses();
    // });
  }

  final debutController = TextEditingController();
  final finController = TextEditingController();
  final saisonFormKey = GlobalKey<FormState>();
  ValueNotifier<osm.GeoPoint?> notifier = ValueNotifier(null);
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      return "${place.locality}, ${place.country}"; //${place.street}, ${place.postalCode},
    }

    return "";
  }

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

  final GlobalKey<_CotisationPricesStepState> _cotisationStepKey = GlobalKey();

  Map<String, double> _cotisationPrices = {};
  @override
  Widget build(BuildContext context) {
    final stepTitles = const [
      'Informations de base',
      'Photos des Cours',
      'Professeurs / Coachs',
      'Les Jours & Horaires',
      'Saison',
      'Localisation', // Nouvelle étape
      'Aperçu',
    ];
    final stepProvider = Provider.of<StepProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Ajouter un Cours'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StepProgressHeader(steps: stepTitles),
            Expanded(
              child: IndexedStack(
                index: stepProvider.currentStep,
                children: [
                  // Contenu de l'étape 0 : Informations de base
                  ListView(
                    children: [
                      Form(
                        key: _formKey1,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          children: [
                            SizedBox(height: 50),
                            TextFormField(
                              controller: _courseNameController,
                              decoration: InputDecoration(
                                hintText: 'Nom du cours',
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surfaceDim,

                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un nom de cours';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _descriptionController,
                              textCapitalization: TextCapitalization.words,
                              minLines: 4,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: 'Déscription',
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surfaceDim,

                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer une description';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: FittedBox(
                                      child: Text(
                                        'Nombre de Place',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: TextFormField(
                                    controller: _placeNumberController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceDim,

                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le Nombre de Place';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.surfaceDim,
                            width: 2.0,
                          ), // Bordure colorée
                        ),
                        elevation: 8, // Ombre plus prononcée
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Tranche d'âge*",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  if (_ageRangeError != null)
                                    Text(
                                      _ageRangeError!,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    )
                                  else
                                    Text(
                                      'De ${_ageRange.start.round()} à ${_ageRange.end.round()} ans',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
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
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Lieu'),
                            notifier.value == null
                                ? Container()
                                : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ValueListenableBuilder<osm.GeoPoint?>(
                                    valueListenable: notifier,
                                    builder: (ctx, px, child) {
                                      return FutureBuilder<String>(
                                        future: getAddressFromLatLng(
                                          px!.latitude,
                                          px.longitude,
                                        ),
                                        builder: (
                                          BuildContext context,
                                          AsyncSnapshot<String> snapshot,
                                        ) {
                                          if (snapshot.hasData) {
                                            return Text(snapshot.data!);
                                          } else if (snapshot.hasError) {
                                            return Text(
                                              'Erreur: ${snapshot.error}',
                                            );
                                          } else {
                                            return CircularProgressIndicator();
                                          }
                                        },
                                      );

                                      //   Center(
                                      //   child: Text(
                                      //     "${px?.latitude.toString()} - ${px?.longitude.toString()}" ??
                                      //         '',
                                      //     textAlign: TextAlign.center,
                                      //   ),
                                      // );
                                    },
                                  ),
                                ),
                            // ValueListenableBuilder<GeoPoint?>(
                            //   valueListenable: notifier,
                            //   builder: (ctx, p, child) {
                            //     return Center(
                            //       child: Text(
                            //         "${p?.toString() ?? ""}",
                            //         textAlign: TextAlign.center,
                            //       ),
                            //     );
                            //   },
                            // ),
                            IconButton(
                              onPressed: () async {
                                final osm.GeoPoint? p = await Navigator.of(
                                  context,
                                ).push(
                                  MaterialPageRoute(
                                    builder:
                                        (ctx) =>
                                            SearchPage(), // retourne GeoPoint de Firestore
                                  ),
                                );
                                if (p != null) {
                                  setState(() => notifier.value = p);
                                }
                              },
                              icon: Icon(Icons.location_searching),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                  // prices and type cotisations
                  CotisationPricesStep(
                    key: _cotisationStepKey,
                    initialPrices: _cotisationPrices,
                    onPricesChanged: (prices) {
                      setState(() => _cotisationPrices = prices);
                    },
                  ),
                  // Contenu de l'étape 1 : Photos des Cours
                  ImageStep(
                    photos: _photos,
                    onImageAdded: (path) {
                      setState(() {
                        _photos.add(path);
                      });
                    },
                  ),

                  // Contenu de l'étape 2 : Professeurs / Coachs
                  ListView(
                    children: [
                      TextField(
                        controller: _profSearchController,
                        onChanged:
                            (value) =>
                                filterProfsWithDebounce(), // Avec debounce
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
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
                                      onChanged:
                                          (_) => _toggleProfSelection(prof),
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
                                          : CircleAvatar(
                                            child: Icon(Icons.person),
                                          ),
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
                  // Contenu de l'étape 3 : Les Jours & Horaires
                  ListView(
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
                                      onLongPress:
                                          () =>
                                              provider.removeSchedule(schedule),
                                      leading: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => provider.removeSchedule(
                                              schedule,
                                            ),
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
                    ],
                  ),
                  // Contenu de l'étape 4 : Saison
                  ListView(
                    children: [
                      SaisonForm(
                        debutController: debutController,
                        finController: finController,
                        formKey: saisonFormKey,
                      ),
                    ],
                  ),
                  // Ajoutez le widget LocationStep pour la nouvelle étape

                  // Contenu de l'étape 5 : Aperçu
                  ListView(
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nom du cours: ${_courseNameController.text}'),
                      Text('Description: ${_descriptionController.text}'),
                      Text('Nombre de Place: ${_placeNumberController.text}'),
                      Text(
                        'Tranche d\'âge: ${_ageRange.start.round()} - ${_ageRange.end.round()} ans',
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Photos des cours:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 8,
                        children:
                            _photos.map((photo) {
                              return Image.file(
                                File(photo),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            }).toList(),
                      ),
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
                      SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                            color: Colors.blueAccent,
                            width: 2.0,
                          ), // Bordure colorée
                        ),
                        elevation: 8, // Ombre plus prononcée
                        margin: EdgeInsets.symmetric(
                          vertical: 8.0,
                        ), // Marge extérieure
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saison:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.blueAccent, // Couleur du texte
                                ),
                              ),
                              Divider(
                                color: Colors.blueAccent,
                                thickness: 1.5,
                              ), // Ligne de séparation
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Début',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        dateDebut != null
                                            ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(dateDebut!)
                                            : '??',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Fin',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        dateFin != null
                                            ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(dateFin!)
                                            : '??',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dans l'étape Aperçu
                      // Ajoutez l'affichage de la localisation dans l'aperçu
                      SizedBox(height: 20),
                      // Affichage des horaires
                      SizedBox(height: 20),
                      Text(
                        'Horaires:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Consumer<CourseProvider>(
                        builder: (context, provider, child) {
                          if (provider.schedules.isNotEmpty) {
                            _schedules = provider.schedules;
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
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveCourse,
                        child: Text('Submit to Storage'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (stepProvider.currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: stepProvider.previousStep,
                      child: Text(
                        'Retour',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (stepProvider.currentStep > 0) SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        stepProvider.currentStep < 5
                            ? _validateCurrentStep()
                                ? stepProvider.nextStep
                                : null
                            : _saveCourse,

                    child: Text(
                      stepProvider.currentStep < 5 ? 'Suivant' : 'Enregitrer',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void filterProfsWithDebounce() {
    // Implémentez la logique de filtrage avec debounce ici
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
                          runSpacing: 8,
                          children:
                              availableDays.map((day) {
                                return SizedBox(
                                  width: 100, // largeur fixe
                                  height: 40,
                                  child: FilterChip(
                                    label: Text(day),
                                    selected: selectedDays.contains(day),
                                    onSelected:
                                        (selected) => setState(() {
                                          selected
                                              ? selectedDays.add(day)
                                              : selectedDays.remove(day);
                                        }),
                                  ),
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
                        // Assurez-vous que l'état est mis à jour
                        setState(() {
                          _schedules =
                              Provider.of<CourseProvider>(
                                context,
                                listen: false,
                              ).schedules;
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

  Future<void> _saveCourse() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    List<String> photoUrls = [];
    ValueNotifier<int> current = ValueNotifier<int>(0);
    int total = _photos.length;

    _showStylishProgressDialog(context, current, total);

    try {
      final futures =
          _photos.map((photo) async {
            if (!photo.startsWith('http')) {
              final compressed = await _compressImageToWebP(photo);

              final ref = firebase_storage.FirebaseStorage.instance.ref().child(
                'course_photos/${DateTime.now().millisecondsSinceEpoch}.webp',
              );

              if (compressed != null) {
                await ref.putData(
                  compressed,
                  firebase_storage.SettableMetadata(contentType: 'image/webp'),
                );
              } else {
                await ref.putFile(File(photo));
              }

              final url = await ref.getDownloadURL();
              current.value++;

              return url;
            } else {
              current.value++;
              return photo;
            }
          }).toList();

      photoUrls = await Future.wait(futures);

      final docRef =
          firestore.FirebaseFirestore.instance.collection('courses').doc();

      final course = Course(
        id: docRef.id,
        name: _courseNameController.text,
        clubId: widget.user.id,
        description: _descriptionController.text,
        schedules: courseProvider.schedules,
        ageRange: '${_ageRange.start.round()}-${_ageRange.end.round()}',
        profIds: _selectedProfs.map((user) => user.id).toList(),
        photos: photoUrls,
        placeNumber: int.parse(_placeNumberController.text.trim()),
        createdAt: DateTime.now(),
        saisonStart: DateFormat('dd/MM/yyyy').parseStrict(debutController.text),
        saisonEnd: DateFormat('dd/MM/yyyy').parseStrict(finController.text),
        location: firestore.GeoPoint(
          notifier.value!.latitude,
          notifier.value!.longitude,
        ),
      );
      print(course);
      await docRef.set(course.toMap(), firestore.SetOptions(merge: true));

      await firestore.FirebaseFirestore.instance
          .collection('userModel')
          .doc(widget.user.id)
          .set({
            'courses': firestore.FieldValue.arrayUnion([course.id]),
          }, firestore.SetOptions(merge: true));

      Navigator.of(context).pop(); // Ferme le progress dialog

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cours sauvegardé avec succès!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyApp1()),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      print('*****************************************');
      print(e);
    }
  }

  void _showStylishProgressDialog(
    BuildContext context,
    ValueNotifier<int> current,
    int total,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: ValueListenableBuilder<int>(
              valueListenable: current,
              builder: (context, value, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: Lottie.asset(
                        'assets/lotties/1 (71).json',
                        repeat: true,
                      ), // ajoute un fichier lottie ici
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Chargement des images...",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: total > 0 ? value / total : null,
                      color: Colors.teal,
                    ),
                    SizedBox(height: 8),
                    Text('$value / $total'),
                  ],
                );
              },
            ),
          ),
    );
  }

  Future<Uint8List?> _compressImageToWebP(String imagePath) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        imagePath,
        format: CompressFormat.webp,
        quality: 75,
        minWidth: 800,
        minHeight: 600,
        keepExif: false,
      );
    } catch (e) {
      print('Erreur compression : $e');
      return null;
    }
  }

  bool _validateCurrentStep() {
    final stepProvider = Provider.of<StepProvider>(context, listen: true);
    switch (stepProvider.currentStep) {
      case 0:
        return _formKey1.currentState?.validate() ?? false;
      case 1:
        return _cotisationPrices.isNotEmpty; // À maintenir à jour
      case 2:
        return _photos.isNotEmpty;
      case 3:
        return _selectedProfs.isNotEmpty;
      case 4:
        return _schedules.isNotEmpty;
      case 5:
        return saisonFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  bool _validateStep0() {
    return _formKey1.currentState?.validate() ?? false;
  }

  bool _validateStep1() {
    return _cotisationStepKey.currentState?.validate() ?? false;
  }

  bool _validateStep2() {
    return _photos.isNotEmpty; // Assuming at least one photo is required
  }

  bool _validateStep3() {
    return _selectedProfs
        .isNotEmpty; // Assuming at least one professor is required
  }

  bool _validateStep4() {
    // Assuming at least one schedule is required

    print(_schedules);

    return Provider.of<CourseProvider>(
      context,
      listen: true,
    ).schedules.isNotEmpty;
  }

  bool _validateStep5() {
    return saisonFormKey.currentState?.validate() ??
        false; // Assuming a form key for the season step
  }
}

class StepProgressHeader extends StatelessWidget {
  final List<String> steps;

  const StepProgressHeader({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);
    final current = stepProvider.currentStep;
    final progress = current / (steps.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              builder:
                  (context, value, _) => SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ),
            ),
            Text(
              '${current + 1} of ${steps.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              steps[current].capitalize(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (current < steps.length - 1)
              Text(
                'Next: ${steps[current + 1]}'.capitalize(),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
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
            // validator:
            //     (value) =>
            //         value == null || value.isEmpty ? 'Obligatoire' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: finController,
            readOnly: true,
            onTap: () => _selectDate(context, false),
            decoration: InputDecoration(labelText: 'Date fin'),
            // validator:
            //     (value) =>
            //         value == null || value.isEmpty ? 'Obligatoire' : null,
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
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
    return ListView(
      children: [
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10.0,
                ), // Optionnel : pour des coins arrondis
              ),
              elevation: 4, // Optionnel : pour une ombre
              child: Container(
                width: 100, // Définissez la largeur du Card
                height: 100, // Définissez la hauteur du Card
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.image, color: Colors.black54, size: 50),
                    onPressed: _pickImages,
                  ),
                ),
              ),
            ),
            SizedBox(width: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10.0,
                ), // Optionnel : pour des coins arrondis
              ),
              elevation: 4, // Optionnel : pour une ombre
              child: Container(
                width: 100, // Définissez la largeur du Card
                height: 100, // Définissez la hauteur du Card
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.black54),
                    onPressed: _takePhoto,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Center(
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _buildPhotoWidgets(),
          ),
        ),
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
                    '+${widget.photos.length - 4}',
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

class CotisationPricesStep extends StatefulWidget {
  final Map<String, double> initialPrices;
  final void Function(Map<String, double>) onPricesChanged;

  const CotisationPricesStep({
    Key? key,
    required this.initialPrices,
    required this.onPricesChanged,
  }) : super(key: key);

  @override
  State<CotisationPricesStep> createState() => _CotisationPricesStepState();
}

class _CotisationPricesStepState extends State<CotisationPricesStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedType;

  late Map<String, double> _prices;

  final List<String> _cotisationTypes = ['annuel', 'mensuel', 'seance'];

  @override
  void initState() {
    super.initState();
    _prices = Map<String, double>.from(widget.initialPrices);
  }

  void _addPrice() {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      final double? parsedPrice = double.tryParse(_priceController.text);
      if (parsedPrice != null) {
        setState(() {
          _prices[_selectedType!] = parsedPrice;
          _selectedType = null;
          _priceController.clear();
        });
        widget.onPricesChanged(Map.from(_prices));
      }
    }
  }

  void _removePrice(String type) {
    setState(() {
      _prices.remove(type);
      widget.onPricesChanged(Map.from(_prices));
    });
  }

  bool validate() {
    return _prices.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type de cotisation',
                  ),
                  value: _selectedType,
                  items:
                      _cotisationTypes
                          .where((type) => !_prices.containsKey(type))
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedType = value),
                  validator:
                      (value) => value == null ? 'Sélectionnez un type' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Prix (DA)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: _addPrice),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_prices.isEmpty) const Text('Aucun tarif ajouté pour l’instant.'),
        ..._prices.entries.map(
          (entry) => ListTile(
            title: Text(entry.key[0].toUpperCase() + entry.key.substring(1)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${entry.value.toStringAsFixed(2)} DA'),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePrice(entry.key),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
