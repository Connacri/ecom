// import 'package:flutter/material.dart';
// import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
//
// class LocationStepperPage extends StatefulWidget {
//   const LocationStepperPage({Key? key}) : super(key: key);
//
//   @override
//   State<LocationStepperPage> createState() => _LocationStepperPageState();
// }
//
// class _LocationStepperPageState extends State<LocationStepperPage> {
//   int currentStep = 0;
//   GeoPoint? selectedLocation;
//   String selectedAddress = '';
//   late MapController mapController;
//   GeoPoint? lastGeoPoint;
//
//   @override
//   void initState() {
//     super.initState();
//     mapController = MapController.withUserPosition(
//       trackUserLocation: UserTrackingOption(
//         enableTracking: true,
//         unFollowUser: false,
//       ),
//     );
//
//     mapController.listenerMapLongTapping.addListener(() async {
//       if (mapController.listenerMapLongTapping.value != null) {
//         GeoPoint tappedPoint = mapController.listenerMapLongTapping.value!;
//         print("Point cliqué : $tappedPoint");
//
//         setState(() {
//           selectedLocation = tappedPoint;
//         });
//
//         if (lastGeoPoint != null) {
//           await mapController.changeLocationMarker(
//             oldLocation: lastGeoPoint!,
//             newLocation: tappedPoint,
//             markerIcon: const MarkerIcon(
//               icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
//             ),
//           );
//         } else {
//           await _addMarker(tappedPoint);
//         }
//         lastGeoPoint = tappedPoint;
//         await _getAddressFromCoordinates(tappedPoint);
//       }
//     });
//   }
//
//   Future<void> _addMarker(GeoPoint geoPoint) async {
//     try {
//       await mapController.addMarker(
//         geoPoint,
//         markerIcon: const MarkerIcon(
//           icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   Future<void> _selectLocation(GeoPoint geoPoint) async {
//     setState(() {
//       selectedLocation = geoPoint;
//     });
//     try {
//       await mapController.clearAllRoads();
//       await mapController.disabledTracking();
//
//       await mapController.addMarker(
//         geoPoint,
//         markerIcon: const MarkerIcon(
//           icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
//         ),
//       );
//       _getAddressFromCoordinates(geoPoint);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     mapController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sélection de Localisation'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: Theme(
//         data: Theme.of(
//           context,
//         ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
//         child: Stepper(
//           currentStep: currentStep,
//           onStepTapped: (step) => setState(() => currentStep = step),
//           controlsBuilder: (context, details) {
//             return Row(
//               children: [
//                 if (details.stepIndex < 1)
//                   ElevatedButton(
//                     onPressed: details.onStepContinue,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text('Suivant'),
//                   ),
//                 const SizedBox(width: 8),
//                 if (details.stepIndex > 0)
//                   TextButton(
//                     onPressed: details.onStepCancel,
//                     child: const Text('Retour'),
//                   ),
//                 if (details.stepIndex == 1)
//                   ElevatedButton(
//                     onPressed: _showCompletionDialog,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text('Terminer'),
//                   ),
//               ],
//             );
//           },
//           onStepContinue: () {
//             if (currentStep < 1 && _validateCurrentStep()) {
//               setState(() => currentStep++);
//             }
//           },
//           onStepCancel: () {
//             if (currentStep > 0) {
//               setState(() => currentStep--);
//             }
//           },
//           steps: [
//             Step(
//               title: const Text('Localisation'),
//               content: _buildLocationPickerStep(),
//               isActive: currentStep >= 0,
//               state: currentStep > 0 ? StepState.complete : StepState.indexed,
//             ),
//             Step(
//               title: const Text('Aperçu'),
//               content: _buildLocationPreviewStep(),
//               isActive: currentStep >= 1,
//               state: currentStep == 1 ? StepState.indexed : StepState.disabled,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLocationPickerStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Sélectionnez votre localisation sur la carte',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 10),
//         if (selectedLocation != null)
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               border: Border.all(color: Colors.green.shade200),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.green.shade600),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Localisation sélectionnée:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}',
//                       ),
//                       Text(
//                         'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
//                       ),
//                       if (selectedAddress.isNotEmpty)
//                         Text('Adresse: $selectedAddress'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         const SizedBox(height: 16),
//         Container(
//           height: 400,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: OSMFlutter(
//               controller: mapController,
//               osmOption: OSMOption(
//                 userTrackingOption: const UserTrackingOption(
//                   enableTracking: false,
//                   unFollowUser: false,
//                 ),
//                 zoomOption: const ZoomOption(
//                   initZoom: 12,
//                   minZoomLevel: 3,
//                   maxZoomLevel: 19,
//                   stepZoom: 1.0,
//                 ),
//                 userLocationMarker: UserLocationMaker(
//                   personMarker: MarkerIcon(
//                     icon: Icon(Icons.location_on, color: Colors.red, size: 48),
//                   ),
//                   directionArrowMarker: MarkerIcon(
//                     icon: Icon(Icons.navigation, color: Colors.red, size: 48),
//                   ),
//                 ),
//                 showZoomController: true,
//                 showDefaultInfoWindow: true,
//                 enableRotationByGesture: true,
//               ),
//               onGeoPointClicked: (geoPoint) async {
//                 await _selectLocation(geoPoint);
//               },
//               mapIsLoading: const Center(child: CircularProgressIndicator()),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _getCurrentLocation,
//                 icon: const Icon(Icons.my_location),
//                 label: const Text('MyPosition'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: selectedLocation != null ? _clearSelection : null,
//                 icon: const Icon(Icons.clear),
//                 label: const Text('Effacer'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildLocationPreviewStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Aperçu de votre sélection',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 20),
//         Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Row(
//                   children: [
//                     Icon(Icons.location_on, color: Colors.red),
//                     SizedBox(width: 8),
//                     Text(
//                       'Localisation sélectionnée',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(),
//                 if (selectedLocation != null) ...[
//                   Text(
//                     'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
//                   ),
//                   Text(
//                     'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
//                   ),
//                   if (selectedAddress.isNotEmpty)
//                     Text('Adresse: $selectedAddress'),
//                 ] else
//                   const Text('Aucune localisation sélectionnée'),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         if (selectedLocation != null) ...[
//           const Text(
//             'Aperçu sur la carte:',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             height: 300,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade300),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: OSMFlutter(
//                 controller: MapController(initPosition: selectedLocation!),
//                 osmOption: OSMOption(
//                   zoomOption: const ZoomOption(
//                     initZoom: 16,
//                     minZoomLevel: 10,
//                     maxZoomLevel: 19,
//                   ),
//                   staticPoints: [
//                     StaticPositionGeoPoint(
//                       "selected_location",
//                       const MarkerIcon(
//                         icon: Icon(
//                           Icons.location_pin,
//                           color: Colors.red,
//                           size: 48,
//                         ),
//                       ),
//                       [selectedLocation!],
//                     ),
//                   ],
//                 ),
//                 mapIsLoading: const Center(child: CircularProgressIndicator()),
//               ),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
//
//   Future<void> _getCurrentLocation() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (context) => const AlertDialog(
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Localisation en cours...'),
//               ],
//             ),
//           ),
//     );
//
//     try {
//       await mapController.enableTracking();
//       GeoPoint currentLocation = await mapController.myLocation();
//       Navigator.of(context).pop();
//       await _selectLocation(currentLocation);
//       await mapController.goToLocation(currentLocation);
//     } catch (e) {
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   void _clearSelection() async {
//     if (lastGeoPoint != null) {
//       // Supprimer le marqueur précédent (si le package le permet)
//       await mapController.removeMarker(lastGeoPoint!);
//     }
//
//     setState(() {
//       selectedLocation = null;
//       lastGeoPoint = null;
//     });
//   }
//
//   Future<void> _getAddressFromCoordinates(GeoPoint geoPoint) async {
//     await Future.delayed(const Duration(seconds: 1));
//     setState(() {
//       selectedAddress =
//           'Adresse approximative: ${geoPoint.latitude.toStringAsFixed(4)}, '
//           '${geoPoint.longitude.toStringAsFixed(4)}';
//     });
//   }
//
//   bool _validateCurrentStep() {
//     if (currentStep == 0 && selectedLocation == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Veuillez sélectionner une localisation'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return false;
//     }
//     return true;
//   }
//
//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Sélection terminée'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('Localisation enregistrée avec succès:'),
//                 const SizedBox(height: 16),
//                 if (selectedLocation != null) ...[
//                   Text(
//                     'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
//                   ),
//                   Text(
//                     'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
//                   ),
//                   if (selectedAddress.isNotEmpty)
//                     Text('Adresse: $selectedAddress'),
//                 ],
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//     );
//   }
// }
//
// // import 'package:flutter/material.dart';
// // import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
// //
// // class LocationStepperPage extends StatefulWidget {
// //   const LocationStepperPage({Key? key}) : super(key: key);
// //
// //   @override
// //   State<LocationStepperPage> createState() => _LocationStepperPageState();
// // }
// //
// // class _LocationStepperPageState extends State<LocationStepperPage> {
// //   int currentStep = 0;
// //   GeoPoint? selectedLocation;
// //   String selectedAddress = '';
// //   late MapController mapController;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     mapController = MapController.withUserPosition(
// //       trackUserLocation: UserTrackingOption(
// //         enableTracking: true,
// //         unFollowUser: false,
// //       ),
// //     );
// //
// //     mapController.listenerMapSingleTapping.addListener(() async {
// //       if (mapController.listenerMapSingleTapping.value != null) {
// //         GeoPoint tappedPoint = mapController.listenerMapSingleTapping.value!;
// //         print("Point cliqué : $tappedPoint");
// //
// //         // Mettre à jour selectedLocation avec le tappedPoint
// //         setState(() {
// //           selectedLocation = tappedPoint;
// //         });
// //
// //         // Ajouter un marqueur à l'emplacement cliqué
// //         await _addMarker(tappedPoint);
// //
// //         // Géocodage pour obtenir l'adresse
// //         List<SearchInfo> suggestions = await addressSuggestion(
// //           "${tappedPoint.latitude}, ${tappedPoint.longitude}",
// //         );
// //         if (suggestions.isNotEmpty) {
// //           print("Adresse suggérée : ${suggestions[0].address}");
// //         } else {
// //           print("Aucune adresse trouvée.");
// //         }
// //       }
// //     });
// //   }
// //
// //   /////////////////////////////////////////////////////////////////////
// //   //   void _clearSelection() {
// //   //     setState(() {
// //   //       selectedLocation = null;
// //   //       selectedAddress = '';
// //   //     });
// //   //     if (currentMarkerId != null) {
// //   //       mapController.removeMarker(currentMarkerId!);
// //   //     }
// //   //   }
// //   //   Future<void> _addMarker2(GeoPoint geoPoint) async {
// //   //     try {
// //   //       if (currentMarkerId != null) {
// //   //         await mapController.removeMarker(currentMarkerId!);
// //   //       }
// //   //
// //   //       currentMarkerId = "marker_${geoPoint.latitude}_${geoPoint.longitude}";
// //   //       await mapController.addMarker(
// //   //         geoPoint,
// //   //         markerId: currentMarkerId!,
// //   //         markerIcon: const MarkerIcon(
// //   //           icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
// //   //         ),
// //   //       );
// //   //     } catch (e) {
// //   //       ScaffoldMessenger.of(context).showSnackBar(
// //   //         SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
// //   //       );
// //   //     }
// //   //   }
// //   ///////////////////////////////////////////////////////////////////////
// //   Future<void> _addMarker(GeoPoint geoPoint) async {
// //     try {
// //       print('selectedLocation');
// //       print(selectedLocation);
// //
// //       // Ajouter un marqueur à l'emplacement sélectionné
// //       await mapController.changeLocationMarker(
// //         markerIcon: const MarkerIcon(
// //           icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
// //         ),
// //         oldLocation: geoPoint,
// //         newLocation: geoPoint,
// //       );
// //       await mapController.addMarker(
// //         geoPoint,
// //         markerIcon: const MarkerIcon(
// //           icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
// //         ),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
// //       );
// //     }
// //   }
// //
// //   Future<void> _selectLocation(GeoPoint geoPoint) async {
// //     setState(() {
// //       selectedLocation = geoPoint;
// //     });
// //     try {
// //       await mapController.clearAllRoads();
// //       await mapController.disabledTracking();
// //
// //       // Réinitialiser le contrôleur de carte
// //       mapController = MapController.withUserPosition(
// //         trackUserLocation: UserTrackingOption(
// //           enableTracking: true,
// //           unFollowUser: false,
// //         ),
// //       );
// //
// //       // Ajouter un marqueur à l'emplacement sélectionné
// //       await mapController.addMarker(
// //         geoPoint,
// //         markerIcon: const MarkerIcon(
// //           icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
// //         ),
// //       );
// //       _getAddressFromCoordinates(geoPoint);
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
// //       );
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     mapController.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Sélection de Localisation'),
// //         backgroundColor: Colors.blue,
// //         foregroundColor: Colors.white,
// //       ),
// //       body: Theme(
// //         data: Theme.of(
// //           context,
// //         ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
// //         child: Stepper(
// //           currentStep: currentStep,
// //           onStepTapped: (step) => setState(() => currentStep = step),
// //           controlsBuilder: (context, details) {
// //             return Row(
// //               children: [
// //                 if (details.stepIndex < 1)
// //                   ElevatedButton(
// //                     onPressed: details.onStepContinue,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.blue,
// //                       foregroundColor: Colors.white,
// //                     ),
// //                     child: const Text('Suivant'),
// //                   ),
// //                 const SizedBox(width: 8),
// //                 if (details.stepIndex > 0)
// //                   TextButton(
// //                     onPressed: details.onStepCancel,
// //                     child: const Text('Retour'),
// //                   ),
// //                 if (details.stepIndex == 1)
// //                   ElevatedButton(
// //                     onPressed: _showCompletionDialog,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.green,
// //                       foregroundColor: Colors.white,
// //                     ),
// //                     child: const Text('Terminer'),
// //                   ),
// //               ],
// //             );
// //           },
// //           onStepContinue: () {
// //             if (currentStep < 1 && _validateCurrentStep()) {
// //               setState(() => currentStep++);
// //             }
// //           },
// //           onStepCancel: () {
// //             if (currentStep > 0) {
// //               setState(() => currentStep--);
// //             }
// //           },
// //           steps: [
// //             Step(
// //               title: const Text('Localisation'),
// //               content: _buildLocationPickerStep(),
// //               isActive: currentStep >= 0,
// //               state: currentStep > 0 ? StepState.complete : StepState.indexed,
// //             ),
// //             Step(
// //               title: const Text('Aperçu'),
// //               content: _buildLocationPreviewStep(),
// //               isActive: currentStep >= 1,
// //               state: currentStep == 1 ? StepState.indexed : StepState.disabled,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildLocationPickerStep() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         const Text(
// //           'Sélectionnez votre localisation sur la carte',
// //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
// //         ),
// //         const SizedBox(height: 10),
// //         if (selectedLocation != null)
// //           Container(
// //             padding: const EdgeInsets.all(12),
// //             decoration: BoxDecoration(
// //               color: Colors.green.shade50,
// //               border: Border.all(color: Colors.green.shade200),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Row(
// //               children: [
// //                 Icon(Icons.check_circle, color: Colors.green.shade600),
// //                 const SizedBox(width: 8),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const Text(
// //                         'Localisation sélectionnée:',
// //                         style: TextStyle(fontWeight: FontWeight.bold),
// //                       ),
// //                       Text(
// //                         'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}',
// //                       ),
// //                       Text(
// //                         'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
// //                       ),
// //                       if (selectedAddress.isNotEmpty)
// //                         Text('Adresse: $selectedAddress'),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         const SizedBox(height: 16),
// //         Container(
// //           height: 400,
// //           decoration: BoxDecoration(
// //             border: Border.all(color: Colors.grey.shade300),
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: ClipRRect(
// //             borderRadius: BorderRadius.circular(12),
// //             child: OSMFlutter(
// //               controller: mapController,
// //               osmOption: OSMOption(
// //                 userTrackingOption: const UserTrackingOption(
// //                   enableTracking:
// //                       false, // Assurez-vous que le suivi de l'utilisateur est désactivé
// //                   unFollowUser: true,
// //                 ),
// //                 zoomOption: const ZoomOption(
// //                   initZoom: 12,
// //                   minZoomLevel: 3,
// //                   maxZoomLevel: 19,
// //                   stepZoom: 1.0,
// //                 ),
// //                 userLocationMarker: UserLocationMaker(
// //                   personMarker: MarkerIcon(
// //                     icon: Icon(Icons.location_on, color: Colors.red, size: 48),
// //                   ),
// //                   directionArrowMarker: MarkerIcon(
// //                     icon: Icon(Icons.navigation, color: Colors.red, size: 48),
// //                   ),
// //                 ),
// //                 showZoomController: true,
// //                 showDefaultInfoWindow: true,
// //                 enableRotationByGesture: true,
// //               ),
// //               onGeoPointClicked: (geoPoint) async {
// //                 print('geoPointgeoPointgeoPointgeoPointgeoPointgeoPoint');
// //                 print(geoPoint);
// //                 await _getAddressFromCoordinates(geoPoint);
// //                 await _selectLocation(geoPoint);
// //               },
// //               mapIsLoading: const Center(child: CircularProgressIndicator()),
// //             ),
// //           ),
// //         ),
// //         const SizedBox(height: 12),
// //         Row(
// //           children: [
// //             Expanded(
// //               child: ElevatedButton.icon(
// //                 onPressed: _getCurrentLocation,
// //                 icon: const Icon(Icons.my_location),
// //                 label: const Text('Ma position'),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: Colors.orange,
// //                   foregroundColor: Colors.white,
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(width: 12),
// //             Expanded(
// //               child: ElevatedButton.icon(
// //                 onPressed: selectedLocation != null ? _clearSelection : null,
// //                 icon: const Icon(Icons.clear),
// //                 label: const Text('Effacer'),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: Colors.red,
// //                   foregroundColor: Colors.white,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildLocationPreviewStep() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         const Text(
// //           'Aperçu de votre sélection',
// //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //         ),
// //         const SizedBox(height: 20),
// //         Card(
// //           child: Padding(
// //             padding: const EdgeInsets.all(16),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Row(
// //                   children: [
// //                     Icon(Icons.location_on, color: Colors.red),
// //                     SizedBox(width: 8),
// //                     Text(
// //                       'Localisation sélectionnée',
// //                       style: TextStyle(
// //                         fontWeight: FontWeight.bold,
// //                         fontSize: 16,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const Divider(),
// //                 if (selectedLocation != null) ...[
// //                   Text(
// //                     'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
// //                   ),
// //                   Text(
// //                     'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
// //                   ),
// //                   if (selectedAddress.isNotEmpty)
// //                     Text('Adresse: $selectedAddress'),
// //                 ] else
// //                   const Text('Aucune localisation sélectionnée'),
// //               ],
// //             ),
// //           ),
// //         ),
// //         const SizedBox(height: 16),
// //         if (selectedLocation != null) ...[
// //           const Text(
// //             'Aperçu sur la carte:',
// //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
// //           ),
// //           const SizedBox(height: 8),
// //           Container(
// //             height: 300,
// //             decoration: BoxDecoration(
// //               border: Border.all(color: Colors.grey.shade300),
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //             child: ClipRRect(
// //               borderRadius: BorderRadius.circular(12),
// //               child: OSMFlutter(
// //                 controller: MapController(initPosition: selectedLocation!),
// //                 osmOption: OSMOption(
// //                   zoomOption: const ZoomOption(
// //                     initZoom: 16,
// //                     minZoomLevel: 10,
// //                     maxZoomLevel: 19,
// //                   ),
// //                   staticPoints: [
// //                     StaticPositionGeoPoint(
// //                       "selected_location",
// //                       const MarkerIcon(
// //                         icon: Icon(
// //                           Icons.location_pin,
// //                           color: Colors.red,
// //                           size: 48,
// //                         ),
// //                       ),
// //                       [selectedLocation!],
// //                     ),
// //                   ],
// //                 ),
// //                 mapIsLoading: const Center(child: CircularProgressIndicator()),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   // Future<void> _selectLocation(GeoPoint geoPoint) async {
// //   //   setState(() => selectedLocation = geoPoint);
// //   //   try {
// //   //     await mapController.clearAllRoads();
// //   //     await mapController.disabledTracking();
// //   //     await mapController.addMarker(
// //   //       geoPoint,
// //   //       markerIcon: const MarkerIcon(
// //   //         icon: Icon(Icons.location_pin, color: Colors.red, size: 100),
// //   //       ),
// //   //     );
// //   //     _getAddressFromCoordinates(geoPoint);
// //   //   } catch (e) {
// //   //     ScaffoldMessenger.of(context).showSnackBar(
// //   //       SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
// //   //     );
// //   //   }
// //   // }
// //
// //   Future<void> _getCurrentLocation() async {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder:
// //           (context) => const AlertDialog(
// //             content: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 CircularProgressIndicator(),
// //                 SizedBox(height: 16),
// //                 Text('Localisation en cours...'),
// //               ],
// //             ),
// //           ),
// //     );
// //
// //     try {
// //       await mapController.enableTracking();
// //       GeoPoint currentLocation = await mapController.myLocation();
// //       Navigator.of(context).pop();
// //       await _selectLocation(currentLocation);
// //       await mapController.goToLocation(currentLocation);
// //     } catch (e) {
// //       Navigator.of(context).pop();
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
// //       );
// //     }
// //   }
// //
// //   void _clearSelection() {
// //     setState(() {
// //       selectedLocation = null;
// //       selectedAddress = '';
// //     });
// //     mapController.clearAllRoads();
// //   }
// //
// //   Future<void> _getAddressFromCoordinates(GeoPoint geoPoint) async {
// //     await Future.delayed(const Duration(seconds: 1));
// //     setState(() {
// //       selectedAddress =
// //           'Adresse approximative: ${geoPoint.latitude.toStringAsFixed(4)}, '
// //           '${geoPoint.longitude.toStringAsFixed(4)}';
// //     });
// //   }
// //
// //   bool _validateCurrentStep() {
// //     if (currentStep == 0 && selectedLocation == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Veuillez sélectionner une localisation'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //       return false;
// //     }
// //     return true;
// //   }
// //
// //   void _showCompletionDialog() {
// //     showDialog(
// //       context: context,
// //       builder:
// //           (context) => AlertDialog(
// //             title: const Text('Sélection terminée'),
// //             content: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Text('Localisation enregistrée avec succès:'),
// //                 const SizedBox(height: 16),
// //                 if (selectedLocation != null) ...[
// //                   Text(
// //                     'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
// //                   ),
// //                   Text(
// //                     'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
// //                   ),
// //                   if (selectedAddress.isNotEmpty)
// //                     Text('Adresse: $selectedAddress'),
// //                 ],
// //               ],
// //             ),
// //             actions: [
// //               TextButton(
// //                 onPressed: () => Navigator.of(context).pop(),
// //                 child: const Text('OK'),
// //               ),
// //             ],
// //           ),
// //     );
// //   }
// // }
