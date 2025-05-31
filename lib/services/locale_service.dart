import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  Locale? _locale;
  static const String _localeKey = 'selected_locale';
  
  // Bahasa yang didukung
  static const Locale enLocale = Locale('en');
  static const Locale idLocale = Locale('id');
  static const Locale systemLocale = Locale('system');
  
  LocaleService() {
    _loadLocale();
  }
  
  // Getter untuk locale saat ini
  Locale? get locale => _locale;
  
  // Memuat preferensi bahasa dari SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localeString = prefs.getString(_localeKey);
    
    if (localeString == null || localeString == 'system') {
      _locale = null; // Gunakan bahasa sistem
    } else {
      _locale = Locale(localeString);
    }
    
    notifyListeners();
  }
  
  // Menyimpan preferensi bahasa ke SharedPreferences
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (locale.languageCode == 'system') {
      _locale = null;
      await prefs.setString(_localeKey, 'system');
    } else {
      _locale = locale;
      await prefs.setString(_localeKey, locale.languageCode);
    }
    
    notifyListeners();
  }
  
  // Mendapatkan nama bahasa berdasarkan kode bahasa
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'id':
        return 'Indonesia';
      case 'system':
        return 'System Language';
      default:
        return 'Unknown';
    }
  }
  
  // Mendapatkan nama bahasa saat ini
  String getCurrentLanguageName() {
    if (_locale == null) {
      return getLanguageName('system');
    }
    return getLanguageName(_locale!.languageCode);
  }
}