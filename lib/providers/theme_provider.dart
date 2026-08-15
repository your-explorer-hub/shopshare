import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeChoice { system, soothing, vibrantDark }

class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_choice';

  AppThemeChoice _choice = AppThemeChoice.system;

  AppThemeChoice get choice => _choice;

  String get label {
    switch (_choice) {
      case AppThemeChoice.system:
        return 'System default';
      case AppThemeChoice.soothing:
        return 'Soothing';
      case AppThemeChoice.vibrantDark:
        return 'Vibrant Dark';
    }
  }

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _choice = AppThemeChoice.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => AppThemeChoice.system,
      );
      notifyListeners();
    }
  }

  Future<void> setChoice(AppThemeChoice choice) async {
    _choice = choice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, choice.name);
  }
}