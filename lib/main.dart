// main.dart
import 'dart:io';

import 'package:ecom/pages/MyApp.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'activities/providers.dart';
import 'ads_provider.dart';
import 'firebase_options.dart';

// Global navigator key for navigation operations from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the splash screen until initialization completes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Setup background message handling
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize date formatting and timeago localization
  await initializeDateFormatting('fr_FR', null);
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());

  // Initialize localization
  final localizationModel = LocalizationModel();
  await localizationModel.initLocale();

  // Initialize AdMob for supported platforms
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileAds.instance.initialize();
  } else {
    print("Google Mobile Ads not supported on this platform");
  }

  // Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // Remove splash screen
  FlutterNativeSplash.remove();

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationModel()),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
        ChangeNotifierProvider(create: (_) => ClubProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ProfProvider()),
      ],
      child: MyApp(),
    ),
  );
}

// Background message handler for Firebase Cloud Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.messageId}");
}
