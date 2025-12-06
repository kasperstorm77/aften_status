import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models/app_settings.dart';
import 'settings_service.dart';

class SettingsController extends ChangeNotifier {
  final SettingsService _settingsService = Modular.get<SettingsService>();

  AppSettings _appSettings = AppSettings();
  bool _isLoading = false;
  bool _isSaving = false;

  AppSettings get appSettings => _appSettings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingsService.init();
      _appSettings = _settingsService.loadSettings();
    } catch (e) {
      debugPrint('Error initializing SettingsController: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateFieldLabel(String fieldKey, String newLabel) {
    final fieldSettings = _appSettings.fieldSettings[fieldKey];
    if (fieldSettings != null) {
      final updatedSettings = fieldSettings.copyWith(
        label: newLabel,
        isCustomLabel: newLabel.trim().isNotEmpty,
      );
      _appSettings.fieldSettings[fieldKey] = updatedSettings;
      notifyListeners();
    }
  }

  void updateFieldUnit(String fieldKey, String newUnit) {
    final fieldSettings = _appSettings.fieldSettings[fieldKey];
    if (fieldSettings != null) {
      final updatedSettings = fieldSettings.copyWith(unit: newUnit);
      _appSettings.fieldSettings[fieldKey] = updatedSettings;
      notifyListeners();
    }
  }

  void toggleFieldEnabled(String fieldKey, bool isEnabled) {
    final fieldSettings = _appSettings.fieldSettings[fieldKey];
    if (fieldSettings != null) {
      final updatedSettings = fieldSettings.copyWith(isEnabled: isEnabled);
      _appSettings.fieldSettings[fieldKey] = updatedSettings;
      notifyListeners();
    }
  }

  Future<void> saveSettings() async {
    _isSaving = true;
    notifyListeners();

    try {
      await _settingsService.saveSettings(_appSettings);
      debugPrint('Settings saved successfully');
    } catch (e) {
      debugPrint('Error saving settings: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void resetToDefaults() {
    _appSettings = AppSettings();
    notifyListeners();
  }
}
