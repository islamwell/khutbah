import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._internal();
  static final AppSettings instance = AppSettings._internal();

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString('app_theme');
      final localeCode = prefs.getString('app_locale');
      if (themeStr != null) {
        _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }
      if (localeCode != null) {
        _locale = Locale(localeCode);
      }
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', locale.languageCode);
    } catch (_) {}
  }
}
