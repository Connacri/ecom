import 'dart:io';

import 'package:ecom/0claude/main.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '0chatgpsCourss/providers/user_provider.dart';
import '0claude/FirebaseWrapper.dart';
import 'PlatformUtils.dart';
import 'activities/generated/multiphoto/photo_provider.dart';
import 'activities/providers.dart';
import 'ads_provider.dart';
import 'firebase_options.dart';
import 'pages/MyApp.dart';

// 🌐 Global navigator key for navigation operations from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initializeDateFormatting('fr_FR', null);
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ✅ N'initialiser Firebase QUE sur les plateformes supportées
  if (Platform.isAndroid || Platform.isIOS || kIsWeb) {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // Initialiser Firebase Wrapper
    await FirebaseWrapper.initialize();

    // Activer le mode debug en développement
    FirebaseWrapper.debugMode = true;

    // Afficher les infos Firebase
    FirebaseWrapper.printInfo();
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await MobileAds.instance.initialize();
  } else {
    debugPrint(
      '⚠️ Firebase désactivé sur Desktop (${Platform.operatingSystem})',
    );
  }

  // 🌍 Locale
  final localizationModel = LocalizationModel();
  await localizationModel.initLocale();

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => localizationModel),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
        ChangeNotifierProvider(create: (_) => ChildProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ProfProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => StepProvider()),
        ChangeNotifierProvider(create: (_) => StepProvider1()),
        ChangeNotifierProvider(create: (_) => UserProviderGpt()),
        ChangeNotifierProvider(create: (_) => UserProviderClaude()),

        // ✅ Provider conditionnel selon la plateforme
        if (!PlatformUtils.isDesktop)
          StreamProvider<User?>.value(
            value: FirebaseWrapper.authStateChanges,
            initialData: null,
          ),
        StreamProvider<User?>.value(
          value: FirebaseWrapper.authStateChanges,
          initialData: null,
        ),
      ],
      child: MyApp1(),
      //MyAppClaude(),
      //MyAppGpt(),
    ),
  );
}

// Background message handler for Firebase Cloud Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background message received: ${message.messageId}");
}
