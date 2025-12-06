import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/evening_status.dart';
import '../services/evening_status_drive_service.dart';
import '../services/storage_service.dart';
import '../services/localization_service.dart';
import 'widgets/common_app_bar.dart';

class GoogleDriveSyncPage extends StatefulWidget {
  const GoogleDriveSyncPage({super.key});

  @override
  State<GoogleDriveSyncPage> createState() => _GoogleDriveSyncPageState();
}

class _GoogleDriveSyncPageState extends State<GoogleDriveSyncPage> {
  final _driveService = EveningStatusDriveService.instance;
  final StorageService _storageService = Modular.get<StorageService>();
  
  bool _isLoading = false;
  String? _statusMessage;
  List<Map<String, dynamic>> _availableBackups = [];
  Map<String, dynamic>? _selectedBackup;
  
  @override
  void initState() {
    super.initState();
    _initDriveService();
  }

  Future<void> _initDriveService() async {
    setState(() => _isLoading = true);
    try {
      await _driveService.initialize();
      if (_driveService.isAuthenticated) {
        await _loadBackups();
      }
    } catch (e) {
      debugPrint('Error initializing drive service: $e');
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
        title: l10n.googleDriveSync,
        showSettings: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAuthSection(context),
                  if (_driveService.isAuthenticated) ...[
                    const SizedBox(height: 24),
                    _buildSyncSection(context),
                    const SizedBox(height: 24),
                    _buildBackupsSection(context),
                  ],
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildStatusMessage(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAuthSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _driveService.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                  color: _driveService.isAuthenticated ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  _driveService.isAuthenticated 
                      ? l10n.signedIn 
                      : l10n.signedOut,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : (_driveService.isAuthenticated ? _signOut : _signIn),
                icon: Icon(_driveService.isAuthenticated ? Icons.logout : Icons.login),
                label: Text(_driveService.isAuthenticated ? l10n.signOut : l10n.signInWithGoogle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.syncOptions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.autoSync),
              subtitle: Text(l10n.autoSyncDescription),
              value: _driveService.syncEnabled,
              onChanged: (value) async {
                await _driveService.setSyncEnabled(value);
                setState(() {});
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: Text(l10n.uploadNow),
              onTap: _uploadToGoogleDrive,
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: Text(l10n.downloadNow),
              onTap: _downloadFromGoogleDrive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.availableBackups,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBackups,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_availableBackups.isEmpty)
              Text(l10n.noBackupsAvailable)
            else ...[
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: _selectedBackup,
                decoration: InputDecoration(
                  labelText: l10n.selectBackup,
                  border: const OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _availableBackups.map((backup) {
                  final fileName = backup['fileName'] as String? ?? 'Unknown';
                  final date = backup['date'] as DateTime?;
                  final displayText = date != null
                      ? '$fileName (${_formatDate(date)})'
                      : fileName;
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: backup,
                    child: Text(
                      displayText,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  onPressed: _selectedBackup != null
                      ? () => _restoreBackup(_selectedBackup!)
                      : null,
                  icon: const Icon(Icons.restore),
                  label: Text(l10n.restoreBackup),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    final isError = _statusMessage!.toLowerCase().contains('error') ||
                    _statusMessage!.toLowerCase().contains('failed');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _statusMessage!,
        style: TextStyle(
          color: isError ? Colors.red.shade800 : Colors.green.shade800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    
    try {
      final success = await _driveService.signIn();
      if (success) {
        await _loadBackups();
        _statusMessage = 'Signed in successfully';
      } else {
        _statusMessage = 'Sign in cancelled';
      }
    } catch (e) {
      _statusMessage = 'Sign in failed: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    
    try {
      await _driveService.signOut();
      _availableBackups = [];
      _statusMessage = 'Signed out successfully';
    } catch (e) {
      _statusMessage = 'Sign out failed: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadToGoogleDrive() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    
    try {
      await _storageService.init();
      final box = Hive.box<EveningStatus>('evening_status');
      await _driveService.uploadFromBox(box, notifyUI: true);
      await _loadBackups();
      _statusMessage = 'Uploaded ${box.length} entries successfully';
    } catch (e) {
      _statusMessage = 'Upload failed: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFromGoogleDrive() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    
    try {
      final content = await _driveService.downloadContent();
      if (content != null) {
        await _storageService.init();
        final box = Hive.box<EveningStatus>('evening_status');
        final count = await _driveService.restoreFromContent(content, box);
        _statusMessage = 'Restored $count entries successfully';
      } else {
        _statusMessage = 'No backup found on Google Drive';
      }
    } catch (e) {
      _statusMessage = 'Download failed: $e';
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
    
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    
    try {
      final fileName = backup['fileName'] as String;
      final content = await _driveService.downloadBackup(fileName);
      if (content != null) {
        await _storageService.init();
        final box = Hive.box<EveningStatus>('evening_status');
        final count = await _driveService.restoreFromContent(content, box);
        _statusMessage = 'Restored $count entries from backup';
      } else {
        _statusMessage = 'Failed to download backup';
      }
    } catch (e) {
      _statusMessage = 'Restore failed: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
