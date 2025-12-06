import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Evening Status'**
  String get appTitle;

  /// Title for creating a new evening entry
  ///
  /// In en, this message translates to:
  /// **'New Evening Status'**
  String get newEveningStatus;

  /// Title for editing an existing entry
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Reset button text
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Export data to CSV button text
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCsv;

  /// Message when no entries exist
  ///
  /// In en, this message translates to:
  /// **'No evening entries yet'**
  String get noEntriesYet;

  /// Subtitle message when no entries exist
  ///
  /// In en, this message translates to:
  /// **'Add your first evening reflection'**
  String get addFirstReflection;

  /// Title of delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntryTitle;

  /// Delete confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this evening entry?'**
  String get deleteEntryConfirmation;

  /// Average score display
  ///
  /// In en, this message translates to:
  /// **'Avg: {score}'**
  String averageScore(String score);

  /// Data export section title
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// Data export section description
  ///
  /// In en, this message translates to:
  /// **'Export your evening status data to CSV format for analysis or backup'**
  String get dataExportDescription;

  /// Reset settings dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettingsTitle;

  /// Reset settings confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all settings to their default values? This action cannot be undone.'**
  String get resetSettingsConfirmation;

  /// Custom label field hint
  ///
  /// In en, this message translates to:
  /// **'Custom Label'**
  String get customLabel;

  /// Custom label field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter custom label'**
  String get enterCustomLabel;

  /// Unit field label
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get unitOptional;

  /// Unit field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g., points, %'**
  String get unitPlaceholder;

  /// Settings saved success message
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// Settings reset success message
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsReset;

  /// Export error message
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// Save settings button text
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @soundSensibility.
  ///
  /// In en, this message translates to:
  /// **'Sound Sensibility'**
  String get soundSensibility;

  /// No description provided for @sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
  String get sleepQuality;

  /// No description provided for @irritability.
  ///
  /// In en, this message translates to:
  /// **'Irritability'**
  String get irritability;

  /// No description provided for @socialWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Social Withdrawal'**
  String get socialWithdrawal;

  /// No description provided for @emotionalWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Emotional Withdrawal'**
  String get emotionalWithdrawal;

  /// No description provided for @skinPicking.
  ///
  /// In en, this message translates to:
  /// **'Skin Picking'**
  String get skinPicking;

  /// No description provided for @tiredness.
  ///
  /// In en, this message translates to:
  /// **'Tiredness'**
  String get tiredness;

  /// No description provided for @forgetfulnessOnConversations.
  ///
  /// In en, this message translates to:
  /// **'Forgetfulness on Conversations'**
  String get forgetfulnessOnConversations;

  /// No description provided for @lackOfFocus.
  ///
  /// In en, this message translates to:
  /// **'Lack of Focus'**
  String get lackOfFocus;

  /// No description provided for @lowToleranceTowardPeople.
  ///
  /// In en, this message translates to:
  /// **'Low Tolerance Toward People'**
  String get lowToleranceTowardPeople;

  /// No description provided for @easyToTears.
  ///
  /// In en, this message translates to:
  /// **'Easy to Tears'**
  String get easyToTears;

  /// No description provided for @interrupting.
  ///
  /// In en, this message translates to:
  /// **'Interrupting'**
  String get interrupting;

  /// No description provided for @misunderstanding.
  ///
  /// In en, this message translates to:
  /// **'Misunderstanding'**
  String get misunderstanding;

  /// No description provided for @selfBlaming.
  ///
  /// In en, this message translates to:
  /// **'Self-blaming'**
  String get selfBlaming;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @irritab.
  ///
  /// In en, this message translates to:
  /// **'Irritab.'**
  String get irritab;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @emotion.
  ///
  /// In en, this message translates to:
  /// **'Emotion'**
  String get emotion;

  /// No description provided for @skin.
  ///
  /// In en, this message translates to:
  /// **'Skin'**
  String get skin;

  /// No description provided for @tired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get tired;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @toleran.
  ///
  /// In en, this message translates to:
  /// **'Toleran.'**
  String get toleran;

  /// No description provided for @tears.
  ///
  /// In en, this message translates to:
  /// **'Tears'**
  String get tears;

  /// No description provided for @interr.
  ///
  /// In en, this message translates to:
  /// **'Interr.'**
  String get interr;

  /// No description provided for @misund.
  ///
  /// In en, this message translates to:
  /// **'Misund.'**
  String get misund;

  /// No description provided for @blame.
  ///
  /// In en, this message translates to:
  /// **'Blame'**
  String get blame;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required Field'**
  String get requiredField;

  /// No description provided for @usersMustFillThisField.
  ///
  /// In en, this message translates to:
  /// **'Users must fill this field'**
  String get usersMustFillThisField;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @showFieldInForms.
  ///
  /// In en, this message translates to:
  /// **'Show field in forms'**
  String get showFieldInForms;

  /// No description provided for @multipleChoiceFieldsMustHaveAtLeastOneOption.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice fields must have at least one option'**
  String get multipleChoiceFieldsMustHaveAtLeastOneOption;

  /// No description provided for @errorSavingField.
  ///
  /// In en, this message translates to:
  /// **'Error saving field: {error}'**
  String errorSavingField(String error);

  /// No description provided for @googleDriveSync.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get googleDriveSync;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @uploadToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Upload to Google Drive'**
  String get uploadToGoogleDrive;

  /// No description provided for @restoreFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get restoreFromGoogleDrive;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @restoreFromGoogleDriveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive?'**
  String get restoreFromGoogleDriveQuestion;

  /// No description provided for @thisWillReplaceYourCurrentData.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current data with the backup from Google Drive. This action cannot be undone.'**
  String get thisWillReplaceYourCurrentData;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoredEntriesFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} entries from Google Drive'**
  String restoredEntriesFromGoogleDrive(int count);

  /// No description provided for @fieldManagement.
  ///
  /// In en, this message translates to:
  /// **'Field Management'**
  String get fieldManagement;

  /// No description provided for @manageFields.
  ///
  /// In en, this message translates to:
  /// **'Manage Fields'**
  String get manageFields;

  /// No description provided for @addCustomField.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Field'**
  String get addCustomField;

  /// No description provided for @deleteField.
  ///
  /// In en, this message translates to:
  /// **'Delete Field'**
  String get deleteField;

  /// No description provided for @areYouSureYouWantToDeleteThisField.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this field? This will remove it from all entries.'**
  String get areYouSureYouWantToDeleteThisField;

  /// No description provided for @fieldCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Field created successfully'**
  String get fieldCreatedSuccessfully;

  /// No description provided for @errorCreatingField.
  ///
  /// In en, this message translates to:
  /// **'Error creating field: {error}'**
  String errorCreatingField(String error);

  /// No description provided for @fieldUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Field updated successfully'**
  String get fieldUpdatedSuccessfully;

  /// No description provided for @errorUpdatingField.
  ///
  /// In en, this message translates to:
  /// **'Error updating field: {error}'**
  String errorUpdatingField(String error);

  /// No description provided for @fieldDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Field deleted successfully'**
  String get fieldDeletedSuccessfully;

  /// No description provided for @errorDeletingField.
  ///
  /// In en, this message translates to:
  /// **'Error deleting field: {error}'**
  String errorDeletingField(String error);

  /// No description provided for @configureGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Configure Google Drive'**
  String get configureGoogleDrive;

  /// No description provided for @appInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'App initialization failed'**
  String get appInitializationFailed;

  /// No description provided for @noDataToExport.
  ///
  /// In en, this message translates to:
  /// **'No data to export'**
  String get noDataToExport;

  /// No description provided for @exportFailed2.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed2(String error);

  /// No description provided for @syncYourData.
  ///
  /// In en, this message translates to:
  /// **'Sync your data with Google Drive'**
  String get syncYourData;

  /// No description provided for @customizeFields.
  ///
  /// In en, this message translates to:
  /// **'Customize your tracking fields'**
  String get customizeFields;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed In'**
  String get signedIn;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed Out'**
  String get signedOut;

  /// No description provided for @syncOptions.
  ///
  /// In en, this message translates to:
  /// **'Sync Options'**
  String get syncOptions;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get autoSync;

  /// No description provided for @autoSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync when changes are made'**
  String get autoSyncDescription;

  /// No description provided for @uploadNow.
  ///
  /// In en, this message translates to:
  /// **'Upload Now'**
  String get uploadNow;

  /// No description provided for @downloadNow.
  ///
  /// In en, this message translates to:
  /// **'Download Now'**
  String get downloadNow;

  /// No description provided for @availableBackups.
  ///
  /// In en, this message translates to:
  /// **'Available Backups'**
  String get availableBackups;

  /// No description provided for @noBackupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No backups available'**
  String get noBackupsAvailable;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current data with the selected backup. Continue?'**
  String get restoreBackupConfirmation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['da', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
