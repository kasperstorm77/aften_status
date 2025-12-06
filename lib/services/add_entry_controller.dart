import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models/evening_status.dart';
import '../models/app_settings.dart';
import '../models/field_definition.dart';
import 'storage_service.dart';
import 'settings_service.dart';
import 'field_definition_service.dart';

class AddEntryController extends ChangeNotifier {
  final StorageService _storageService = Modular.get<StorageService>();
  final SettingsService _settingsService = Modular.get<SettingsService>();
  final FieldDefinitionService _fieldService = Modular.get<FieldDefinitionService>();

  EveningStatus _currentStatus = EveningStatus();
  AppSettings _appSettings = AppSettings();
  List<FieldDefinition> _activeFields = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _editingEntryId;
  final Map<String, String> _fieldErrors = {};

  EveningStatus get currentStatus => _currentStatus;
  AppSettings get appSettings => _appSettings;
  List<FieldDefinition> get activeFields => _activeFields;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isEditing => _editingEntryId != null;
  Map<String, String> get fieldErrors => _fieldErrors;

  Future<void> init({String? entryId}) async {
    _isLoading = true;
    _editingEntryId = entryId;
    notifyListeners();

    try {
      await _storageService.init();
      await _settingsService.init();
      await _fieldService.initialize();

      _appSettings = _settingsService.loadSettings();
      _activeFields = await _fieldService.getActiveFields();
      
      if (entryId != null) {
        // Load existing entry for editing
        final entries = await _storageService.getAllEveningStatus();
        // Sort to match the display order (latest first)
        entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final index = int.tryParse(entryId);
        if (index != null && index < entries.length) {
          // Create a copy of the entry to avoid Hive key conflicts
          final original = entries[index];
          _currentStatus = EveningStatus.fromMap(original.toMap());
        }
      } else {
        // Create new entry
        _currentStatus = EveningStatus();
      }
    } catch (e) {
      final st = StackTrace.current;
      debugPrint('Error initializing AddEntryController: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateFieldValue(String fieldKey, dynamic value) {
    _fieldErrors.remove(fieldKey);
    _currentStatus.setFieldValue(fieldKey, value);
    notifyListeners();
  }

  dynamic getFieldValue(String fieldKey) {
    return _currentStatus.getFieldValue(fieldKey);
  }

  Future<void> saveCurrentStatus() async {
    _isSaving = true;
    notifyListeners();

    try {
      if (_editingEntryId != null) {
        // Update existing entry
        final index = int.tryParse(_editingEntryId!);
        if (index != null) {
          await _storageService.updateEveningStatus(index, _currentStatus);
        }
      } else {
        // Save new entry
        await _storageService.saveEveningStatus(_currentStatus);
      }
      
      // Navigate back with success
      Modular.to.pop(true);
    } catch (e) {
      debugPrint('Error saving status: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
