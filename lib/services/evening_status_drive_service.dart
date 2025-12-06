import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/evening_status.dart';
import '../models/field_definition.dart';
import '../shared/services/google_drive/drive_config.dart';
import '../shared/services/google_drive/mobile_drive_service.dart';
import '../shared/services/google_drive/windows_drive_service_wrapper.dart';
import '../shared/utils/platform_helper.dart';

/// Google Drive service specifically for Evening Status app
/// Uses the shared drive infrastructure with EveningStatus-specific logic
class EveningStatusDriveService {
  static EveningStatusDriveService? _instance;
  static EveningStatusDriveService get instance {
    _instance ??= EveningStatusDriveService._();
    return _instance!;
  }

  // Platform-specific drive services
  MobileDriveService? _mobileDriveService;
  WindowsDriveServiceWrapper? _windowsDriveService;
  
  final StreamController<int> _uploadCountController = StreamController<int>.broadcast();

  EveningStatusDriveService._() {
    _initializePlatformService();
  }

  /// Drive configuration for this app
  static const _config = GoogleDriveConfig(
    fileName: 'aften_status_backup.json',
    mimeType: 'application/json',
    scope: 'https://www.googleapis.com/auth/drive.appdata',
    parentFolder: 'appDataFolder',
  );

  /// Initialize the appropriate platform-specific service
  void _initializePlatformService() {
    if (PlatformHelper.isWindows || PlatformHelper.isMacOS || PlatformHelper.isLinux) {
      if (kDebugMode) print('EveningStatusDriveService: Initializing for Desktop');
      // Will be created async in initialize()
    } else {
      if (kDebugMode) print('EveningStatusDriveService: Initializing for Mobile');
      _mobileDriveService = MobileDriveService(config: _config);
    }
  }

  // Expose underlying service properties
  bool get syncEnabled {
    if (PlatformHelper.isDesktop) {
      return _windowsDriveService?.syncEnabled ?? false;
    } else {
      return _mobileDriveService?.syncEnabled ?? false;
    }
  }
  
  bool get isAuthenticated {
    if (PlatformHelper.isDesktop) {
      return _windowsDriveService?.isAuthenticated ?? false;
    } else {
      return _mobileDriveService?.isAuthenticated ?? false;
    }
  }
  
  Stream<bool> get onSyncStateChanged {
    if (PlatformHelper.isDesktop) {
      return _windowsDriveService?.onSyncStateChanged ?? Stream.empty();
    } else {
      return _mobileDriveService?.onSyncStateChanged ?? Stream.empty();
    }
  }
  
  Stream<int> get onUpload => _uploadCountController.stream;
  
  Stream<String> get onError {
    if (PlatformHelper.isDesktop) {
      return _windowsDriveService?.onError ?? Stream.empty();
    } else {
      return _mobileDriveService?.onError ?? Stream.empty();
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (PlatformHelper.isDesktop) {
      _windowsDriveService = await WindowsDriveServiceWrapper.create(
        config: _config,
        syncEnabled: false,
        uploadDelay: const Duration(milliseconds: 700),
      );
      await _windowsDriveService!.initialize();
    } else {
      await _mobileDriveService!.initialize();
    }
    await _loadSyncState();
  }

  /// Sign in to Google
  Future<bool> signIn() {
    if (PlatformHelper.isDesktop) {
      return _windowsDriveService!.driveService.signIn();
    } else {
      return _mobileDriveService!.signIn();
    }
  }

  /// Sign out from Google  
  Future<void> signOut() async {
    if (PlatformHelper.isDesktop) {
      await _windowsDriveService!.driveService.signOut();
    } else {
      await _mobileDriveService!.signOut();
    }
    await _saveSyncState(false);
  }

  /// Enable/disable sync
  Future<void> setSyncEnabled(bool enabled) async {
    if (PlatformHelper.isDesktop) {
      await _windowsDriveService!.setSyncEnabled(enabled);
    } else {
      _mobileDriveService!.setSyncEnabled(enabled);
    }
    await _saveSyncState(enabled);
  }

  /// Set external client from access token (for mobile when auth happens externally)
  Future<void> setClientFromToken(String accessToken) async {
    if (!PlatformHelper.isDesktop) {
      await _mobileDriveService?.setExternalClientFromToken(accessToken);
    }
  }

  /// Clear the drive client (used on sign-out)
  void clearClient() {
    if (!PlatformHelper.isDesktop) {
      _mobileDriveService?.clearExternalClient();
    }
  }

  /// Upload evening status entries from Hive box
  Future<void> uploadFromBox(Box<EveningStatus> box, {bool notifyUI = false}) async {
    if (!syncEnabled || !isAuthenticated) {
      return;
    }

    try {
      // Get field definitions if available
      List<Map<String, dynamic>> fieldDefinitions = [];
      try {
        if (Hive.isBoxOpen('field_definitions')) {
          final fieldBox = Hive.box<FieldDefinition>('field_definitions');
          fieldDefinitions = fieldBox.values.map((def) => {
            'id': def.id,
            'labelKey': def.labelKey,
            'type': def.type.index,
            'isActive': def.isActive,
            'orderIndex': def.orderIndex,
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) print('Could not get field definitions: $e');
      }

      // Get entries
      final entries = box.values.map((e) => e.toMap()).toList();
      
      final now = DateTime.now().toUtc();
      final exportData = {
        'version': '1.0',
        'app': 'aften_status',
        'exportDate': now.toIso8601String(),
        'lastModified': now.toIso8601String(),
        'fieldDefinitions': fieldDefinitions,
        'entries': entries,
      };

      final jsonString = json.encode(exportData);

      if (PlatformHelper.isDesktop) {
        _windowsDriveService!.scheduleUpload(jsonString);
      } else {
        await _mobileDriveService!.uploadContent(jsonString);
      }
      
      await _saveLastModified(now);
      
      if (notifyUI) {
        _uploadCountController.add(entries.length);
      }
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Upload error: $e');
      rethrow;
    }
  }

  /// Download content from Drive
  Future<String?> downloadContent() async {
    if (PlatformHelper.isDesktop) {
      return await _windowsDriveService?.downloadContent();
    } else {
      return await _mobileDriveService?.downloadContent();
    }
  }

  /// Restore entries from downloaded content
  Future<int> restoreFromContent(String content, Box<EveningStatus> box) async {
    try {
      final data = json.decode(content) as Map<String, dynamic>;
      
      // Restore field definitions if present
      if (data.containsKey('fieldDefinitions')) {
        try {
          final fieldBox = await Hive.openBox<FieldDefinition>('field_definitions');
          await fieldBox.clear();
          
          final definitions = data['fieldDefinitions'] as List;
          for (final defData in definitions) {
            final def = FieldDefinition(
              id: defData['id'],
              labelKey: defData['labelKey'] ?? defData['name'] ?? '',
              type: FieldType.values[defData['type'] ?? 0],
              isActive: defData['isActive'] ?? true,
              orderIndex: defData['orderIndex'] ?? defData['sortOrder'] ?? 0,
            );
            await fieldBox.put(def.id, def);
          }
        } catch (e) {
          if (kDebugMode) print('Could not restore field definitions: $e');
        }
      }
      
      // Restore entries
      final entries = data['entries'] as List;
      await box.clear();
      
      int count = 0;
      for (final entryData in entries) {
        final entry = EveningStatus.fromMap(entryData);
        await box.add(entry);
        count++;
      }
      
      return count;
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Restore error: $e');
      rethrow;
    }
  }

  /// List available backups
  Future<List<Map<String, dynamic>>> listAvailableBackups() async {
    if (PlatformHelper.isDesktop) {
      return await _windowsDriveService?.listAvailableBackups() ?? [];
    } else {
      return await _mobileDriveService?.listAvailableBackups() ?? [];
    }
  }

  /// Download specific backup by filename
  Future<String?> downloadBackup(String fileName) async {
    if (PlatformHelper.isDesktop) {
      return await _windowsDriveService?.driveService.downloadBackupContent(fileName);
    } else {
      return await _mobileDriveService?.downloadBackupContent(fileName);
    }
  }

  // Private helpers
  Future<void> _loadSyncState() async {
    try {
      final settingsBox = Hive.box('settings');
      final enabled = settingsBox.get('syncEnabled', defaultValue: false) as bool;
      if (enabled) {
        await setSyncEnabled(true);
      }
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error loading sync state: $e');
    }
  }

  Future<void> _saveSyncState(bool enabled) async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('syncEnabled', enabled);
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error saving sync state: $e');
    }
  }

  Future<void> _saveLastModified(DateTime timestamp) async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('lastDriveSync', timestamp.toIso8601String());
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error saving last modified: $e');
    }
  }

  void dispose() {
    _uploadCountController.close();
  }
}
