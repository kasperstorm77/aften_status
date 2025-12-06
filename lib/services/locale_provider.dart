import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Locale provider with persistence to Hive settings
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _initialized = false;
  
  Locale get locale => _locale;
  
  /// Initialize and load saved locale from Hive
  /// Should be called after Hive settings box is opened
  Future<void> initialize() async {
    if (_initialized) return;
    
    _initialized = true;
    try {
      // Ensure settings box is open
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }
      
      final settingsBox = Hive.box('settings');
      final savedLanguageCode = settingsBox.get('language') as String?;
      
      if (savedLanguageCode != null) {
        _locale = Locale(savedLanguageCode);
        debugPrint('LocaleProvider: Loaded saved locale: $savedLanguageCode');
      } else {
        debugPrint('LocaleProvider: No saved locale, using default: en');
      }
    } catch (e) {
      debugPrint('LocaleProvider: Error loading locale: $e');
      // If loading fails, use default locale
      _locale = const Locale('en');
    }
  }
  
  /// Change locale and persist to Hive
  Future<void> changeLocale(Locale locale) async {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
      
      // Save to Hive
      try {
        if (!Hive.isBoxOpen('settings')) {
          await Hive.openBox('settings');
        }
        final settingsBox = Hive.box('settings');
        await settingsBox.put('language', locale.languageCode);
        debugPrint('LocaleProvider: Saved locale: ${locale.languageCode}');
      } catch (e) {
        debugPrint('LocaleProvider: Error saving locale: $e');
        // Persist failed, but locale change still applied in memory
      }
    }
  }

  /// Quick access methods for common languages
  void setEnglish() => changeLocale(const Locale('en'));
  void setDanish() => changeLocale(const Locale('da'));
  
  /// Check current language
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isDanish => _locale.languageCode == 'da';
}
