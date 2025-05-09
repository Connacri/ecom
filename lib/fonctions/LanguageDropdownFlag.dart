import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads_provider.dart';

class LanguageDropdownFlag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizationModel = Provider.of<LocalizationModel>(context);

    return PopupMenuButton<String>(
      icon: _getLanguageFlag(localizationModel.locale.languageCode),
      onSelected: (String languageCode) {
        localizationModel.changeLocale(languageCode);
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'fr',
              child: Row(
                children: [
                  _getLanguageFlag('fr'),
                  SizedBox(width: 10),
                  Text('Français'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                children: [
                  _getLanguageFlag('en'),
                  SizedBox(width: 10),
                  Text('English'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'ar',
              child: Row(
                children: [
                  _getLanguageFlag('ar'),
                  SizedBox(width: 10),
                  Text('العربية'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'es',
              child: Row(
                children: [
                  _getLanguageFlag('es'),
                  SizedBox(width: 10),
                  Text('Español'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'zh',
              child: Row(
                children: [
                  _getLanguageFlag('zh'),
                  SizedBox(width: 10),
                  Text('中文'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'ja',
              child: Row(
                children: [
                  _getLanguageFlag('ja'),
                  SizedBox(width: 10),
                  Text('日本語'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'th',
              child: Row(
                children: [
                  _getLanguageFlag('th'),
                  SizedBox(width: 10),
                  Text('ไทย'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'ru',
              child: Row(
                children: [
                  _getLanguageFlag('ru'),
                  SizedBox(width: 10),
                  Text('Русский'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'it',
              child: Row(
                children: [
                  _getLanguageFlag('it'),
                  SizedBox(width: 10),
                  Text('Italiano'),
                ],
              ),
            ),
          ],
    );
  }

  Widget _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return Image.asset('assets/flags/flag_fr.png', width: 24);
      case 'en':
        return Image.asset('assets/flags/flag_en.png', width: 24);
      case 'ar':
        return Image.asset('assets/flags/flag_ar.png', width: 24);
      case 'es':
        return Image.asset('assets/flags/flag_es.png', width: 24);
      case 'zh':
        return Image.asset('assets/flags/flag_cn.png', width: 24);
      case 'ja':
        return Image.asset('assets/flags/flag_jp.png', width: 24);
      case 'th':
        return Image.asset('assets/flags/flag_th.png', width: 24);
      case 'ru':
        return Image.asset('assets/flags/flag_ru.png', width: 24);
      case 'it':
        return Image.asset('assets/flags/flag_it.png', width: 24);
      default:
        return Image.asset('assets/flags/flag_fr.png', width: 24);
    }
  }
}
