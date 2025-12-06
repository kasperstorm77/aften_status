import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/evening_status.dart';
import '../models/field_definition.dart';
import '../services/storage_service.dart';
import '../services/field_definition_service.dart';

/// Service responsible for initializing all app services in the correct order
class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  
  /// Initialize all services in the correct dependency order
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    debugPrint('AppInitializationService: Starting app initialization...');

    try {
      // Step 1: Initialize Hive
      await Hive.initFlutter();
      debugPrint('AppInitializationService: Hive initialized');

      // Step 2: Register Hive adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(EveningStatusAdapter());
        debugPrint('AppInitializationService: EveningStatus adapter registered');
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FieldDefinitionAdapter());
        debugPrint('AppInitializationService: FieldDefinition adapter registered');
      }

      // Step 3: Initialize FieldDefinitionService (needs Hive to be ready)
      final fieldDefinitionService = FieldDefinitionService();
      await fieldDefinitionService.initialize();
      debugPrint('AppInitializationService: FieldDefinitionService initialized');

      // Step 4: Initialize StorageService (needs Hive and adapters to be ready)
      final storageService = StorageService();
      await storageService.init();
      debugPrint('AppInitializationService: StorageService initialized');

      _isInitialized = true;
      debugPrint('AppInitializationService: All services initialized successfully');

    } catch (e, stackTrace) {
      debugPrint('AppInitializationService: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;
}