import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
      appBar: AppBar(title: Text('Stepper Demo')),
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
              profs(),
              // Autres étapes
              ...widget.steps.skip(1).map((step) {
                return Center(child: Text('Content for $step'));
              }).toList(),
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

class profs extends StatefulWidget {
  const profs({super.key});

  @override
  State<profs> createState() => _profsState();
}

class _profsState extends State<profs> {
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

// Provider.of<StepProvider1>(
// context,
// listen: false,
// ).updatePhotos(_photos);
