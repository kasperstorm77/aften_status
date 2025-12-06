import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/field_definition.dart';
import 'evening_status_drive_service.dart';

class FieldDefinitionService {
  static const String _boxName = 'fieldDefinitions';
  late Box<FieldDefinition> _box;
  bool _isInitialized = false;
  
  // Reference to drive service for auto-sync
  EveningStatusDriveService get _driveService => EveningStatusDriveService.instance;
  
  static final FieldDefinitionService _instance = FieldDefinitionService._internal();
  factory FieldDefinitionService() => _instance;
  FieldDefinitionService._internal();

  Future<void> initialize() async {
    // If already initialized and the box is open, nothing to do
    if (_isInitialized && Hive.isBoxOpen(_boxName)) {
      return;
    }

    try {
      // If the box is already open (but instance not set), grab it
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<FieldDefinition>(_boxName);
      } else {
        _box = await Hive.openBox<FieldDefinition>(_boxName);
      }
      debugPrint('FieldDefinitionService: Opened box with ${_box.length} existing fields');
      
      // Initialize with default field definitions if none exist
      if (_box.isEmpty) {
        debugPrint('FieldDefinitionService: Box is empty, initializing default fields');
        await _initializeDefaultFields();
      } else {
        debugPrint('FieldDefinitionService: Box already contains ${_box.length} fields');
        // List existing fields for debugging
        for (final key in _box.keys) {
          final field = _box.get(key);
          debugPrint('FieldDefinitionService: Existing field: $key -> ${field?.labelKey}');
        }
      }
      
      _isInitialized = true;
      debugPrint('FieldDefinitionService: Initialized successfully');
    } catch (e) {
      debugPrint('FieldDefinitionService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Initialize default field definitions with embedded localized names
  /// These are sample fields that users can modify or delete
  Future<void> _initializeDefaultFields() async {
    debugPrint('FieldDefinitionService: Initializing default fields...');
    final defaultFields = _getDefaultFieldsList();

    for (final field in defaultFields) {
      await _box.put(field.id, field);
      debugPrint('FieldDefinitionService: Initialized field: ${field.id}');
    }
    debugPrint('FieldDefinitionService: Initialized ${defaultFields.length} default fields');
  }

  /// Get all field definitions ordered by their order property
  Future<List<FieldDefinition>> getAllFields() async {
    try {
      await initialize();
      final fields = _box.values.toList();
      debugPrint('FieldDefinitionService: getAllFields() found ${fields.length} fields');
      for (final field in fields) {
        debugPrint('FieldDefinitionService: Field: ${field.id}, active: ${field.isActive}, system: ${field.isSystemField}');
      }
      
      // If no soundSensibility field found, add it manually as a fallback
      if (!fields.any((field) => field.id == 'soundSensibility')) {
        debugPrint('FieldDefinitionService: soundSensibility not found, adding manually');
        final soundSensibilityField = FieldDefinition(
          id: 'soundSensibility',
          labelKey: 'soundSensibility',
          type: FieldType.slider,
          isSystemField: true,
          orderIndex: 0,
          isActive: true,
          localizedNames: {'en': 'Sound Sensibility', 'da': 'Lyd Følsomhed'},
        );
        fields.insert(0, soundSensibilityField);
        // Try to save it to the box for next time
        try {
          await _box.put(soundSensibilityField.id, soundSensibilityField);
        } catch (e) {
          debugPrint('FieldDefinitionService: Could not save soundSensibility field: $e');
        }
      }
      
      fields.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return fields;
    } catch (e) {
      debugPrint('FieldDefinitionService: Error in getAllFields, returning default soundSensibility: $e');
      // Return at least the soundSensibility field if everything fails
      return [
        FieldDefinition(
          id: 'soundSensibility',
          labelKey: 'soundSensibility',
          type: FieldType.slider,
          isSystemField: true,
          orderIndex: 0,
          isActive: true,
          localizedNames: {'en': 'Sound Sensibility', 'da': 'Lyd Følsomhed'},
        )
      ];
    }
  }

  /// Get only active field definitions
  Future<List<FieldDefinition>> getActiveFields() async {
    final allFields = await getAllFields();
    return allFields.where((field) => field.isActive).toList();
  }

  /// Get field definition by ID
  Future<FieldDefinition?> getFieldById(String id) async {
    await initialize();
    return _box.get(id);
  }

  /// Add or update a field definition
  Future<void> saveField(FieldDefinition field, {bool triggerSync = true}) async {
    await initialize();
    await _box.put(field.id, field);
    if (triggerSync) {
      await _triggerAutoSync();
    }
  }

  /// Update an existing field definition
  Future<void> updateField(String id, FieldDefinition updatedField) async {
    await initialize();
    final existingField = await getFieldById(id);
    if (existingField != null) {
      updatedField.updatedAt = DateTime.now();
      await _box.put(id, updatedField);
    } else {
      throw Exception('Field with ID "$id" not found');
    }
  }

  /// Delete a field definition (only if not system field)
  Future<bool> deleteField(String id) async {
    final field = await getFieldById(id);
    if (field != null && !field.isSystemField) {
      await _box.delete(id);
      await _triggerAutoSync();
      return true;
    }
    return false;
  }

  /// Deactivate a field (mark as inactive)
  Future<void> deactivateField(String id) async {
    final field = await getFieldById(id);
    if (field != null) {
      field.isActive = false;
      field.updatedAt = DateTime.now();
      await saveField(field);
    }
  }

  /// Activate a field
  Future<void> activateField(String id) async {
    final field = await getFieldById(id);
    if (field != null) {
      field.isActive = true;
      field.updatedAt = DateTime.now();
      await saveField(field);
    }
  }

  /// Update field order
  Future<void> updateFieldOrder(String id, int newOrder) async {
    final field = await getFieldById(id);
    if (field != null) {
      field.orderIndex = newOrder;
      field.updatedAt = DateTime.now();
      await saveField(field);
    }
  }

  /// Update localized name for a field
  Future<void> updateLocalizedName(String fieldId, String locale, String name) async {
    final field = await getFieldById(fieldId);
    if (field != null) {
      field.setLocalizedName(locale, name);
      field.updatedAt = DateTime.now();
      await saveField(field);
    }
  }

  /// Create a new custom field
  Future<FieldDefinition> createCustomField({
    required String id,
    required String labelKey,
    required FieldType type,
    Map<String, dynamic>? options,
  }) async {
    // Ensure ID is unique
    final existingField = await getFieldById(id);
    if (existingField != null) {
      throw Exception('Field with ID "$id" already exists');
    }

    final allFields = await getAllFields();
    final maxOrder = allFields.isEmpty 
        ? 0 
        : allFields.map((f) => f.orderIndex).reduce((a, b) => a > b ? a : b);

    final field = FieldDefinition(
      id: id,
      labelKey: labelKey,
      type: type,
      isSystemField: false,
      options: options ?? {},
      orderIndex: maxOrder + 1,
      isActive: true,
    );

    await saveField(field);
    return field;
  }

  /// Get fields that need to be synced (for iCloud sync)
  Future<Map<String, dynamic>> getFieldsForSync() async {
    final fields = await getAllFields();
    return {
      'fields': fields.map((f) => f.toMap()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Update fields from sync data
  Future<void> updateFieldsFromSync(Map<String, dynamic> syncData) async {
    if (syncData['fields'] != null) {
      final fieldMaps = List<Map<String, dynamic>>.from(syncData['fields']);
      
      for (final fieldMap in fieldMaps) {
        final field = FieldDefinition.fromMap(fieldMap);
        await saveField(field);
      }
    }
  }

  /// Clear all field definitions (for testing/reset)
  Future<void> clearAllFields() async {
    await initialize();
    await _box.clear();
    await _initializeDefaultFields();
    await _triggerAutoSync();
  }

  /// Restore missing default fields (only adds fields that don't exist)
  /// Returns the number of fields restored
  Future<int> restoreDefaultFields() async {
    await initialize();
    debugPrint('FieldDefinitionService: Restoring missing default fields...');
    
    final defaultFields = _getDefaultFieldsList();
    int restoredCount = 0;
    
    for (final field in defaultFields) {
      if (!_box.containsKey(field.id)) {
        await _box.put(field.id, field);
        restoredCount++;
        debugPrint('FieldDefinitionService: Restored missing field: ${field.id}');
      }
    }
    
    if (restoredCount > 0) {
      await _triggerAutoSync();
    }
    
    debugPrint('FieldDefinitionService: Restored $restoredCount default fields');
    return restoredCount;
  }

  /// Get list of all default field definitions
  List<FieldDefinition> _getDefaultFieldsList() {
    return [
      FieldDefinition(
        id: 'soundSensibility',
        labelKey: 'soundSensibility',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 0,
        isActive: true,
        localizedNames: {'en': 'Sound Sensibility', 'da': 'Lyd Følsomhed'},
      ),
      FieldDefinition(
        id: 'sleepQuality',
        labelKey: 'sleepQuality',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 1,
        isActive: true,
        localizedNames: {'en': 'Sleep Quality', 'da': 'Søvn Kvalitet'},
      ),
      FieldDefinition(
        id: 'irritability',
        labelKey: 'irritability',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 2,
        isActive: true,
        localizedNames: {'en': 'Irritability', 'da': 'Irritabilitet'},
      ),
      FieldDefinition(
        id: 'socialWithdrawal',
        labelKey: 'socialWithdrawal',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 3,
        isActive: true,
        localizedNames: {'en': 'Social Withdrawal', 'da': 'Social Tilbagetrækning'},
      ),
      FieldDefinition(
        id: 'emotionalWithdrawal',
        labelKey: 'emotionalWithdrawal',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 4,
        isActive: true,
        localizedNames: {'en': 'Emotional Withdrawal', 'da': 'Følelsesmæssig Tilbagetrækning'},
      ),
      FieldDefinition(
        id: 'skinPicking',
        labelKey: 'skinPicking',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 5,
        isActive: true,
        localizedNames: {'en': 'Skin Picking', 'da': 'Hud Plukning'},
      ),
      FieldDefinition(
        id: 'tiredness',
        labelKey: 'tiredness',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 6,
        isActive: true,
        localizedNames: {'en': 'Tiredness', 'da': 'Træthed'},
      ),
      FieldDefinition(
        id: 'forgetfulnessOnConversations',
        labelKey: 'forgetfulnessOnConversations',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 7,
        isActive: true,
        localizedNames: {'en': 'Forgetfulness on Conversations', 'da': 'Glemsel i Samtaler'},
      ),
      FieldDefinition(
        id: 'lackOfFocus',
        labelKey: 'lackOfFocus',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 8,
        isActive: true,
        localizedNames: {'en': 'Lack of Focus', 'da': 'Mangel på Fokus'},
      ),
      FieldDefinition(
        id: 'lowToleranceTowardPeople',
        labelKey: 'lowToleranceTowardPeople',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 9,
        isActive: true,
        localizedNames: {'en': 'Low Tolerance Toward People', 'da': 'Lav Tolerance Overfor Folk'},
      ),
      FieldDefinition(
        id: 'easyToTears',
        labelKey: 'easyToTears',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 10,
        isActive: true,
        localizedNames: {'en': 'Easy to Tears', 'da': 'Let til Tårer'},
      ),
      FieldDefinition(
        id: 'interrupting',
        labelKey: 'interrupting',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 11,
        isActive: true,
        localizedNames: {'en': 'Interrupting', 'da': 'Afbrydelse'},
      ),
      FieldDefinition(
        id: 'misunderstanding',
        labelKey: 'misunderstanding',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 12,
        isActive: true,
        localizedNames: {'en': 'Misunderstanding', 'da': 'Misforståelse'},
      ),
      FieldDefinition(
        id: 'selfBlaming',
        labelKey: 'selfBlaming',
        type: FieldType.slider,
        isSystemField: true,
        orderIndex: 13,
        isActive: true,
        localizedNames: {'en': 'Self-blaming', 'da': 'Selvbebrejdelse'},
      ),
    ];
  }

  /// Trigger automatic sync to Google Drive if enabled (debounced)
  Future<void> _triggerAutoSync() async {
    try {
      if (_driveService.syncEnabled && _driveService.isAuthenticated) {
        debugPrint('FieldDefinitionService: Scheduling debounced sync to Google Drive...');
        // Use debounced sync to prevent rapid-fire uploads
        _driveService.scheduleDebouncedSync();
      }
    } catch (e) {
      debugPrint('FieldDefinitionService: Auto-sync scheduling failed: $e');
      // Don't rethrow - sync failure shouldn't break local operations
    }
  }
}