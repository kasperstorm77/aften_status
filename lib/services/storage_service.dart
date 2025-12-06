import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/evening_status.dart';
import '../models/field_definition.dart';
import 'evening_status_drive_service.dart';

class StorageService {
  static const String _eveningStatusBoxName = 'evening_status';
  Box<EveningStatus>? _eveningStatusBox;
  
  // Reference to drive service for auto-sync
  EveningStatusDriveService get _driveService => EveningStatusDriveService.instance;

  // Ensure the service is initialized and box is opened before doing operations
  Future<void> _ensureInitialized() async {
    if (_eveningStatusBox == null || !(_eveningStatusBox?.isOpen ?? false)) {
      debugPrint('StorageService: evening status box not open, initializing storage service...');
      await init();
    }
  }

  Future<void> init() async {
    debugPrint('StorageService: === INITIALIZATION STARTING ===');
    
    try {
      // Initialize Hive with detailed logging
      debugPrint('StorageService: Initializing Hive...');
      await Hive.initFlutter();
      debugPrint('StorageService: Hive initialized successfully');
      
      // Register adapters with error handling
      debugPrint('StorageService: Registering Hive adapters...');
      try {
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(EveningStatusAdapter());
          debugPrint('StorageService: EveningStatus adapter registered (typeId: 0)');
        }
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(FieldDefinitionAdapter());
          debugPrint('StorageService: FieldDefinition adapter registered (typeId: 1)');
        }
        if (!Hive.isAdapterRegistered(2)) {
          Hive.registerAdapter(FieldTypeAdapter());
          debugPrint('StorageService: FieldType adapter registered (typeId: 2)');
        }
        debugPrint('StorageService: All adapters registered successfully');
      } catch (e, st) {
        debugPrint('StorageService: CRITICAL - Adapter registration failed: $e\n$st');
        throw Exception('Failed to register Hive adapters: $e');
      }
      
      // Open box with recovery for schema errors
      debugPrint('StorageService: Opening evening status box...');
      try {
        _eveningStatusBox = await Hive.openBox<EveningStatus>(_eveningStatusBoxName);
        debugPrint('StorageService: Evening status box opened successfully');
      } catch (e, st) {
        debugPrint('StorageService: Error opening evening status box: $e\n$st');
        final message = e.toString();
        if (message.contains('unknown typeId') || 
            message.contains('Unknown typeId') ||
            message.contains('not a subtype of type') ||
            message.contains('type cast') ||
            message.contains('FormatException')) {
          debugPrint('StorageService: Detected corrupted box data. Deleting and recreating...');
          try {
            await Hive.deleteBoxFromDisk(_eveningStatusBoxName);
            debugPrint('StorageService: Deleted corrupted box from disk, retrying open...');
            _eveningStatusBox = await Hive.openBox<EveningStatus>(_eveningStatusBoxName);
            debugPrint('StorageService: Evening status box recreated successfully');
          } catch (e2, st2) {
            debugPrint('StorageService: Failed to recover evening status box: $e2\n$st2');
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      
      debugPrint('StorageService: === INITIALIZATION COMPLETE ===');
    } catch (e, st) {
      debugPrint('StorageService: FATAL - Initialization failed: $e\n$st');
      rethrow;
    }
  }

  // Save a new evening status entry
  Future<void> saveEveningStatus(EveningStatus status) async {
    await _ensureInitialized();
    debugPrint('StorageService: Saving new entry with timestamp ${status.timestamp}');
    await _eveningStatusBox!.add(status);
    debugPrint('StorageService: Entry saved successfully');
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Update an existing evening status entry
  Future<void> updateEveningStatus(int index, EveningStatus status) async {
    await _ensureInitialized();
    debugPrint('StorageService: Updating entry at index $index');
    await _eveningStatusBox!.putAt(index, status);
    debugPrint('StorageService: Entry updated successfully');
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Delete an evening status entry
  Future<void> deleteEveningStatus(int index) async {
    await _ensureInitialized();
    debugPrint('StorageService: Deleting entry at index $index');
    await _eveningStatusBox!.deleteAt(index);
    debugPrint('StorageService: Entry deleted successfully');
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Get all evening status entries
  Future<List<EveningStatus>> getAllEveningStatus() async {
    await _ensureInitialized();
    final entries = _eveningStatusBox!.values.toList();
    debugPrint('StorageService: Retrieved ${entries.length} entries');
    return entries;
  }

  // Get entries within a date range
  Future<List<EveningStatus>> getEntriesInRange(DateTime start, DateTime end) async {
    await _ensureInitialized();
    final allEntries = _eveningStatusBox!.values.toList();
    final filteredEntries = allEntries.where((entry) {
      return entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end);
    }).toList();
    debugPrint('StorageService: Retrieved ${filteredEntries.length} entries in range');
    return filteredEntries;
  }

  // Replace all entries (used for restore operations)
  Future<void> replaceAllEveningStatus(List<EveningStatus> entries) async {
    await _ensureInitialized();
    debugPrint('StorageService: Replacing all entries with ${entries.length} new entries');
    await _eveningStatusBox!.clear();
    await _eveningStatusBox!.addAll(entries);
    debugPrint('StorageService: All entries replaced successfully');
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Emergency reset - delete all data
  Future<void> emergencyReset() async {
    await _ensureInitialized();
    debugPrint('StorageService: EMERGENCY RESET - Deleting all data');
    await _eveningStatusBox!.clear();
    debugPrint('StorageService: All data deleted');
  }

  // Trigger automatic sync to Google Drive if enabled (debounced)
  Future<void> _triggerAutoSync() async {
    try {
      // Always update local timestamp when data changes
      await _driveService.updateLocalLastModified();
      
      if (_driveService.syncEnabled && _driveService.isAuthenticated) {
        debugPrint('StorageService: Scheduling debounced sync to Google Drive...');
        // Use debounced sync to prevent rapid-fire uploads
        _driveService.scheduleDebouncedSync();
      }
    } catch (e) {
      debugPrint('StorageService: Auto-sync scheduling failed: $e');
      // Don't rethrow - sync failure shouldn't break local operations
    }
  }

  // Close the box
  Future<void> close() async {
    if (_eveningStatusBox?.isOpen ?? false) {
      await _eveningStatusBox!.close();
      debugPrint('StorageService: Evening status box closed');
    }
  }
}
