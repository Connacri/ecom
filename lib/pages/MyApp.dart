import 'package:feedback/feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../activities/screens/userHomePage.dart';
import '../ads_provider.dart';
import '../auth/google.dart';
import '../fonctions/AppLocalizations.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return PageLance();
  }
}

class PageLance extends StatefulWidget {
  const PageLance({super.key});

  @override
  State<PageLance> createState() => _PageLanceState();
}

class _PageLanceState extends State<PageLance> {
  @override
  void initState() {
    super.initState();
    // Initialise la locale au démarrage
    Future.delayed(Duration.zero, () {
      final localizationModel = Provider.of<LocalizationModel>(
        context,
        listen: false,
      );
      localizationModel.initLocale().then((_) {
        print(
          "Locale initialisée : ${localizationModel.locale}",
        ); // Ajout d'une impression de débogage
        setState(() {}); // Force la reconstruction de l'interface utilisateur
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocalizationModel>(
      builder: (context, themeProvider, localizationModel, child) {
        String fontAr = 'KHALED';
        print(
          "Locale actuelle : ${localizationModel.locale}",
        ); // Ajout d'une impression de débogage
        return BetterFeedback(
          localeOverride: localizationModel.locale,
          child: MaterialApp(
            title: 'WaShop',
            supportedLocales: [
              Locale('en'),
              Locale('fr'),
              Locale('ar'),
              Locale('es'),
              Locale('zh'),
              Locale('ja'),
              Locale('it'),
              Locale('ru'),
              Locale('th'),
            ],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale:
                localizationModel
                    .locale, // Assurez-vous que cette ligne est présente
            theme: ThemeData(
              fontFamily:
                  localizationModel.locale.languageCode == 'ar'
                      ? fontAr
                      : 'oswald',
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              chipTheme: ChipThemeData(
                backgroundColor: Colors.grey[300]!,
                labelStyle: TextStyle(
                  fontFamily:
                      localizationModel.locale.languageCode == 'ar'
                          ? fontAr
                          : 'oswald',
                ),
              ),
              textTheme: TextTheme(
                bodyMedium: TextStyle(color: Colors.black),
                bodyLarge: TextStyle(color: Colors.black),
                bodySmall: TextStyle(color: Colors.black),
                titleMedium: TextStyle(color: Colors.black),
                titleLarge: TextStyle(color: Colors.black),
                labelLarge: TextStyle(color: Colors.black),
              ),
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            darkTheme: ThemeData(
              fontFamily:
                  localizationModel.locale.languageCode == 'ar'
                      ? fontAr
                      : 'oswald',
              brightness: Brightness.dark,
              primaryColor: Colors.blueGrey,
              chipTheme: ChipThemeData(
                backgroundColor: Colors.grey[800]!,
                labelStyle: TextStyle(
                  fontFamily:
                      localizationModel.locale.languageCode == 'ar'
                          ? fontAr
                          : 'oswald',
                ),
              ),
              textTheme: TextTheme(
                bodyMedium: TextStyle(color: Colors.white),
                bodyLarge: TextStyle(color: Colors.white),
                bodySmall: TextStyle(color: Colors.white),
                titleMedium: TextStyle(color: Colors.white),
                titleLarge: TextStyle(color: Colors.white),
                labelLarge: TextStyle(color: Colors.white),
              ),
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            themeMode:
                themeProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,

            home: Scaffold(
              body: AuthScreen(),
              //HomePage(),
            ),
          ),
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // User is not authenticated, navigate to the Google page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => google()),
              );
            });
            return google();
          } else {
            // return Scaffold(
            //   appBar: AppBar(),
            //   body: Center(
            //     child: Column(
            //       children: [
            //         Text('${user.displayName} Deja Autentifié'),
            //         SizedBox(height: 100),
            //         ElevatedButton(
            //           onPressed: () async {
            //             await FirebaseAuth.instance.signOut();
            //           },
            //           child: Text('Déconnexion'),
            //         ),
            //         SizedBox(height: 100),
            //         ElevatedButton(
            //           onPressed:
            //               () => Navigator.of(context).push(
            //                 MaterialPageRoute(
            //                   builder: (ctx) => HomeScreenAct(),
            //                 ),
            //               ),
            //           child: Text('Go to'),
            //         ),
            //       ],
            //     ),
            //   ),
            // );
            // Utilisateur authentifié, naviguer vers PageLance
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => HomePage()),
              ); //HomeScreenAct()));
            });
            return Container(); // Retourner un widget vide pendant la navigation
          }
        } else {
          // Afficher un indicateur de chargement pendant la vérification de l'état d'authentification
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}
