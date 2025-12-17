import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/field_definition.dart';
import 'evening_status_drive_service.dart';

class FieldDefinitionService {
  static const String _boxName = 'fieldDefinitions';
  static const _uuid = Uuid();
  late Box<FieldDefinition> _box;
  bool _isInitialized = false;
  
  // Reference to drive service for auto-sync
  EveningStatusDriveService get _driveService => EveningStatusDriveService.instance;
  
  static final FieldDefinitionService _instance = FieldDefinitionService._internal();
  factory FieldDefinitionService() => _instance;
  FieldDefinitionService._internal();

  /// Force reload the field definitions from the Hive box
  /// Call this after restoring from backup to refresh the cached data
  Future<void> reload() async {
    _isInitialized = false;
    await initialize();
  }

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
      
      // Initialize with default field definitions if none exist
      if (_box.isEmpty) {
        await _initializeDefaultFields();
      }
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('FieldDefinitionService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Initialize default field definitions with embedded localized names
  /// These are sample fields that users can modify or delete
  Future<void> _initializeDefaultFields() async {
    final defaultFields = _getDefaultFieldsList();
    for (final field in defaultFields) {
      await _box.put(field.id, field);
    }
  }

  /// Get all field definitions ordered by their order property
  Future<List<FieldDefinition>> getAllFields() async {
    try {
      await initialize();
      final fields = _box.values.toList();
      fields.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return fields;
    } catch (e) {
      if (kDebugMode) debugPrint('FieldDefinitionService: Error in getAllFields: $e');
      return [];
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

  /// Get field definition by labelKey (for looking up fields by their key name)
  Future<FieldDefinition?> getFieldByLabelKey(String labelKey) async {
    await initialize();
    try {
      return _box.values.firstWhere((f) => f.labelKey == labelKey);
    } catch (e) {
      return null; // Not found
    }
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

  /// Delete a field definition
  Future<bool> deleteField(String id) async {
    final field = await getFieldById(id);
    if (field != null) {
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
    
    final defaultFields = _getDefaultFieldsList();
    final existingLabelKeys = _box.values.map((f) => f.labelKey).toSet();
    int restoredCount = 0;
    
    for (final field in defaultFields) {
      // Check by labelKey since IDs are now random UUIDs
      if (!existingLabelKeys.contains(field.labelKey)) {
        await _box.put(field.id, field);
        restoredCount++;
      }
    }
    
    if (restoredCount > 0) {
      await _triggerAutoSync();
    }
    
    return restoredCount;
  }

  /// Get list of all default field definitions
  List<FieldDefinition> _getDefaultFieldsList() {
    return [
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'soundSensibility',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 0,
        isActive: true,
        localizedNames: {'en': 'Sound Sensibility', 'da': 'Lyd Følsomhed'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'sleepQuality',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 1,
        isActive: true,
        localizedNames: {'en': 'Sleep Quality', 'da': 'Søvn Kvalitet'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'irritability',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 2,
        isActive: true,
        localizedNames: {'en': 'Irritability', 'da': 'Irritabilitet'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'socialWithdrawal',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 3,
        isActive: true,
        localizedNames: {'en': 'Social Withdrawal', 'da': 'Social Tilbagetrækning'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'emotionalWithdrawal',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 4,
        isActive: true,
        localizedNames: {'en': 'Emotional Withdrawal', 'da': 'Følelsesmæssig Tilbagetrækning'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'skinPicking',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 5,
        isActive: true,
        localizedNames: {'en': 'Skin Picking', 'da': 'Hud Plukning'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'tiredness',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 6,
        isActive: true,
        localizedNames: {'en': 'Tiredness', 'da': 'Træthed'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'forgetfulnessOnConversations',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 7,
        isActive: true,
        localizedNames: {'en': 'Forgetfulness on Conversations', 'da': 'Glemsel i Samtaler'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'lackOfFocus',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 8,
        isActive: true,
        localizedNames: {'en': 'Lack of Focus', 'da': 'Mangel på Fokus'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'lowToleranceTowardPeople',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 9,
        isActive: true,
        localizedNames: {'en': 'Low Tolerance Toward People', 'da': 'Lav Tolerance Overfor Folk'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'easyToTears',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 10,
        isActive: true,
        localizedNames: {'en': 'Easy to Tears', 'da': 'Let til Tårer'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'interrupting',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 11,
        isActive: true,
        localizedNames: {'en': 'Interrupting', 'da': 'Afbrydelse'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'misunderstanding',
        type: FieldType.slider,
        isSystemField: false,
        orderIndex: 12,
        isActive: true,
        localizedNames: {'en': 'Misunderstanding', 'da': 'Misforståelse'},
      ),
      FieldDefinition(
        id: _uuid.v4(),
        labelKey: 'selfBlaming',
        type: FieldType.slider,
        isSystemField: false,
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
        // Use debounced sync to prevent rapid-fire uploads
        _driveService.scheduleDebouncedSync();
      }
    } catch (e) {
      // Don't rethrow - sync failure shouldn't break local operations
    }
  }
}