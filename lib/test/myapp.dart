import 'package:feedback/feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../activities/screens/ClubDetailScreen.dart';
import '../ads_provider.dart';
import '../fonctions/AppLocalizations.dart';
import '../test/widgets.dart';
import 'auth_service.dart';
import 'profile_provider.dart';
import 'screens/HomeParentPage.dart';
import 'screens/HomeProfPage.dart';
import 'screens/HomeUnknownPage.dart';
import 'screens/LoginPage.dart';
import 'screens/RoleSelectionPage.dart';

class MyApp3 extends StatefulWidget {
  const MyApp3({super.key});

  @override
  State<MyApp3> createState() => _MyApp3State();
}

class _MyApp3State extends State<MyApp3> {
  User? _user = FirebaseAuth.instance.currentUser;
  bool _isMounted = false;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charge l'utilisateur et les enfants si parent
      if (_isMounted) {
        _loadInitialData();
      }
    });

    if (_user != null) {
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).loadCurrentUser(_user!.uid);
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!.uid;
      final userProvider = Provider.of<ProfileProvider>(context, listen: false);
      await userProvider.loadCurrentUser(currentUser);
    } catch (e) {
      if (_isMounted) {
        // Gérer l'erreur si nécessaire
        debugPrint('Erreur lors du chargement initial: $e');
      }
    }
  }

  Future<void> _retryLoading() async {
    if (_isMounted) {
      await _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Consumer4<
      ThemeProvider,
      LocalizationModel,
      AuthService,
      ProfileProvider
    >(
      builder: (context, themeProvider, localizationModel, auth, profile, _) {
        if (profileProvider.error != null) {
          return _buildErrorScreen(
            profileProvider.error!,
            onRetry: _retryLoading,
          );
        }

        // if (profileProvider.user == null) {
        //   return Scaffold(body: Center(child: CustomShimmerEffect()));
        // }
        String fontAr = 'KHALED';
        return BetterFeedback(
          localeOverride: localizationModel.locale,
          child: MaterialApp(
            title: 'NextGen',
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

            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final user = snap.data;
                if (user == null) {
                  return LoginPage();
                }
                auth.user = user;
                return //Scaffold(body: Center(child: Text(profile.user!.name)));
                _determineStart(profile);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _determineStart(ProfileProvider profile) {
    final userModel = profile.user;
    if (profile.isLoading) {
      // Tant que ProfileProvider n’a pas fini, on affiche le loader
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userModel == null) {
      // Aucun utilisateur : on affiche la page de login
      return LoginPage();
    }

    if (profile.isNewUser) {
      return const RoleSelectionPage();
    }

    switch (userModel.role) {
      // Rôles parentaux et familiaux
      case 'parent':
      case 'grand-parent':
      case 'oncle/tante':
      case 'frère/sœur':
      case 'famille d’accueil':
        return HomeParentPage(user: profile.user!);

      // Rôles éducatifs et enseignants
      case 'professeur':
      case 'prof':
      case 'enseignant suppléant':
      case 'conseiller pédagogique':
      case 'éducateur':
      case 'formateur':
      case 'coach':
      case 'animateur':
      case 'moniteur':
      case 'intervenant extérieur':
      case 'médiateur':
      case 'tuteur':
        return HomeProfPage(
          user: profile.user!,
        ); // Ou un autre page spécifique si nécessaire

      // Structures organisationnelles
      case 'club':
      case 'association':
      case 'ecole':
        return ClubDetailScreen(club: profile.user!); //HomeClubPage();

      // Rôle par défaut
      case 'autre':
      default:
        return HomeUnknownPage();
    }
  }

  Widget _buildErrorScreen(String error, {VoidCallback? onRetry}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $error'),
            const SizedBox(height: 20),
            if (onRetry != null)
              Column(
                children: [
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : iconLogout(),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
