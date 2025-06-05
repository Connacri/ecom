import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../aGeo/map/LocationAppExample.dart';
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
        missingFields.add('Tranche d\'age');
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
    }

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

class CustomStepper extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: currentStep,
            children: [
              // Première étape avec formulaire
              IntrinsicHeight(child: InformationsDeBaseForm()),
              PrixCotisationForm(),
              CoursesPhotos(),

              // Autres étapes
              ...steps.skip(1).map((step) {
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
                onPressed: currentStep > 0 ? onStepCancel : null,
                child: Text('Précédent'),
              ),
              ElevatedButton(
                onPressed:
                    currentStep < steps.length - 1 ? onStepContinue : null,
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
        _photos.add(pickedFile.path);
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _photos.add(pickedFile.path);
    }
  }

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
