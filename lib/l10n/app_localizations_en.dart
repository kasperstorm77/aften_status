// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Evening Status';

  @override
  String get newEveningStatus => 'New Evening Status';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get reset => 'Reset';

  @override
  String get exportToCsv => 'Export to CSV';

  @override
  String get noEntriesYet => 'No evening entries yet';

  @override
  String get addFirstReflection => 'Add your first evening reflection';

  @override
  String get deleteEntryTitle => 'Delete Entry';

  @override
  String get deleteEntryConfirmation =>
      'Are you sure you want to delete this evening entry?';

  @override
  String averageScore(String score) {
    return 'Avg: $score';
  }

  @override
  String get dataExport => 'Data Export';

  @override
  String get dataExportDescription =>
      'Export your evening status data to CSV format for analysis or backup';

  @override
  String get resetSettingsTitle => 'Reset Settings';

  @override
  String get resetSettingsConfirmation =>
      'Are you sure you want to reset all settings to their default values? This action cannot be undone.';

  @override
  String get customLabel => 'Custom Label';

  @override
  String get enterCustomLabel => 'Enter custom label';

  @override
  String get unitOptional => 'Unit (optional)';

  @override
  String get unitPlaceholder => 'e.g., points, %';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get settingsReset => 'Settings reset to defaults';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get language => 'Language';

  @override
  String get soundSensibility => 'Sound Sensibility';

  @override
  String get sleepQuality => 'Sleep Quality';

  @override
  String get irritability => 'Irritability';

  @override
  String get socialWithdrawal => 'Social Withdrawal';

  @override
  String get emotionalWithdrawal => 'Emotional Withdrawal';

  @override
  String get skinPicking => 'Skin Picking';

  @override
  String get tiredness => 'Tiredness';

  @override
  String get forgetfulnessOnConversations => 'Forgetfulness on Conversations';

  @override
  String get lackOfFocus => 'Lack of Focus';

  @override
  String get lowToleranceTowardPeople => 'Low Tolerance Toward People';

  @override
  String get easyToTears => 'Easy to Tears';

  @override
  String get interrupting => 'Interrupting';

  @override
  String get misunderstanding => 'Misunderstanding';

  @override
  String get selfBlaming => 'Self-blaming';

  @override
  String get sound => 'Sound';

  @override
  String get sleep => 'Sleep';

  @override
  String get irritab => 'Irritab.';

  @override
  String get social => 'Social';

  @override
  String get emotion => 'Emotion';

  @override
  String get skin => 'Skin';

  @override
  String get tired => 'Tired';

  @override
  String get forget => 'Forget';

  @override
  String get focus => 'Focus';

  @override
  String get toleran => 'Toleran.';

  @override
  String get tears => 'Tears';

  @override
  String get interr => 'Interr.';

  @override
  String get misund => 'Misund.';

  @override
  String get blame => 'Blame';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get retry => 'Retry';

  @override
  String get edit => 'Edit';

  @override
  String get requiredField => 'Required Field';

  @override
  String get usersMustFillThisField => 'Users must fill this field';

  @override
  String get active => 'Active';

  @override
  String get showFieldInForms => 'Show field in forms';

  @override
  String get multipleChoiceFieldsMustHaveAtLeastOneOption =>
      'Multiple choice fields must have at least one option';

  @override
  String errorSavingField(String error) {
    return 'Error saving field: $error';
  }

  @override
  String get googleDriveSync => 'Google Drive Sync';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get uploadToGoogleDrive => 'Upload to Google Drive';

  @override
  String get restoreFromGoogleDrive => 'Restore from Google Drive';

  @override
  String get signOut => 'Sign out';

  @override
  String get restoreFromGoogleDriveQuestion => 'Restore from Google Drive?';

  @override
  String get thisWillReplaceYourCurrentData =>
      'This will replace your current data with the backup from Google Drive. This action cannot be undone.';

  @override
  String get restore => 'Restore';

  @override
  String restoredEntriesFromGoogleDrive(int count) {
    return 'Restored $count entries from Google Drive';
  }

  @override
  String get fieldManagement => 'Field Management';

  @override
  String get manageFields => 'Manage Fields';

  @override
  String get addCustomField => 'Add Custom Field';

  @override
  String get deleteField => 'Delete Field';

  @override
  String get areYouSureYouWantToDeleteThisField =>
      'Are you sure you want to delete this field? This will remove it from all entries.';

  @override
  String get restoreDefaultFields => 'Restore Default Fields';

  @override
  String restoredDefaultFields(int count) {
    return 'Restored $count default fields';
  }

  @override
  String get allDefaultFieldsExist => 'All default fields already exist';

  @override
  String get fieldCreatedSuccessfully => 'Field created successfully';

  @override
  String errorCreatingField(String error) {
    return 'Error creating field: $error';
  }

  @override
  String get fieldUpdatedSuccessfully => 'Field updated successfully';

  @override
  String errorUpdatingField(String error) {
    return 'Error updating field: $error';
  }

  @override
  String get fieldDeletedSuccessfully => 'Field deleted successfully';

  @override
  String errorDeletingField(String error) {
    return 'Error deleting field: $error';
  }

  @override
  String get configureGoogleDrive => 'Configure Google Drive';

  @override
  String get appInitializationFailed => 'App initialization failed';

  @override
  String get noDataToExport => 'No data to export';

  @override
  String exportFailed2(String error) {
    return 'Export failed: $error';
  }

  @override
  String get syncYourData => 'Sync your data with Google Drive';

  @override
  String get customizeFields => 'Customize your tracking fields';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get signedIn => 'Signed In';

  @override
  String get signedOut => 'Signed Out';

  @override
  String get syncOptions => 'Sync Options';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get autoSyncDescription => 'Automatically sync when changes are made';

  @override
  String get uploadNow => 'Upload Now';

  @override
  String get downloadNow => 'Download Now';

  @override
  String get availableBackups => 'Available Backups';

  @override
  String get noBackupsAvailable => 'No backups available';

  @override
  String get selectBackup => 'Select a backup';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoreBackupConfirmation =>
      'This will replace your current data with the selected backup. Continue?';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get signOutGoogle => 'Sign Out Google';

  @override
  String get syncWithGoogleDrive => 'Sync with Google Drive';

  @override
  String get exportToJson => 'Export to JSON';

  @override
  String get importFromJson => 'Import from JSON';

  @override
  String get selectRestorePoint => 'Select Restore Point';

  @override
  String get backupsAvailable => 'backups available';

  @override
  String get restoreFromBackup => 'Restore from Backup';

  @override
  String get uploadToGoogleDriveManual => 'Upload to Google Drive (Manual)';

  @override
  String get deleteAllEntries => 'Delete All Entries';

  @override
  String get deleteAllConfirmation =>
      'Are you sure you want to delete all entries? This action cannot be undone.';

  @override
  String get allEntriesDeleted => 'All entries deleted';

  @override
  String get importedEntries => 'Imported entries';

  @override
  String get uploadSuccess => 'Upload successful';

  @override
  String get restoreSuccess => 'Restore successful';

  @override
  String get syncStatusInSync => 'In sync';

  @override
  String get syncStatusLocalNewer => 'Local changes pending upload';

  @override
  String get syncStatusRemoteNewer => 'Remote changes available';

  @override
  String get syncStatusLocalOnly => 'Not yet synced to cloud';

  @override
  String get syncStatusRemoteOnly => 'Cloud data available';

  @override
  String get syncStatusNoData => 'No data';

  @override
  String lastSynced(String date) {
    return 'Last synced: $date';
  }

  @override
  String get backupRetentionInfo => 'Backups: Today (all) + 7 days (1 per day)';

  @override
  String get showLess => 'Show less';

  @override
  String showMore(int count) {
    return 'Show $count more';
  }

  @override
  String get graph => 'Trends';

  @override
  String get legend => 'Legend';

  @override
  String get showAll => 'Toggle All';
}
