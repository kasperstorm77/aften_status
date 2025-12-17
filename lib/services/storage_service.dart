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
      await init();
    }
  }

  Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(EveningStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FieldDefinitionAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FieldTypeAdapter());
      }
      
      // Open box with recovery for schema errors
      try {
        _eveningStatusBox = await Hive.openBox<EveningStatus>(_eveningStatusBoxName);
      } catch (e) {
        final message = e.toString();
        if (message.contains('unknown typeId') || 
            message.contains('Unknown typeId') ||
            message.contains('not a subtype of type') ||
            message.contains('type cast') ||
            message.contains('FormatException')) {
          // Corrupted box - delete and recreate
          await Hive.deleteBoxFromDisk(_eveningStatusBoxName);
          _eveningStatusBox = await Hive.openBox<EveningStatus>(_eveningStatusBoxName);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService: Init failed: $e');
      rethrow;
    }
  }

  // Save a new evening status entry
  Future<void> saveEveningStatus(EveningStatus status) async {
    await _ensureInitialized();
    await _eveningStatusBox!.add(status);
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Update an existing evening status entry
  Future<void> updateEveningStatus(int index, EveningStatus status) async {
    await _ensureInitialized();
    await _eveningStatusBox!.putAt(index, status);
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Delete an evening status entry
  Future<void> deleteEveningStatus(int index) async {
    await _ensureInitialized();
    await _eveningStatusBox!.deleteAt(index);
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Get all evening status entries
  Future<List<EveningStatus>> getAllEveningStatus() async {
    await _ensureInitialized();
    return _eveningStatusBox!.values.toList();
  }

  // Get entries within a date range
  Future<List<EveningStatus>> getEntriesInRange(DateTime start, DateTime end) async {
    await _ensureInitialized();
    return _eveningStatusBox!.values.where((entry) {
      return entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end);
    }).toList();
  }

  // Replace all entries (used for restore operations)
  Future<void> replaceAllEveningStatus(List<EveningStatus> entries) async {
    await _ensureInitialized();
    await _eveningStatusBox!.clear();
    await _eveningStatusBox!.addAll(entries);
    unawaited(_triggerAutoSync()); // Fire-and-forget for responsive UI
  }

  // Emergency reset - delete all data
  Future<void> emergencyReset() async {
    await _ensureInitialized();
    await _eveningStatusBox!.clear();
  }

  // Trigger automatic sync to Google Drive if enabled (debounced)
  Future<void> _triggerAutoSync() async {
    try {
      // Always update local timestamp when data changes
      await _driveService.updateLocalLastModified();
      
      if (_driveService.syncEnabled && _driveService.isAuthenticated) {
        // Use debounced sync to prevent rapid-fire uploads
        _driveService.scheduleDebouncedSync();
      }
    } catch (e) {
      // Don't rethrow - sync failure shouldn't break local operations
    }
  }

  // Close the box
  Future<void> close() async {
    if (_eveningStatusBox?.isOpen ?? false) {
      await _eveningStatusBox!.close();
    }
  }
}
