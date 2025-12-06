import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/evening_status.dart';
import '../models/field_definition.dart';
import '../services/storage_service.dart';
import '../services/field_definition_service.dart';
import '../services/evening_status_drive_service.dart';
import '../services/locale_provider.dart';

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
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FieldTypeAdapter());
        debugPrint('AppInitializationService: FieldType adapter registered');
      }

      // Step 3: Initialize FieldDefinitionService (needs Hive to be ready)
      final fieldDefinitionService = FieldDefinitionService();
      await fieldDefinitionService.initialize();
      debugPrint('AppInitializationService: FieldDefinitionService initialized');

      // Step 4: Initialize StorageService (needs Hive and adapters to be ready)
      final storageService = StorageService();
      await storageService.init();
      debugPrint('AppInitializationService: StorageService initialized');

      // Step 5: Open settings box for sync state persistence
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
        debugPrint('AppInitializationService: Settings box opened');
      }

      // Step 6: Initialize locale provider (load saved language preference)
      final localeProvider = LocaleProvider();
      await localeProvider.initialize();
      debugPrint('AppInitializationService: LocaleProvider initialized');

      // Step 7: Initialize drive service and perform silent sync check if signed in
      await _performStartupSyncCheck();

      _isInitialized = true;
      debugPrint('AppInitializationService: All services initialized successfully');

    } catch (e, stackTrace) {
      debugPrint('AppInitializationService: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Perform a silent sync check on startup if user is signed in
  Future<void> _performStartupSyncCheck() async {
    try {
      final driveService = EveningStatusDriveService.instance;
      await driveService.initialize();
      debugPrint('AppInitializationService: Drive service initialized');

      // Only check for updates if authenticated and sync is enabled
      if (driveService.isAuthenticated && driveService.syncEnabled) {
        debugPrint('AppInitializationService: Performing silent sync check...');
        
        // Check if remote has newer data
        final syncStatus = await driveService.getSyncStatus();
        final status = syncStatus['status'] as String;
        
        if (status == 'remote_newer' || status == 'remote_only') {
          debugPrint('AppInitializationService: Remote data is newer, downloading...');
          
          // Download and restore silently
          final content = await driveService.downloadContent();
          if (content != null) {
            final box = Hive.box<EveningStatus>('evening_status');
            final restoredCount = await driveService.restoreFromContent(content, box);
            debugPrint('AppInitializationService: Silent sync restored $restoredCount entries');
          }
        } else if (status == 'local_newer' || status == 'local_only') {
          debugPrint('AppInitializationService: Local data is newer, uploading...');
          
          // Upload local data silently
          final box = Hive.box<EveningStatus>('evening_status');
          await driveService.uploadFromBox(box);
          debugPrint('AppInitializationService: Silent sync uploaded local data');
        } else {
          debugPrint('AppInitializationService: Data is in sync, no action needed');
        }
      } else {
        debugPrint('AppInitializationService: Skipping sync check (not authenticated or sync disabled)');
      }
    } catch (e) {
      // Silent failure - don't block app startup
      debugPrint('AppInitializationService: Silent sync check failed: $e');
    }
  }
}