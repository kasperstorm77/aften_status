import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/evening_status_drive_service.dart';
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
                        // Sign In/Out Button
                        _buildAuthButton(context, l10n),
                        const SizedBox(height: 16),
                        
                        // Google Drive Sync Toggle
                        _buildSyncToggle(context, l10n),
                        const SizedBox(height: 16),
                        
                        // Export to JSON
                        _buildExportButton(context, l10n),
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
                        
                        // Delete All Entries
                        _buildDeleteAllButton(context, l10n),
                        const SizedBox(height: 24),
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _availableBackups.isEmpty 
                  ? l10n.noBackupsAvailable
                  : '${_availableBackups.length} ${l10n.backupsAvailable}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _availableBackups.isNotEmpty ? _showRestoreDialog : null,
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
        ),
      ),
    );
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

  // === Actions ===

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

      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
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

  void _showRestoreDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectRestorePoint),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableBackups.length,
            itemBuilder: (context, index) {
              final backup = _availableBackups[index];
              return ListTile(
                leading: const Icon(Icons.backup),
                title: Text(backup['fileName'] ?? 'Backup ${index + 1}'),
                subtitle: backup['date'] != null 
                    ? Text(_formatDate(backup['date'] as DateTime))
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _restoreBackup(backup);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
