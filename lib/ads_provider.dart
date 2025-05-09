import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdsProvider extends ChangeNotifier {
  final int _limit = 10;
  final List<Map<String, dynamic>> _ads = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> get ads => List.unmodifiable(_ads);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> fetchAds({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;
    _isLoading = true;

    try {
      if (refresh) {
        _ads.clear();
        _lastDoc = null;
        _hasMore = true;
      }

      Query query = FirebaseFirestore.instance
          .collection('ads')
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        _ads.addAll(snapshot.docs.map((e) => e.data() as Map<String, dynamic>));
      }

      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Erreur chargement des annonces: $e");
    }

    _isLoading = false;
    notifyListeners(); // notifier uniquement à la fin
  }
}

class ThemeProvider with ChangeNotifier {
  // Par défaut, le thème est clair
  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  // Fonction pour changer le thème
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners(); // Notifie les auditeurs que l'état a changé
  }
}

class LocalizationModel with ChangeNotifier {
  Locale _locale = Locale('en'); // Valeur par défaut

  final List<String> supportedLanguages = [
    'en',
    'fr',
    'ar',
    'es',
    'zh',
    'ja',
    'th',
    'ru',
    'it',
  ];

  Locale get locale => _locale;

  // Initialise la locale avec celle du système ou celle sauvegardée
  Future<void> initLocale() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Vérifier si une langue est déjà sauvegardée
      String? savedLanguage = prefs.getString('language_code');

      if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
        // Utiliser la langue sauvegardée si elle est supportée
        _locale = Locale(savedLanguage);
      } else {
        // Utiliser la langue du système si elle est supportée
        final String deviceLocale =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;

        // Vérifier si la langue du système est supportée
        if (supportedLanguages.contains(deviceLocale)) {
          _locale = Locale(deviceLocale);
        } else {
          // Langue par défaut si celle du système n'est pas supportée
          _locale = Locale('fr');
        }

        // Sauvegarder la locale détectée ou par défaut
        await prefs.setString('language_code', _locale.languageCode);
      }

      notifyListeners();
    } catch (e) {
      print("Erreur lors de l'initialisation de la locale: $e");
      // En cas d'erreur, on garde la locale par défaut
      _locale = Locale('fr');
    }
  }

  // Changer la langue et la sauvegarder
  Future<void> changeLocale(String languageCode) async {
    try {
      if (!supportedLanguages.contains(languageCode)) {
        throw Exception('Langue non supportée: $languageCode');
      }

      _locale = Locale(languageCode);

      // Sauvegarder la langue dans SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);

      notifyListeners();
    } catch (e) {
      print("Erreur lors du changement de locale: $e");
      rethrow; // Permet à l'UI de gérer l'erreur si nécessaire
    }
  }
}
