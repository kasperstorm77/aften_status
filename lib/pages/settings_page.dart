import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/evening_status_drive_service.dart';
import '../services/field_definition_service.dart';
import '../services/storage_service.dart';
import '../services/localization_service.dart';
import '../models/evening_status.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/responsive_layout.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _driveService = EveningStatusDriveService.instance;
  late StorageService _storageService;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableBackups = [];

  @override
  void initState() {
    super.initState();
    _storageService = Modular.get<StorageService>();
    _initServices();
  }

  Future<void> _initServices() async {
    setState(() => _isLoading = true);
    try {
      await _driveService.initialize();
      if (_driveService.isAuthenticated) {
        await _loadBackups();
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBackups() async {
    try {
      _availableBackups = await _driveService.listAvailableBackups();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading backups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.dataManagement,
        showSettings: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.getMaxWidth(context),
                  ),
                  child: Padding(
                    padding: ResponsiveLayout.getHorizontalPadding(context).add(
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Manage Fields
                        _buildManageFieldsButton(context, l10n),
                        const SizedBox(height: 24),
                        
                        // Sign In/Out Button
                        _buildAuthButton(context, l10n),
                        const SizedBox(height: 16),
                        
                        // Google Drive Sync Toggle
                        _buildSyncToggle(context, l10n),
                        const SizedBox(height: 16),
                        
                        // Export to JSON
                        _buildExportButton(context, l10n),
                        const SizedBox(height: 12),
                        
                        // Export to CSV
                        _buildExportCsvButton(context, l10n),
                        const SizedBox(height: 12),
                        
                        // Import from JSON
                        _buildImportButton(context, l10n),
                        const SizedBox(height: 24),
                        
                        // Restore from Backup Section
                        _buildBackupSection(context, l10n),
                        const SizedBox(height: 16),
                        
                        // Upload to Google Drive (Manual)
                        _buildUploadButton(context, l10n),
                        const SizedBox(height: 12),
                        
                        // Disconnect Google Drive & Delete Backup
                        _buildDisconnectButton(context, l10n),
                        const SizedBox(height: 24),
                        
                        // Delete All Entries
                        _buildDeleteAllButton(context, l10n),
                        const SizedBox(height: 24),
                        
                        // Debug: Clear All Backups (only visible in debug mode)
                        if (kDebugMode) ...[                          
                          _buildClearBackupsButton(context, l10n),
                          const SizedBox(height: 12),
                          _buildGenerateSampleDataButton(context, l10n),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAuthButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : (_driveService.isAuthenticated ? _signOut : _signIn),
      icon: Icon(_driveService.isAuthenticated ? Icons.logout : Icons.login),
      label: Text(
        _driveService.isAuthenticated 
            ? l10n.signOutGoogle
            : l10n.signInWithGoogle,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildManageFieldsButton(BuildContext context, AppLocalizations l10n) {
    return FilledButton.icon(
      onPressed: () => Modular.to.pushNamed('/settings/fields'),
      icon: const Icon(Icons.tune),
      label: Text(l10n.manageFields),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildSyncToggle(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.syncWithGoogleDrive,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Switch(
          value: _driveService.syncEnabled,
          onChanged: _driveService.isAuthenticated 
              ? (value) async {
                  await _driveService.setSyncEnabled(value);
                  setState(() {});
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildExportButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton(
      onPressed: _exportToJson,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      child: Text(l10n.exportToJson),
    );
  }

  Widget _buildExportCsvButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _exportToCsv,
      icon: const Icon(Icons.table_chart_outlined),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      label: Text(l10n.exportToCsv),
    );
  }

  Widget _buildImportButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton(
      onPressed: () => _showMessage('Import from Files app coming soon'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      child: Text(l10n.importFromJson),
    );
  }

  String? _selectedBackup;

  Widget _buildBackupSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Text(
                  l10n.selectRestorePoint,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _driveService.isAuthenticated ? _loadBackups : null,
                  tooltip: 'Refresh backups',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Backup dropdown
            if (!_driveService.isAuthenticated)
              Text(
                'Sign in to Google to see available backups',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else if (_availableBackups.isEmpty)
              Text(
                l10n.noBackupsAvailable,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedBackup,
                decoration: InputDecoration(
                  labelText: l10n.selectBackup,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: Text('${_availableBackups.length} ${l10n.backupsAvailable}'),
                isExpanded: true,
                items: _availableBackups.map((backup) {
                  final fileName = backup['fileName'] as String? ?? 'Unknown';
                  final displayDate = backup['displayDate'] as String? ?? '';
                  return DropdownMenuItem<String>(
                    value: fileName,
                    child: Text(displayDate.isNotEmpty ? displayDate : fileName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedBackup = value);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedBackup != null ? () => _restoreSelectedBackup() : null,
                  icon: const Icon(Icons.download),
                  label: Text(l10n.restoreFromBackup),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _restoreSelectedBackup() async {
    if (_selectedBackup == null) return;
    
    final backup = _availableBackups.firstWhere(
      (b) => b['fileName'] == _selectedBackup,
      orElse: () => {},
    );
    
    if (backup.isNotEmpty) {
      await _restoreBackup(backup);
    }
  }

  Widget _buildUploadButton(BuildContext context, AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: _driveService.isAuthenticated ? _uploadToGoogleDrive : null,
      icon: const Icon(Icons.cloud_upload),
      label: Text(l10n.uploadToGoogleDriveManual),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildDisconnectButton(BuildContext context, AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: _driveService.isAuthenticated ? _showDisconnectDialog : null,
      icon: const Icon(Icons.link_off),
      label: Text(l10n.disconnectGoogleDrive),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildDeleteAllButton(BuildContext context, AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: _showDeleteAllDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(l10n.deleteAllEntries),
    );
  }

  Widget _buildClearBackupsButton(BuildContext context, AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: _driveService.isAuthenticated ? _clearAllBackups : null,
      icon: const Icon(Icons.delete_forever),
      label: const Text('[DEBUG] Clear All Backups'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildGenerateSampleDataButton(BuildContext context, AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: _generateSampleData,
      icon: const Icon(Icons.auto_fix_high),
      label: const Text('[DEBUG] Generate 20 Sample Entries'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // === Actions ===

  Future<void> _clearAllBackups() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('[DEBUG] Clear All Backups'),
        content: const Text('This will delete ALL backup files from Google Drive. This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      // Delete all backup files
      for (final backup in _availableBackups) {
        final fileId = backup['fileId'] as String?;
        if (fileId != null) {
          await _driveService.deleteBackupFile(fileId);
        }
      }
      
      _availableBackups.clear();
      _selectedBackup = null;
      _showMessage('All backups deleted');
      await _loadBackups();
    } catch (e) {
      _showError('Failed to clear backups: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('[DEBUG] Generate Sample Data'),
        content: const Text('This will create 20 random entries spread over the last 20 days. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final fieldService = Modular.get<FieldDefinitionService>();
      final allFields = await fieldService.getActiveFields();
      final random = Random();
      
      // Generate 20 entries, one per day for the last 20 days
      for (int i = 19; i >= 0; i--) {
        final entryDate = DateTime.now().subtract(Duration(days: i));
        final fieldValues = <String, dynamic>{};
        
        // Generate random values for each active field
        for (final field in allFields) {
          // Generate value between 1 and 10 with some variance
          final baseValue = 3 + random.nextDouble() * 5; // 3-8 base range
          final variance = random.nextDouble() * 2 - 1; // -1 to +1
          final value = (baseValue + variance).clamp(1.0, 10.0);
          fieldValues[field.id] = double.parse(value.toStringAsFixed(1));
        }
        
        final entry = EveningStatus(
          timestamp: DateTime(entryDate.year, entryDate.month, entryDate.day, 21, 0),
          fieldValues: fieldValues,
          schemaVersion: 2,
        );
        
        await _storageService.saveEveningStatus(entry);
      }
      
      _showMessage('Created 20 sample entries');
    } catch (e) {
      _showError('Failed to generate sample data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await _driveService.signIn();
      if (_driveService.isAuthenticated) {
        await _loadBackups();
      }
    } catch (e) {
      _showError('Sign in failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await _driveService.signOut();
      _availableBackups.clear();
    } catch (e) {
      _showError('Sign out failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToJson() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() => _isLoading = true);
      
      final entries = await _storageService.getAllEveningStatus();
      if (entries.isEmpty) {
        _showMessage(l10n.noDataToExport);
        return;
      }

      // Get field definitions for export
      final fieldService = Modular.get<FieldDefinitionService>();
      final fields = await fieldService.getAllFields();
      final fieldDefinitions = fields.map((def) => def.toMap()).toList();

      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'fieldDefinitions': fieldDefinitions,
        'entries': entries.map((e) => e.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // Save to temp file and share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/aften_status_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles([XFile(file.path)], subject: 'Aften Status Export');
      
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCsv() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() => _isLoading = true);
      
      final entries = await _storageService.getAllEveningStatus();
      if (entries.isEmpty) {
        _showMessage(l10n.noDataToExport);
        return;
      }

      // Get field definitions for column headers
      final fieldService = Modular.get<FieldDefinitionService>();
      final fields = await fieldService.getAllFields();
      
      // Get locale for localized field names
      final locale = Localizations.localeOf(context).languageCode;
      
      // Build CSV header
      final headers = <String>['Date', 'Time'];
      for (final field in fields) {
        headers.add(_escapeCsvValue(field.getDisplayLabel(locale)));
      }
      
      final csvLines = <String>[headers.join(',')];
      
      // Sort entries by timestamp (oldest first)
      final sortedEntries = List<EveningStatus>.from(entries)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Build CSV rows
      for (final entry in sortedEntries) {
        final row = <String>[
          _formatDate(entry.timestamp),
          _formatTime(entry.timestamp),
        ];
        
        for (final field in fields) {
          final value = entry.fieldValues[field.id];
          if (value == null) {
            row.add('');
          } else if (value is double) {
            row.add(value.toStringAsFixed(1));
          } else {
            row.add(_escapeCsvValue(value.toString()));
          }
        }
        
        csvLines.add(row.join(','));
      }
      
      final csvContent = csvLines.join('\n');
      
      // Save to temp file and share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/aften_status_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent);
      
      await Share.shareXFiles([XFile(file.path)], subject: 'Aften Status CSV Export');
      
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _escapeCsvValue(String value) {
    // If value contains comma, quote, or newline, wrap in quotes and escape quotes
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadToGoogleDrive() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      // Get the evening status box and upload
      final box = Hive.box<EveningStatus>('evening_status');
      await _driveService.uploadFromBox(box, notifyUI: true);
      _showMessage(l10n.uploadSuccess);
      await _loadBackups();
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreBackup),
        content: Text(l10n.restoreBackupConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final fileName = backup['fileName'] as String?;
      if (fileName == null) throw Exception('No backup file name');
      
      final content = await _driveService.downloadBackup(fileName);
      if (content == null) throw Exception('Failed to download backup');
      
      final box = Hive.box<EveningStatus>('evening_status');
      await _driveService.restoreFromContent(content, box);
      
      // Reload field definitions service to pick up restored fields
      await FieldDefinitionService().reload();
      
      _showMessage(l10n.restoreSuccess);
    } catch (e) {
      _showError('Restore failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteAllDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllEntries),
        content: Text(l10n.deleteAllConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAllEntries();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.disconnectGoogleDrive),
        content: Text(l10n.disconnectConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _disconnectAndDeleteBackups();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.disconnect),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectAndDeleteBackups() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() => _isLoading = true);
    try {
      // Get backup file IDs BEFORE signing out (required for deletion)
      final fileIds = await _driveService.getBackupFileIds();
      
      // Sign out immediately for instant UI feedback
      await _driveService.signOut();
      _availableBackups.clear();
      _selectedBackup = null;
      setState(() => _isLoading = false);
      _showMessage(l10n.disconnectSuccess);
      
      // Delete backups in the background (don't await)
      _driveService.deleteBackupsInBackground(fileIds);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(l10n.disconnectFailed(e.toString()));
    }
  }

  Future<void> _deleteAllEntries() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await _storageService.emergencyReset();
      _showMessage(l10n.allEntriesDeleted);
    } catch (e) {
      _showError('Delete failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
