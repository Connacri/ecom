// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class MapPage extends StatefulWidget {
//   @override
//   _MapPageState createState() => _MapPageState();
// }
//
// class _MapPageState extends State<MapPage> {
//   late final WebViewController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     // Construire l'URL de l'iframe Embed
//     final url =
//         Uri.https('www.google.com', '/maps/embed/v1/place', {
//           'key': 'AIzaSyAnZOralrik9xxzORmT28puMkGdE-13hQw',
//           'q': 'Eiffel+Tower,Paris,France',
//         }).toString();
//
//     // Charger l'URL dans le WebView
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..loadRequest(Uri.parse(url));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Ma carte Google')),
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }
