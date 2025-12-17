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
  
  // Data format version - increment this to trigger a fresh reset
  static const int _dataFormatVersion = 2;
  static const String _versionKey = 'dataFormatVersion';
  
  /// Initialize all services in the correct dependency order
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Step 1: Initialize Hive
      await Hive.initFlutter();

      // Step 2: Register Hive adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(EveningStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FieldDefinitionAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FieldTypeAdapter());
      }

      // Step 2.5: Check if we need to reset data for new format
      await _checkAndResetForNewDataFormat();

      // Step 3: Initialize FieldDefinitionService (needs Hive to be ready)
      final fieldDefinitionService = FieldDefinitionService();
      await fieldDefinitionService.initialize();

      // Step 4: Initialize StorageService (needs Hive and adapters to be ready)
      final storageService = StorageService();
      await storageService.init();

      // Step 5: Open settings box for sync state persistence
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      // Step 6: Initialize locale provider (load saved language preference)
      final localeProvider = LocaleProvider();
      await localeProvider.initialize();

      // Step 7: Start background sync check (non-blocking)
      _performStartupSyncCheck();

      _isInitialized = true;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('AppInitializationService: Initialization failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Perform a silent sync check on startup if user is signed in
  /// This runs in background and doesn't block app startup
  void _performStartupSyncCheck() {
    // Run sync check in background - don't await
    Future(() async {
      try {
        final driveService = EveningStatusDriveService.instance;
        await driveService.initialize();

        // Only check for updates if authenticated and sync is enabled
        if (driveService.isAuthenticated && driveService.syncEnabled) {
          // Check if remote has newer data
          final syncStatus = await driveService.getSyncStatus();
          final status = syncStatus['status'] as String;
          
          if (status == 'remote_newer' || status == 'remote_only') {
            // Download and restore silently
            final content = await driveService.downloadContent();
            if (content != null) {
              final box = Hive.box<EveningStatus>('evening_status');
              await driveService.restoreFromContent(content, box);
            }
          } else if (status == 'local_newer' || status == 'local_only') {
            // Upload local data silently
            final box = Hive.box<EveningStatus>('evening_status');
            await driveService.uploadFromBox(box);
          }
        }
      } catch (e) {
        // Silent failure - don't block app startup
        if (kDebugMode) debugPrint('AppInitializationService: Background sync failed: $e');
      }
    });
  }  /// Check if data format version changed and reset all data if needed
  /// This ensures clean slate when data structure changes
  Future<void> _checkAndResetForNewDataFormat() async {
    try {
      // Open settings box to check version
      final settingsBox = await Hive.openBox('settings');
      final storedVersion = settingsBox.get(_versionKey, defaultValue: 0) as int;
      
      if (storedVersion < _dataFormatVersion) {
        debugPrint('AppInitializationService: Data format version changed from $storedVersion to $_dataFormatVersion');
        debugPrint('AppInitializationService: Clearing all local data for fresh start...');
        
        // Clear field definitions box
        if (Hive.isBoxOpen('fieldDefinitions')) {
          await Hive.box('fieldDefinitions').clear();
        } else {
          final box = await Hive.openBox<FieldDefinition>('fieldDefinitions');
          await box.clear();
        }
        debugPrint('AppInitializationService: Field definitions cleared');
        
        // Clear evening status box
        if (Hive.isBoxOpen('evening_status')) {
          await Hive.box('evening_status').clear();
        } else {
          final box = await Hive.openBox<EveningStatus>('evening_status');
          await box.clear();
        }
        debugPrint('AppInitializationService: Evening status entries cleared');
        
        // Update version
        await settingsBox.put(_versionKey, _dataFormatVersion);
        debugPrint('AppInitializationService: Data format version updated to $_dataFormatVersion');
        
        // Clear any old Google Drive backups by resetting sync state
        await settingsBox.delete('lastSyncTimestamp');
        await settingsBox.delete('lastLocalUpdateTimestamp');
        debugPrint('AppInitializationService: Sync timestamps reset');
      } else {
        debugPrint('AppInitializationService: Data format version is current ($storedVersion)');
      }
    } catch (e) {
      debugPrint('AppInitializationService: Error checking data format version: $e');
      // Continue anyway - don't block initialization
    }
  }
}