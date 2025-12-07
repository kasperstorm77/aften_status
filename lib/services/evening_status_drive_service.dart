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

  // Debouncing for auto-sync
  Timer? _syncDebounceTimer;
  static const _syncDebounceDelay = Duration(seconds: 5); // Wait 5 seconds after last change
  bool _syncPending = false;

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
  /// After successful sign-in, sync is automatically enabled
  Future<bool> signIn() async {
    bool success;
    if (PlatformHelper.isDesktop) {
      success = await _windowsDriveService!.driveService.signIn();
    } else {
      success = await _mobileDriveService!.signIn();
    }
    
    // Auto-enable sync after successful sign-in
    if (success) {
      await setSyncEnabled(true);
      if (kDebugMode) print('EveningStatusDriveService: Auto-enabled sync after sign-in');
    }
    
    return success;
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

  /// Delete all backup files from Google Drive and sign out
  /// This completely disconnects the app from Google Drive
  Future<void> disconnectAndDeleteAllBackups() async {
    // First get all backups
    final backups = await listAvailableBackups();
    
    // Delete each backup file
    for (final backup in backups) {
      final fileId = backup['fileId'] as String?;
      if (fileId != null) {
        await deleteBackupFile(fileId);
      }
    }
    
    // Sign out
    await signOut();
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

  /// Schedule a debounced sync - waits for activity to settle before syncing
  /// This prevents rapid-fire syncs when multiple changes happen in quick succession
  void scheduleDebouncedSync() {
    if (!syncEnabled || !isAuthenticated) {
      return;
    }
    
    _syncPending = true;
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounceDelay, () async {
      if (_syncPending) {
        _syncPending = false;
        if (kDebugMode) print('EveningStatusDriveService: Debounced sync triggered');
        try {
          if (Hive.isBoxOpen('evening_status')) {
            final box = Hive.box<EveningStatus>('evening_status');
            await uploadFromBox(box);
          }
        } catch (e) {
          if (kDebugMode) print('EveningStatusDriveService: Debounced sync failed: $e');
        }
      }
    });
  }

  /// Cancel any pending debounced sync
  void cancelPendingSync() {
    _syncDebounceTimer?.cancel();
    _syncPending = false;
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
        if (Hive.isBoxOpen('fieldDefinitions')) {
          final fieldBox = Hive.box<FieldDefinition>('fieldDefinitions');
          fieldDefinitions = fieldBox.values.map((def) => {
            'id': def.id,
            'labelKey': def.labelKey,
            'type': def.type.index,
            'isActive': def.isActive,
            'isRequired': def.isRequired,
            'orderIndex': def.orderIndex,
            'isSystemField': def.isSystemField,
            'localizedNames': def.localizedNames,
            'options': def.options,
            'createdAt': def.createdAt.toIso8601String(),
            'updatedAt': def.updatedAt?.toIso8601String(),
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
          final fieldBox = await Hive.openBox<FieldDefinition>('fieldDefinitions');
          await fieldBox.clear();
          
          final definitions = data['fieldDefinitions'] as List;
          for (final defData in definitions) {
            // Parse localizedNames (could be Map<String, dynamic> from JSON)
            Map<String, String> localizedNames = {};
            if (defData['localizedNames'] != null) {
              final rawNames = defData['localizedNames'] as Map<String, dynamic>;
              localizedNames = rawNames.map((k, v) => MapEntry(k, v.toString()));
            }
            
            // Parse options
            Map<String, dynamic> options = {};
            if (defData['options'] != null) {
              options = Map<String, dynamic>.from(defData['options']);
            }
            
            final def = FieldDefinition(
              id: defData['id'],
              labelKey: defData['labelKey'] ?? defData['name'] ?? '',
              type: FieldType.values[defData['type'] ?? 0],
              isActive: defData['isActive'] ?? true,
              isRequired: defData['isRequired'] ?? false,
              orderIndex: defData['orderIndex'] ?? defData['sortOrder'] ?? 0,
              isSystemField: defData['isSystemField'] ?? false,
              localizedNames: localizedNames,
              options: options,
              createdAt: defData['createdAt'] != null 
                  ? DateTime.parse(defData['createdAt']) 
                  : DateTime.now(),
              updatedAt: defData['updatedAt'] != null 
                  ? DateTime.parse(defData['updatedAt']) 
                  : null,
            );
            await fieldBox.put(def.id, def);
          }
          if (kDebugMode) print('EveningStatusDriveService: Restored ${definitions.length} field definitions');
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

  /// Delete a specific backup file by ID (for debug/cleanup purposes)
  Future<void> deleteBackupFile(String fileId) async {
    if (PlatformHelper.isDesktop) {
      await _windowsDriveService?.driveService.deleteFileById(fileId);
    } else {
      await _mobileDriveService?.deleteFile(fileId);
    }
  }

  /// Get the last modified timestamp from local storage
  Future<DateTime?> getLocalLastModified() async {
    try {
      final settingsBox = await _getSettingsBox();
      final lastSync = settingsBox.get('lastLocalModified') as String?;
      if (lastSync != null) {
        return DateTime.parse(lastSync);
      }
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error getting local last modified: $e');
    }
    return null;
  }

  /// Get the last modified timestamp from remote (most recent backup)
  Future<DateTime?> getRemoteLastModified() async {
    try {
      final backups = await listAvailableBackups();
      if (backups.isNotEmpty) {
        // Backups are sorted newest first
        return backups.first['date'] as DateTime?;
      }
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error getting remote last modified: $e');
    }
    return null;
  }

  /// Check if local data is newer than remote
  Future<bool> isLocalNewer() async {
    final local = await getLocalLastModified();
    final remote = await getRemoteLastModified();
    
    if (local == null) return false; // No local data, not newer
    if (remote == null) return true;  // No remote data, local is newer
    
    return local.isAfter(remote);
  }

  /// Check if remote data is newer than local
  Future<bool> isRemoteNewer() async {
    final local = await getLocalLastModified();
    final remote = await getRemoteLastModified();
    
    if (remote == null) return false; // No remote data, not newer
    if (local == null) return true;   // No local data, remote is newer
    
    return remote.isAfter(local);
  }

  /// Get sync status information
  Future<Map<String, dynamic>> getSyncStatus() async {
    final local = await getLocalLastModified();
    final remote = await getRemoteLastModified();
    
    String status;
    if (local == null && remote == null) {
      status = 'no_data';
    } else if (local == null) {
      status = 'remote_only';
    } else if (remote == null) {
      status = 'local_only';
    } else if (local.isAfter(remote)) {
      status = 'local_newer';
    } else if (remote.isAfter(local)) {
      status = 'remote_newer';
    } else {
      status = 'in_sync';
    }
    
    return {
      'status': status,
      'localLastModified': local?.toIso8601String(),
      'remoteLastModified': remote?.toIso8601String(),
      'isLocalNewer': local != null && (remote == null || local.isAfter(remote)),
      'isRemoteNewer': remote != null && (local == null || remote.isAfter(local)),
    };
  }

  /// Smart sync - only upload if local is newer or equal
  /// Returns true if upload happened, false if skipped
  Future<bool> smartUploadFromBox(Box<EveningStatus> box, {bool notifyUI = false, bool forceUpload = false}) async {
    if (!syncEnabled || !isAuthenticated) {
      if (kDebugMode) print('EveningStatusDriveService: Smart sync skipped - not enabled or not authenticated');
      return false;
    }

    if (!forceUpload) {
      final isRemoteNewer = await this.isRemoteNewer();
      if (isRemoteNewer) {
        if (kDebugMode) print('EveningStatusDriveService: Smart sync skipped - remote is newer. Use forceUpload to override.');
        return false;
      }
    }

    await uploadFromBox(box, notifyUI: notifyUI);
    return true;
  }

  /// Smart download - only download if remote is newer
  /// Returns the content if downloaded, null if skipped
  Future<String?> smartDownloadContent({bool forceDownload = false}) async {
    if (!syncEnabled || !isAuthenticated) {
      if (kDebugMode) print('EveningStatusDriveService: Smart download skipped - not enabled or not authenticated');
      return null;
    }

    if (!forceDownload) {
      final isLocalNewer = await this.isLocalNewer();
      if (isLocalNewer) {
        if (kDebugMode) print('EveningStatusDriveService: Smart download skipped - local is newer. Use forceDownload to override.');
        return null;
      }
    }

    return await downloadContent();
  }

  // Private helpers
  Future<Box> _getSettingsBox() async {
    if (!Hive.isBoxOpen('settings')) {
      return await Hive.openBox('settings');
    }
    return Hive.box('settings');
  }

  Future<void> _loadSyncState() async {
    try {
      final settingsBox = await _getSettingsBox();
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
      final settingsBox = await _getSettingsBox();
      await settingsBox.put('syncEnabled', enabled);
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error saving sync state: $e');
    }
  }

  Future<void> _saveLastModified(DateTime timestamp) async {
    try {
      final settingsBox = await _getSettingsBox();
      await settingsBox.put('lastDriveSync', timestamp.toIso8601String());
      // Also update local last modified to track when local data changed
      await settingsBox.put('lastLocalModified', timestamp.toIso8601String());
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error saving last modified: $e');
    }
  }

  /// Update local last modified timestamp (called when local data changes)
  Future<void> updateLocalLastModified() async {
    try {
      final settingsBox = await _getSettingsBox();
      await settingsBox.put('lastLocalModified', DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      if (kDebugMode) print('EveningStatusDriveService: Error updating local last modified: $e');
    }
  }

  void dispose() {
    _uploadCountController.close();
  }
}
