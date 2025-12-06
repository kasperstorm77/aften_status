import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final settingsJson = jsonEncode(settings.toMap());
    await _prefs?.setString(_settingsKey, settingsJson);
  }

  AppSettings loadSettings() {
    final settingsJson = _prefs?.getString(_settingsKey);
    if (settingsJson == null) {
      return AppSettings();
    }
    
    try {
      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      return AppSettings.fromMap(settingsMap);
    } catch (e) {
      return AppSettings();
    }
  }
}