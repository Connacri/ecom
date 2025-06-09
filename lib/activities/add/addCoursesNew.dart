import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../pages/MyApp.dart';
import '../aGeo/map/LocationAppExample.dart';
import '../modèles.dart';
import '../providers.dart';

class StepperDemo extends StatefulWidget {
  @override
  _StepperDemoState createState() => _StepperDemoState();
}

class _StepperDemoState extends State<StepperDemo> {
  final List<String> steps = const [
    'Informations de base',
    'Courses Type & price',
    'Photos des Cours',
    'Professeurs / Coachs',
    'Les Jours & Horaires',
    'Saison',
    'Aperçu',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Stepper Demo'),
        actions: [
          IconButton(
            onPressed: () {
              _fillTestData(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StepperDemo()),
              );
            },
            icon: Icon(Icons.account_tree_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          StepProgressHeader(steps: steps),
          const SizedBox(height: 16),
          Expanded(
            child: CustomStepper(
              steps: steps,
              currentStep: Provider.of<StepProvider1>(context).currentStep,
              onStepContinue: () {
                _validateAndContinue(context);
              },
              onStepCancel: () {
                Provider.of<StepProvider1>(
                  context,
                  listen: false,
                ).previousStep();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndContinue(BuildContext context) {
    final stepProvider = Provider.of<StepProvider1>(context, listen: false);
    if (stepProvider.currentStep == 0) {
      // Validation pour la première étape
      List<String> missingFields = [];

      if (stepProvider.nom == null || stepProvider.nom!.trim().isEmpty) {
        missingFields.add('Nom');
      }

      if (stepProvider.description == null ||
          stepProvider.description!.trim().isEmpty) {
        missingFields.add('Description');
      }

      if (stepProvider.nombrePlaces == null) {
        missingFields.add('Nombre de places');
      }

      if (stepProvider.ageRange == null) {
        missingFields.add('Tranche d\'âge');
      }

      if (stepProvider.location == null) {
        missingFields.add('Localisation');
      }

      if (missingFields.isNotEmpty) {
        _showValidationDialog(context, missingFields);
        return;
      }
    } else if (stepProvider.currentStep == 1) {
      // Validation pour la deuxième étape
      if (stepProvider.prices == null || stepProvider.prices!.isEmpty) {
        _showValidationDialog(context, [
          'Au moins un type de cotisation avec prix',
        ]);
        return;
      }
    } else if (stepProvider.currentStep == 2) {
      if (stepProvider.photos == null || stepProvider.photos!.isEmpty) {
        _showValidationDialog(context, ['Au moins une photo']);
        return;
      }
    } else if (stepProvider.currentStep == 3) {
      if (stepProvider.profs == null || stepProvider.profs!.isEmpty) {
        _showValidationDialog(context, [
          'Au moins un professeurs / coach / ...',
        ]);
        return;
      }
    } else if (stepProvider.currentStep == 4) {
      // Validation pour la cinquième étape
      // Ajoutez votre logique de validation ici
    } else if (stepProvider.currentStep == 5) {
      // Validation pour la sixième étape
      // Ajoutez votre logique de validation ici
    } else if (stepProvider.currentStep == 6) {
      // Validation pour la septième étape
      // Ajoutez votre logique de validation ici
    }

    // if (stepProvider.currentStep == 0) {
    //   // Validation pour la première étape
    //   List<String> missingFields = [];
    //
    //   if (stepProvider.nom == null || stepProvider.nom!.trim().isEmpty) {
    //     missingFields.add('Nom');
    //   }
    //
    //   if (stepProvider.description == null ||
    //       stepProvider.description!.trim().isEmpty) {
    //     missingFields.add('Description');
    //   }
    //
    //   if (stepProvider.nombrePlaces == null) {
    //     missingFields.add('Nombre de places');
    //   }
    //
    //   if (stepProvider.ageRange == null) {
    //     missingFields.add('Tranche d\'age');
    //   }
    //
    //   if (stepProvider.location == null) {
    //     missingFields.add('Localisation');
    //   }
    //
    //   if (missingFields.isNotEmpty) {
    //     _showValidationDialog(context, missingFields);
    //     return;
    //   }
    // } else if (stepProvider.currentStep == 1) {
    //   // Validation pour la deuxième étape
    //   if (stepProvider.prices == null || stepProvider.prices!.isEmpty) {
    //     _showValidationDialog(context, [
    //       'Au moins un type de cotisation avec prix',
    //     ]);
    //     return;
    //   }
    // }

    // Si validation réussie ou autre étape
    stepProvider.nextStep();
  }

  void _showValidationDialog(BuildContext context, List<String> missingFields) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Champs manquants'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Veuillez remplir les champs suivants :'),
              SizedBox(height: 8),
              ...missingFields
                  .map(
                    (field) => Padding(
                      padding: EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        '• $field',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class CustomStepper extends StatefulWidget {
  final List<String> steps;
  final int currentStep;
  final VoidCallback onStepContinue;
  final VoidCallback onStepCancel;

  const CustomStepper({
    required this.steps,
    required this.currentStep,
    required this.onStepContinue,
    required this.onStepCancel,
  });

  @override
  State<CustomStepper> createState() => _CustomStepperState();
}

class _CustomStepperState extends State<CustomStepper> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: widget.currentStep,
            children: [
              // Première étape avec formulaire
              IntrinsicHeight(child: InformationsDeBaseForm()),
              PrixCotisationForm(),
              CoursesPhotos(),
              // Contenu de l'étape 2 : Professeurs / Coachs
              Profs(),
              Horraires(),
              Saisons(),
              FinalView(),
              // Autres étapes
              // ...widget.steps.skip(1).map((step) {
              //   return Center(child: Text('Content for $step'));
              // }).toList(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.currentStep > 0 ? widget.onStepCancel : null,
                child: Text('Précédent'),
              ),
              ElevatedButton(
                onPressed:
                    widget.currentStep < widget.steps.length - 1
                        ? widget.onStepContinue
                        : null,
                child: Text('Suivant'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InformationsDeBaseForm extends StatefulWidget {
  @override
  _InformationsDeBaseFormState createState() => _InformationsDeBaseFormState();
}

class _InformationsDeBaseFormState extends State<InformationsDeBaseForm> {
  final _formKey1 = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeNumberController = TextEditingController();
  RangeValues _ageRange = const RangeValues(0, 30);
  String? _ageRangeError;

  String _locationText = 'Aucune localisation sélectionnée';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // void _loadInitialData() {
  //   final stepProvider = Provider.of<StepProvider1>(context, listen: false);
  //   _courseNameController.text = stepProvider.nom ?? '';
  //   _descriptionController.text = stepProvider.description ?? '';
  //   _ageRange = stepProvider.priceRange ?? RangeValues(3, 10);
  //   Provider.of<StepProvider1>(
  //     context,
  //     listen: false,
  //   ).updateAgeRange(_ageRange);
  //   _placeNumberController.text = (stepProvider.nombrePlaces ?? 0).toString();
  //
  //   notifier.value = stepProvider.location;
  //   if (notifier.value != null) {
  //     _locationText =
  //         'Lat: ${notifier.value!.latitude.toStringAsFixed(4)}, Lng: ${notifier.value!.longitude.toStringAsFixed(4)}';
  //   }
  //
  // }

  bool _isSliderInitialState = true;
  void _loadInitialData() {
    final stepProvider = Provider.of<StepProvider1>(context, listen: false);
    _courseNameController.text = stepProvider.nom ?? '';
    _descriptionController.text = stepProvider.description ?? '';
    //_ageRange = stepProvider.priceRange ?? RangeValues(3, 18);
    _placeNumberController.text = (stepProvider.nombrePlaces ?? 0).toString();

    notifier.value = stepProvider.location;
    if (notifier.value != null) {
      _locationText =
          'Lat: ${notifier.value!.latitude.toStringAsFixed(4)}, Lng: ${notifier.value!.longitude.toStringAsFixed(4)}';
    }

    // Use addPostFrameCallback to defer the state update
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<StepProvider1>(
    //     context,
    //     listen: false,
    //   ).updateAgeRange(_ageRange);
    // });
  }

  ValueNotifier<osm.GeoPoint?> notifier = ValueNotifier(null);
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      return "${place.locality}, ${place.country}"; //${place.street}, ${place.postalCode},
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de base',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),

            // Champ Nom
            TextFormField(
              controller: _courseNameController,
              textAlign: TextAlign.justify,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                //   labelText: 'Nom du cours*',
                hintText: 'Entrez le nom du cours',
                hintStyle: TextStyle(fontWeight: FontWeight.w500),
              ),
              onChanged: (value) {
                Provider.of<StepProvider1>(
                  context,
                  listen: false,
                ).updateNom(value);
              },
            ),
            SizedBox(height: 16),

            // Champ Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textAlign: TextAlign.justify,
              textAlignVertical: TextAlignVertical.top,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                //labelText: 'Description*',
                hintText: 'Décrivez votre cours',
                alignLabelWithHint: true,
                border: InputBorder.none,
              ),
              onChanged: (value) {
                Provider.of<StepProvider1>(
                  context,
                  listen: false,
                ).updateDescription(value);
              },
            ),
            SizedBox(height: 24),

            // Nombre de places
            TextFormField(
              controller: _placeNumberController,
              maxLines: 1,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nombre de Places*',
                hintText: 'Entrer Nombre de Places',
                // border: OutlineInputBorder(),
              ),
              onTap: () {
                setState(() {
                  _placeNumberController.clear();
                });
              },
              onChanged: (value) {
                Provider.of<StepProvider1>(
                  context,
                  listen: false,
                ).updateNombrePlaces(int.tryParse(value)!);
              },
            ),

            SizedBox(height: 24),

            // Range Slider pour les prix
            if (_ageRangeError != null)
              Text(
                _ageRangeError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              Text(
                'Tranche d\'âge*: ${_ageRange.start.round()}ans - ${_ageRange.end.round()}ans',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            // RangeSlider(
            //   values: _ageRange,
            //   min: 3,
            //   max: 30,
            //   divisions: 27,
            //   labels: RangeLabels(
            //     '${_ageRange.start.round()} ans',
            //     '${_ageRange.end.round()} ans',
            //   ),
            //   onChanged: (values) {
            //     setState(() {
            //       _ageRange = values;
            //     });
            //     Provider.of<StepProvider1>(
            //       context,
            //       listen: false,
            //     ).updateAgeRange(values);
            //   },
            //   onChangeEnd: (values) {
            //     if (values.end - values.start < 1) {
            //       setState(() {
            //         _ageRangeError = 'La plage doit être d\'au moins 1 an';
            //       });
            //     }
            //   },
            // ),
            RangeSlider(
              values: _ageRange,
              min: 0,
              max: 30,
              divisions: 30,
              labels:
                  _isSliderInitialState
                      ? RangeLabels('', '')
                      : RangeLabels(
                        '${_ageRange.start.round()} ans',
                        '${_ageRange.end.round()} ans',
                      ),
              onChanged: (RangeValues values) {
                setState(() {
                  _ageRange = values;
                  _isSliderInitialState = false;
                });
                Provider.of<StepProvider1>(
                  context,
                  listen: false,
                ).updateAgeRange(values);
              },
            ),
            // Localisation
            SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Localisation*  ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                notifier.value == null
                    ? IconButton(
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

                          Provider.of<StepProvider1>(
                            context,
                            listen: false,
                          ).updateLocation(p);
                        }
                      },
                      icon: Icon(Icons.location_on_sharp),
                    )
                    : IconButton(
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

                          Provider.of<StepProvider1>(
                            context,
                            listen: false,
                          ).updateLocation(p);
                        }
                      },
                      icon: Icon(Icons.my_location, color: Colors.green),
                    ),
                Expanded(
                  child:
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
                                      return Text(
                                        snapshot.data!,

                                        style: TextStyle(color: Colors.green),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Text(
                                        '--------',
                                        //   'Erreur: ${snapshot.error}',
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    } else {
                                      return LinearProgressIndicator();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                ),
              ],
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _descriptionController.dispose();
    _placeNumberController.dispose();
    //_ageRangeError!.isEmpty;
    notifier.value == null;
    super.dispose();
  }
}

class PrixCotisationForm extends StatefulWidget {
  @override
  _PrixCotisationFormState createState() => _PrixCotisationFormState();
}

class _PrixCotisationFormState extends State<PrixCotisationForm> {
  final List<String> cotisationTypes = ['annuel', 'mensuel', 'seance'];
  String _selectedType = 'annuel';
  final _priceController = TextEditingController();
  late Map<String, double> _prices;

  @override
  void initState() {
    super.initState();
    final stepProvider = Provider.of<StepProvider1>(context, listen: false);
    _prices = Map<String, double>.from(stepProvider.prices ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prix et Cotisations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 24),

          // Formulaire d'ajout
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Ajouter un type de cotisation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),

                // Dropdown pour le type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type de cotisation',
                    //border: OutlineInputBorder(),
                  ),
                  items:
                      cotisationTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type.capitalize()),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Champ prix
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Prix (DZD)',
                    hintText: 'Entrez le prix',
                    //    border: OutlineInputBorder(),
                    suffixText: 'DZD',
                  ),
                ),
                SizedBox(height: 16),

                // Bouton ajouter
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addPrice,
                    icon: Icon(Icons.add),
                    label: Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Liste des prix ajoutés
          if (_prices.isNotEmpty) ...[
            Text(
              'Types de cotisation ajoutés:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _prices.length,
              itemBuilder: (context, index) {
                String type = _prices.keys.elementAt(index);
                double price = _prices[type]!;

                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        _getIconForType(type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      type.capitalize(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Prix: ${price.toStringAsFixed(2)} DZD'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removePrice(type),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.price_change_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun type de cotisation ajouté',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ajoutez au moins un type de cotisation pour continuer',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 32),
        ],
      ),
    );
  }

  void _addPrice() {
    String priceText = _priceController.text.trim();

    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer un prix'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer un prix valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_prices.containsKey(_selectedType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ce type de cotisation existe déjà'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _prices[_selectedType] = price;
    });

    // Mettre à jour le provider
    Provider.of<StepProvider1>(context, listen: false).updatePrices(_prices);

    // Réinitialiser le formulaire
    _priceController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Type de cotisation ajouté avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removePrice(String type) {
    setState(() {
      _prices.remove(type);
    });

    // Mettre à jour le provider
    Provider.of<StepProvider1>(context, listen: false).updatePrices(_prices);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Type de cotisation supprimé'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'annuel':
        return FontAwesomeIcons.calendar;
      case 'mensuel':
        return Icons.calendar_view_month;
      case 'seance':
        return Icons.schedule;
      default:
        return Icons.monetization_on;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}

class CoursesPhotos extends StatefulWidget {
  @override
  _CoursesPhotosState createState() => _CoursesPhotosState();
}

class _CoursesPhotosState extends State<CoursesPhotos> {
  List<String> _photos = [];
  bool _showAllPhotos = false;
  bool _expanded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mettre à jour l'état local avec les données actuelles du Provider
    final stepProvider = Provider.of<StepProvider1>(context);
    if (_photos != stepProvider.photos) {
      setState(() {
        _photos = List<String>.from(stepProvider.photos ?? []);
      });
    }
  }

  @override
  List<Widget> _buildPhotoWidgets() {
    List<Widget> photoWidgets = [];

    int displayCount =
        _expanded ? _photos.length : (_photos.length > 4 ? 4 : _photos.length);

    for (int index = 0; index < displayCount; index++) {
      if (index == 3 && !_expanded && _photos.length > 4) {
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
                  child: Image.file(File(_photos[index]), fit: BoxFit.cover),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Text(
                    '+${_photos.length - 4}',
                    style: TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (index == _photos.length - 1 && _expanded) {
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
                  child: Image.file(File(_photos[index]), fit: BoxFit.cover),
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
                child: Image.file(File(_photos[index]), fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _photos.removeAt(index);
                    });

                    Provider.of<StepProvider1>(
                      context,
                      listen: false,
                    ).updatePhotos(_photos);
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

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Image.file(
              File(_photos[index]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed:
                    () => setState(() {
                      _photos.removeAt(index);
                    }),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      for (var pickedFile in pickedFiles) {
        setState(() {
          _photos.add(pickedFile.path);
          // _photos.addAll(pickedFiles.map((file) => file.path).toList());
        });
        // Mettre à jour le provider
        Provider.of<StepProvider1>(
          context,
          listen: false,
        ).updatePhotos(_photos);
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _photos.add(pickedFile.path);
      });
      // Mettre à jour le provider
      Provider.of<StepProvider1>(context, listen: false).updatePhotos(_photos);
    }
  }

  // Future<void> _pickImages() async {
  //   final picker = ImagePicker();
  //   final pickedFiles = await picker.pickMultiImage();
  //
  //   if (pickedFiles != null) {
  //     for (var pickedFile in pickedFiles) {
  //       _photos.add(pickedFile.path);
  //     }
  //   }
  // }
  //
  // Future<void> _takePhoto() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.camera);
  //
  //   if (pickedFile != null) {
  //     _photos.add(pickedFile.path);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ListView(
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
          //  _buildPhotoGrid(),
          Center(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _buildPhotoWidgets(),
            ),
          ),
        ],
      ),
    );
  }
}

class Profs extends StatefulWidget {
  const Profs({super.key});

  @override
  State<Profs> createState() => _ProfsState();
}

class _ProfsState extends State<Profs> {
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
    // _resetState();
    _loadProfsList();
    _profSearchController.addListener(filterProfs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfProvider>(
        context,
        listen: false,
      ).fetchProfessorsFromFirestore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stepProvider = Provider.of<StepProvider1>(context);
    if (stepProvider.profs != null && _selectedProfs != stepProvider.profs) {
      setState(() {
        _selectedProfs = List<UserModel>.from(stepProvider.profs!);
      });
    }
  }

  void _resetState() {
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
    _profSearchController.dispose();
    _newProfNameController.dispose();
    _newProfEmailController.dispose();
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
      if (_selectedProfs.contains(prof)) {
        _selectedProfs.remove(prof);
      } else {
        _selectedProfs.add(prof);
      }
      Provider.of<StepProvider1>(
        context,
        listen: false,
      ).updateProfs(_selectedProfs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ListView(
        children: [
          TextField(
            controller: _profSearchController,
            onChanged: (value) => filterProfsWithDebounce(), // Avec debounce
            // ou
            //  onChanged: (value) => filterProfs(), // Version directe
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email, rôle ou initiales...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          TextButton(
            onPressed:
                () => setState(() => _showAddProfForm = !_showAddProfForm),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_showAddProfForm ? Icons.remove : Icons.add, size: 20),
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
                        role.substring(0, 1).toUpperCase() + role.substring(1),
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
              child: Text(
                'Enregistrer & Selectionner\nCoach/Professeur',
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Affichage des profs filtrés
          Consumer2<ProfProvider, StepProvider1>(
            builder: (context, professorsProvider, stepProvider1, child) {
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
                        //  final isSelected = _selectedProfs.contains(prof);
                        // Vérifiez si le professeur est sélectionné dans stepProvider1
                        // Utilisez stepProvider1.profs pour vérifier si le professeur est sélectionné
                        final isSelected =
                            stepProvider1.profs != null &&
                            stepProvider1.profs!.any(
                              (selectedProf) => selectedProf.id == prof.id,
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
                                backgroundImage: CachedNetworkImageProvider(
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
}

class Horraires extends StatefulWidget {
  const Horraires({super.key});

  @override
  State<Horraires> createState() => _HorrairesState();
}

class _HorrairesState extends State<Horraires> {
  List<Schedule> _schedules = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ElevatedButton(
          onPressed: _addSchedule,

          child: Text('Ajouter un horaire'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ...provider.schedules.map((schedule) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        onLongPress: () => provider.removeSchedule(schedule),
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${DateFormat.Hm().format(schedule.startTime)}',
                            ),
                            Text('${DateFormat.Hm().format(schedule.endTime)}'),
                          ],
                        ),
                        title: Text(
                          schedule.days.join(", "),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        // subtitle: Text(
                        //   '${DateFormat.Hm().format(schedule.startTime)} - ${DateFormat.Hm().format(schedule.endTime)}',
                        // ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.removeSchedule(schedule),
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
}

class Saisons extends StatefulWidget {
  const Saisons({super.key});

  @override
  State<Saisons> createState() => _SaisonsState();
}

class _SaisonsState extends State<Saisons> {
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
      key: saisonFormKey,
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

class StepProgressHeader extends StatelessWidget {
  final List<String> steps;

  const StepProgressHeader({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider1>(context);
    final current = stepProvider.currentStep;
    final progress = current / (steps.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              builder:
                  (context, value, _) => Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: SizedBox(
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

class FinalView extends StatefulWidget {
  const FinalView({super.key});

  @override
  State<FinalView> createState() => _FinalViewState();
}

class _FinalViewState extends State<FinalView> {
  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider1>(context);
    final user = Provider.of<UserProvider>(context).user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Nom du cours: ${stepProvider.nom ?? "Non spécifié"}'),
        const SizedBox(height: 8),
        Text('Description: ${stepProvider.description ?? "Non spécifiée"}'),
        const SizedBox(height: 8),
        Text(
          'Nombre de places: ${stepProvider.nombrePlaces?.toString() ?? "Non spécifié"}',
        ),
        const SizedBox(height: 8),
        Text(
          'Tranche d\'âge: ${stepProvider.ageRange != null ? "${stepProvider.ageRange!.start.round()} - ${stepProvider.ageRange!.end.round()} ans" : "Non spécifiée"}',
        ),
        const SizedBox(height: 20),
        const Text(
          'Photos des cours:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (stepProvider.photos != null && stepProvider.photos!.isNotEmpty)
          Wrap(
            spacing: 8,
            children:
                stepProvider.photos!.map((photo) {
                  return Image.file(
                    File(photo),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  );
                }).toList(),
          )
        else
          const Text("Aucune photo disponible"),
        const SizedBox(height: 20),
        const Text(
          'Professeurs:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (stepProvider.profs != null && stepProvider.profs!.isNotEmpty)
          Wrap(
            spacing: 8,
            children:
                stepProvider.profs!.map((prof) {
                  return Chip(label: Text(prof.name));
                }).toList(),
          )
        else
          const Text("Aucun professeur sélectionné"),
        const SizedBox(height: 20),
        if (stepProvider.location != null)
          Text(
            'Localisation: Lat: ${stepProvider.location!.latitude.toStringAsFixed(4)}, Lng: ${stepProvider.location!.longitude.toStringAsFixed(4)}',
          )
        else
          const Text("Aucune localisation sélectionnée"),
        const SizedBox(height: 20),
        if (stepProvider.prices != null && stepProvider.prices!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prix:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...stepProvider.prices!.entries.map((entry) {
                return Text('${entry.key}: ${entry.value}');
              }).toList(),
            ],
          )
        else
          const Text("Aucun prix spécifié"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _saveCourse(user),
          child: const Text('Soumettre'),
        ),
      ],
    );
  }

  Future<void> _saveCourse(user) async {
    final stepProvider = Provider.of<StepProvider1>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    List<String> photoUrls = [];
    ValueNotifier<int> current = ValueNotifier<int>(0);
    int total = stepProvider.photos?.length ?? 0;

    _showStylishProgressDialog(context, current, total);

    try {
      final futures =
          stepProvider.photos?.map((photo) async {
            if (!photo.startsWith('http')) {
              final compressed = await _compressImageToWebP(photo);

              final ref = FirebaseStorage.instance.ref().child(
                'course_photos/${DateTime.now().millisecondsSinceEpoch}.webp',
              );

              if (compressed != null) {
                await ref.putData(
                  compressed,
                  SettableMetadata(contentType: 'image/webp'),
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
          }).toList() ??
          [];

      photoUrls = await Future.wait(futures);

      final docRef =
          firestore.FirebaseFirestore.instance.collection('courses').doc();

      final course = Course(
        id: docRef.id,
        name: stepProvider.nom ?? '',
        clubId: user!.id, // Assurez-vous d'avoir l'ID de l'utilisateur
        description: stepProvider.description ?? '',
        schedules: courseProvider.schedules,
        ageRange:
            stepProvider.ageRange != null
                ? '${stepProvider.ageRange!.start.round()}-${stepProvider.ageRange!.end.round()}'
                : '0-0',
        profIds: stepProvider.profs?.map((user) => user.id).toList() ?? [],
        photos: photoUrls,
        placeNumber: stepProvider.nombrePlaces ?? 0,
        createdAt: DateTime.now(),
        saisonStart: DateTime.now(), // Assurez-vous d'avoir la date de début
        saisonEnd: DateTime.now(), // Assurez-vous d'avoir la date de fin
        location:
            stepProvider.location != null
                ? firestore.GeoPoint(
                  stepProvider.location!.latitude,
                  stepProvider.location!.longitude,
                )
                : firestore.GeoPoint(0, 0),
      );

      await docRef.set(course.toMap(), firestore.SetOptions(merge: true));

      await firestore.FirebaseFirestore.instance
          .collection('userModel')
          .doc('user_id') // Assurez-vous d'avoir l'ID de l'utilisateur
          .set({
            'courses': firestore.FieldValue.arrayUnion([course.id]),
          }, firestore.SetOptions(merge: true));

      Navigator.of(context).pop(); // Ferme le dialog de progression

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cours sauvegardé avec succès!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyApp1()),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      print(e);
    }
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
}

// class FinalView1 extends StatefulWidget {
//   const FinalView1({super.key});
//
//   @override
//   State<FinalView1> createState() => _FinalView1State();
// }
//
// class _FinalView1State extends State<FinalView1> {
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       //crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Nom du cours: ${_courseNameController.text}'),
//         Text('Description: ${_descriptionController.text}'),
//         Text('Nombre de Place: ${_placeNumberController.text}'),
//         Text(
//           'Tranche d\'âge: ${_ageRange.start.round()} - ${_ageRange.end.round()} ans',
//         ),
//         SizedBox(height: 20),
//         Text(
//           'Photos des cours:',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         Wrap(
//           spacing: 8,
//           children:
//               _photos.map((photo) {
//                 return Image.file(
//                   File(photo),
//                   width: 100,
//                   height: 100,
//                   fit: BoxFit.cover,
//                 );
//               }).toList(),
//         ),
//         SizedBox(height: 20),
//         Text('Professeurs:', style: TextStyle(fontWeight: FontWeight.bold)),
//         Wrap(
//           spacing: 8,
//           children:
//               _selectedProfs.map((prof) {
//                 return Chip(
//                   label: Text(prof.name),
//                   deleteIcon: Icon(Icons.close, size: 18),
//                   onDeleted: () => _toggleProfSelection(prof),
//                 );
//               }).toList(),
//         ),
//         SizedBox(height: 20),
//         Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15.0),
//             side: BorderSide(
//               color: Colors.blueAccent,
//               width: 2.0,
//             ), // Bordure colorée
//           ),
//           elevation: 8, // Ombre plus prononcée
//           margin: EdgeInsets.symmetric(vertical: 8.0), // Marge extérieure
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Saison:',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                     color: Colors.blueAccent, // Couleur du texte
//                   ),
//                 ),
//                 Divider(
//                   color: Colors.blueAccent,
//                   thickness: 1.5,
//                 ), // Ligne de séparation
//                 SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Début',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           dateDebut != null
//                               ? DateFormat('dd/MM/yyyy').format(dateDebut!)
//                               : '??',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           'Fin',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           dateFin != null
//                               ? DateFormat('dd/MM/yyyy').format(dateFin!)
//                               : '??',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//
//         // Dans l'étape Aperçu
//         // Ajoutez l'affichage de la localisation dans l'aperçu
//         SizedBox(height: 20),
//         // Affichage des horaires
//         SizedBox(height: 20),
//         Text('Horaires:', style: TextStyle(fontWeight: FontWeight.bold)),
//         Consumer<CourseProvider>(
//           builder: (context, provider, child) {
//             if (provider.schedules.isNotEmpty) {
//               _schedules = provider.schedules;
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(height: 16),
//                   Text(
//                     'Horaires ajoutés:',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   SizedBox(height: 8),
//                   ...provider.schedules.map((schedule) {
//                     return Card(
//                       margin: EdgeInsets.symmetric(vertical: 4),
//                       child: ListTile(
//                         title: Text(
//                           schedule.days.join(", "),
//                           style: TextStyle(fontWeight: FontWeight.w500),
//                         ),
//                         subtitle: Text(
//                           '${DateFormat.Hm().format(schedule.startTime)} - ${DateFormat.Hm().format(schedule.endTime)}',
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ],
//               );
//             } else {
//               return SizedBox.shrink();
//             }
//           },
//         ),
//         SizedBox(height: 20),
//         ElevatedButton(
//           onPressed: _saveCourse,
//           child: Text('Submit to Storage'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _saveCourse() async {
//     final courseProvider = Provider.of<CourseProvider>(context, listen: false);
//     List<String> photoUrls = [];
//     ValueNotifier<int> current = ValueNotifier<int>(0);
//     int total = _photos.length;
//
//     _showStylishProgressDialog(context, current, total);
//
//     try {
//       final futures =
//           _photos.map((photo) async {
//             if (!photo.startsWith('http')) {
//               final compressed = await _compressImageToWebP(photo);
//
//               final ref = firebase_storage.FirebaseStorage.instance.ref().child(
//                 'course_photos/${DateTime.now().millisecondsSinceEpoch}.webp',
//               );
//
//               if (compressed != null) {
//                 await ref.putData(
//                   compressed,
//                   firebase_storage.SettableMetadata(contentType: 'image/webp'),
//                 );
//               } else {
//                 await ref.putFile(File(photo));
//               }
//
//               final url = await ref.getDownloadURL();
//               current.value++;
//
//               return url;
//             } else {
//               current.value++;
//               return photo;
//             }
//           }).toList();
//
//       photoUrls = await Future.wait(futures);
//
//       final docRef =
//           firestore.FirebaseFirestore.instance.collection('courses').doc();
//
//       final course = Course(
//         id: docRef.id,
//         name: _courseNameController.text,
//         clubId: widget.user.id,
//         description: _descriptionController.text,
//         schedules: courseProvider.schedules,
//         ageRange: '${_ageRange.start.round()}-${_ageRange.end.round()}',
//         profIds: _selectedProfs.map((user) => user.id).toList(),
//         photos: photoUrls,
//         placeNumber: int.parse(_placeNumberController.text.trim()),
//         createdAt: DateTime.now(),
//         saisonStart: DateFormat('dd/MM/yyyy').parseStrict(debutController.text),
//         saisonEnd: DateFormat('dd/MM/yyyy').parseStrict(finController.text),
//         location: firestore.GeoPoint(
//           notifier.value!.latitude,
//           notifier.value!.longitude,
//         ),
//       );
//       print(course);
//       await docRef.set(course.toMap(), firestore.SetOptions(merge: true));
//
//       await firestore.FirebaseFirestore.instance
//           .collection('userModel')
//           .doc(widget.user.id)
//           .set({
//             'courses': firestore.FieldValue.arrayUnion([course.id]),
//           }, firestore.SetOptions(merge: true));
//
//       Navigator.of(context).pop(); // Ferme le progress dialog
//
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Cours sauvegardé avec succès!')));
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => MyApp1()),
//       );
//     } catch (e) {
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
//       print('*****************************************');
//       print(e);
//     }
//   }
//
//   void _showStylishProgressDialog(
//     BuildContext context,
//     ValueNotifier<int> current,
//     int total,
//   ) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (_) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             content: ValueListenableBuilder<int>(
//               valueListenable: current,
//               builder: (context, value, _) {
//                 return Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     SizedBox(
//                       height: 100,
//                       width: 100,
//                       child: Lottie.asset(
//                         'assets/lotties/1 (71).json',
//                         repeat: true,
//                       ), // ajoute un fichier lottie ici
//                     ),
//                     SizedBox(height: 12),
//                     Text(
//                       "Chargement des images...",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     LinearProgressIndicator(
//                       value: total > 0 ? value / total : null,
//                       color: Colors.teal,
//                     ),
//                     SizedBox(height: 8),
//                     Text('$value / $total'),
//                   ],
//                 );
//               },
//             ),
//           ),
//     );
//   }
// }

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

// Provider.of<StepProvider1>(
// context,
// listen: false,
// ).updatePhotos(_photos);

void _fillTestData(BuildContext context) {
  final stepProvider = Provider.of<StepProvider1>(context, listen: false);
  final courseProvider = Provider.of<CourseProvider>(context, listen: false);

  // Remplir les informations de base
  stepProvider.updateNom('Cours de Test');
  stepProvider.updateDescription('Description du cours de test.');
  stepProvider.updateNombrePlaces(30);
  stepProvider.updateAgeRange(RangeValues(10, 20));
  stepProvider.updateLocation(
    osm.GeoPoint(latitude: 36.7538, longitude: 3.0588),
  );

  // Remplir les prix
  stepProvider.updatePrices({
    'annuel': 1000.0,
    'mensuel': 100.0,
    'seance': 10.0,
  });

  // Remplir les photos
  stepProvider.updatePhotos(['path/to/photo1.jpg', 'path/to/photo2.jpg']);

  // Remplir les professeurs
  stepProvider.updateProfs([
    UserModel(
      id: '1',
      name: 'Professeur 1',
      email: 'prof1@test.com',
      role: 'professeur',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      editedAt: DateTime.now(),
    ),
    UserModel(
      id: '2',
      name: 'Professeur 2',
      email: 'prof2@test.com',
      role: 'professeur',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      editedAt: DateTime.now(),
    ),
  ]);

  // Remplir les horaires
  courseProvider.addSchedule(
    Schedule(
      id: '1',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 2)),
      days: ['Lundi', 'Mercredi', 'Vendredi'],
      createdAt: DateTime.now(),
    ),
  );
}
