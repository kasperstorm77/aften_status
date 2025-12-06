import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models/evening_status.dart';
import 'storage_service.dart';
import 'localization_service.dart';

class HomeController extends ChangeNotifier {
  final StorageService _storageService = Modular.get<StorageService>();

  List<EveningStatus> _entries = [];
  bool _isLoading = false;

  List<EveningStatus> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('HomeController: Initializing storage service...');
      await _storageService.init();
      
      debugPrint('HomeController: Loading local entries...');
      await loadEntries();
      debugPrint('HomeController: Loaded ${_entries.length} local entries');
    } catch (e) {
      debugPrint('Error initializing HomeController: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEntries() async {
    try {
      _entries = await _storageService.getAllEveningStatus();
      // Sort by timestamp, latest first
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading entries: $e');
    }
  }

  Future<void> deleteEntry(int index) async {
    try {
      await _storageService.deleteEveningStatus(index);
      await loadEntries(); // Reload to refresh the list
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }

  Future<void> addNewEntry() async {
    final result = await Modular.to.pushNamed('/add-entry');
    if (result == true) {
      await loadEntries(); // Reload entries if a new one was added
    }
  }

  Future<void> editEntry(int index) async {
    final result = await Modular.to.pushNamed('/edit-entry/$index');
    if (result == true) {
      await loadEntries(); // Reload entries if one was edited
    }
  }

  String formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      final l10n = AppLocalizations.of(context);
      return l10n?.today ?? 'Today';
    } else if (entryDate == yesterday) {
      final l10n = AppLocalizations.of(context);
      return l10n?.yesterday ?? 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
