import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/field_definition.dart';

class FieldDefinitionService {
  static const String _boxName = 'fieldDefinitions';
  late Box<FieldDefinition> _box;
  bool _isInitialized = false;
  
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
        debugPrint('FieldDefinitionService: Box already contains fields, skipping initialization');
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

  /// Initialize default field definitions based on existing schema
  Future<void> _initializeDefaultFields() async {
    debugPrint('FieldDefinitionService: Initializing default fields...');
    final defaultFields = [
      FieldDefinition(
        id: 'soundSensibility',
        labelKey: 'soundSensibility',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 0,
        isActive: true,
      ),
      FieldDefinition(
        id: 'sleepQuality',
        labelKey: 'sleepQuality',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 1,
        isActive: true,
      ),
      FieldDefinition(
        id: 'irritability',
        labelKey: 'irritability',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 2,
        isActive: true,
      ),
      FieldDefinition(
        id: 'socialWithdrawal',
        labelKey: 'socialWithdrawal',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 3,
        isActive: true,
      ),
      FieldDefinition(
        id: 'emotionalWithdrawal',
        labelKey: 'emotionalWithdrawal',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 4,
        isActive: true,
      ),
      FieldDefinition(
        id: 'skinPicking',
        labelKey: 'skinPicking',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 5,
        isActive: true,
      ),
      FieldDefinition(
        id: 'tiredness',
        labelKey: 'tiredness',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 6,
        isActive: true,
      ),
      FieldDefinition(
        id: 'forgetfulnessOnConversations',
        labelKey: 'forgetfulnessOnConversations',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 7,
        isActive: true,
      ),
      FieldDefinition(
        id: 'lackOfFocus',
        labelKey: 'lackOfFocus',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 8,
        isActive: true,
      ),
      FieldDefinition(
        id: 'lowToleranceTowardPeople',
        labelKey: 'lowToleranceTowardPeople',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 9,
        isActive: true,
      ),
      FieldDefinition(
        id: 'easyToTears',
        labelKey: 'easyToTears',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 10,
        isActive: true,
      ),
      FieldDefinition(
        id: 'interrupting',
        labelKey: 'interrupting',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 11,
        isActive: true,
      ),
      FieldDefinition(
        id: 'misunderstanding',
        labelKey: 'misunderstanding',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 12,
        isActive: true,
      ),
      FieldDefinition(
        id: 'selfBlaming',
        labelKey: 'selfBlaming',
        type: FieldType.rating,
        isSystemField: true,
        orderIndex: 13,
        isActive: true,
      ),
    ];

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
          type: FieldType.rating,
          isSystemField: true,
          orderIndex: 0,
          isActive: true,
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
          type: FieldType.rating,
          isSystemField: true,
          orderIndex: 0,
          isActive: true,
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
  Future<void> saveField(FieldDefinition field) async {
    await initialize();
    await _box.put(field.id, field);
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

  /// Update custom label for a field
  Future<void> updateCustomLabel(String fieldId, String locale, String label) async {
    final field = await getFieldById(fieldId);
    if (field != null) {
      field.setCustomLabel(locale, label);
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
  }
}