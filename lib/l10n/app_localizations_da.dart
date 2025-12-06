// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Aften Status';

  @override
  String get newEveningStatus => 'Ny Aften Status';

  @override
  String get editEntry => 'Rediger Indtastning';

  @override
  String get settings => 'Indstillinger';

  @override
  String get save => 'Gem';

  @override
  String get update => 'Opdater';

  @override
  String get cancel => 'Annuller';

  @override
  String get delete => 'Slet';

  @override
  String get reset => 'Nulstil';

  @override
  String get exportToCsv => 'Eksporter til CSV';

  @override
  String get noEntriesYet => 'Ingen aften indtastninger endnu';

  @override
  String get addFirstReflection => 'Tilføj din første aften reflektion';

  @override
  String get deleteEntryTitle => 'Slet Indtastning';

  @override
  String get deleteEntryConfirmation =>
      'Er du sikker på, at du vil slette denne aften indtastning?';

  @override
  String averageScore(String score) {
    return 'Gnmsn: $score';
  }

  @override
  String get dataExport => 'Data Eksport';

  @override
  String get dataExportDescription =>
      'Eksporter dine aften status data til CSV format til analyse eller backup';

  @override
  String get resetSettingsTitle => 'Nulstil Indstillinger';

  @override
  String get resetSettingsConfirmation =>
      'Er du sikker på, at du vil nulstille alle indstillinger til deres standardværdier? Denne handling kan ikke fortrydes.';

  @override
  String get customLabel => 'Brugerdefineret Etiket';

  @override
  String get enterCustomLabel => 'Indtast brugerdefineret etiket';

  @override
  String get unitOptional => 'Enhed (valgfri)';

  @override
  String get unitPlaceholder => 'f.eks., point, %';

  @override
  String get settingsSaved => 'Indstillinger gemt succesfuldt';

  @override
  String get settingsReset => 'Indstillinger nulstillet til standard';

  @override
  String exportFailed(String error) {
    return 'Eksport mislykkedes: $error';
  }

  @override
  String get saveSettings => 'Gem Indstillinger';

  @override
  String get language => 'Sprog';

  @override
  String get soundSensibility => 'Lyd Følsomhed';

  @override
  String get sleepQuality => 'Søvn Kvalitet';

  @override
  String get irritability => 'Irritabilitet';

  @override
  String get socialWithdrawal => 'Social Tilbagetrækning';

  @override
  String get emotionalWithdrawal => 'Følelsesmæssig Tilbagetrækning';

  @override
  String get skinPicking => 'Hud Plukning';

  @override
  String get tiredness => 'Træthed';

  @override
  String get forgetfulnessOnConversations => 'Glemsel i Samtaler';

  @override
  String get lackOfFocus => 'Mangel på Fokus';

  @override
  String get lowToleranceTowardPeople => 'Lav Tolerance Overfor Folk';

  @override
  String get easyToTears => 'Let til Tårer';

  @override
  String get interrupting => 'Afbrydelse';

  @override
  String get misunderstanding => 'Misforståelse';

  @override
  String get selfBlaming => 'Selvbebrejdelse';

  @override
  String get sound => 'Lyd';

  @override
  String get sleep => 'Søvn';

  @override
  String get irritab => 'Irritab.';

  @override
  String get social => 'Social';

  @override
  String get emotion => 'Følelse';

  @override
  String get skin => 'Hud';

  @override
  String get tired => 'Træt';

  @override
  String get forget => 'Glem';

  @override
  String get focus => 'Fokus';

  @override
  String get toleran => 'Toleran.';

  @override
  String get tears => 'Tårer';

  @override
  String get interr => 'Afbryd.';

  @override
  String get misund => 'Misforst.';

  @override
  String get blame => 'Bebrejd.';

  @override
  String get today => 'I dag';

  @override
  String get yesterday => 'I går';

  @override
  String get retry => 'Prøv igen';

  @override
  String get edit => 'Rediger';

  @override
  String get requiredField => 'Påkrævet Felt';

  @override
  String get usersMustFillThisField => 'Brugere skal udfylde dette felt';

  @override
  String get active => 'Aktiv';

  @override
  String get showFieldInForms => 'Vis felt i formularer';

  @override
  String get multipleChoiceFieldsMustHaveAtLeastOneOption =>
      'Flervalgsmuligheder skal have mindst én mulighed';

  @override
  String errorSavingField(String error) {
    return 'Fejl ved gemning af felt: $error';
  }

  @override
  String get googleDriveSync => 'Google Drive Synkronisering';

  @override
  String get signInWithGoogle => 'Log ind med Google';

  @override
  String get uploadToGoogleDrive => 'Upload til Google Drive';

  @override
  String get restoreFromGoogleDrive => 'Gendan fra Google Drive';

  @override
  String get signOut => 'Log ud';

  @override
  String get restoreFromGoogleDriveQuestion => 'Gendan fra Google Drive?';

  @override
  String get thisWillReplaceYourCurrentData =>
      'Dette vil erstatte dine nuværende data med backup fra Google Drive. Denne handling kan ikke fortrydes.';

  @override
  String get restore => 'Gendan';

  @override
  String restoredEntriesFromGoogleDrive(int count) {
    return 'Gendannet $count indtastninger fra Google Drive';
  }

  @override
  String get fieldManagement => 'Felthåndtering';

  @override
  String get manageFields => 'Administrer Felter';

  @override
  String get addCustomField => 'Tilføj Brugerdefineret Felt';

  @override
  String get deleteField => 'Slet Felt';

  @override
  String get areYouSureYouWantToDeleteThisField =>
      'Er du sikker på, at du vil slette dette felt? Dette vil fjerne det fra alle indtastninger.';

  @override
  String get fieldCreatedSuccessfully => 'Felt oprettet succesfuldt';

  @override
  String errorCreatingField(String error) {
    return 'Fejl ved oprettelse af felt: $error';
  }

  @override
  String get fieldUpdatedSuccessfully => 'Felt opdateret succesfuldt';

  @override
  String errorUpdatingField(String error) {
    return 'Fejl ved opdatering af felt: $error';
  }

  @override
  String get fieldDeletedSuccessfully => 'Felt slettet succesfuldt';

  @override
  String errorDeletingField(String error) {
    return 'Fejl ved sletning af felt: $error';
  }

  @override
  String get configureGoogleDrive => 'Konfigurer Google Drive';

  @override
  String get appInitializationFailed => 'App initialisering mislykkedes';

  @override
  String get noDataToExport => 'Ingen data at eksportere';

  @override
  String exportFailed2(String error) {
    return 'Eksport mislykkedes: $error';
  }

  @override
  String get syncYourData => 'Synkroniser dine data med Google Drive';

  @override
  String get customizeFields => 'Tilpas dine sporingsfelter';

  @override
  String get resetSettings => 'Nulstil Indstillinger';

  @override
  String get resetToDefaults => 'Nulstil til Standard';

  @override
  String get signedIn => 'Logget Ind';

  @override
  String get signedOut => 'Logget Ud';

  @override
  String get syncOptions => 'Synkroniseringsindstillinger';

  @override
  String get autoSync => 'Auto Synkronisering';

  @override
  String get autoSyncDescription =>
      'Synkroniser automatisk når der foretages ændringer';

  @override
  String get uploadNow => 'Upload Nu';

  @override
  String get downloadNow => 'Download Nu';

  @override
  String get availableBackups => 'Tilgængelige Backups';

  @override
  String get noBackupsAvailable => 'Ingen backups tilgængelige';

  @override
  String get restoreBackup => 'Gendan Backup';

  @override
  String get restoreBackupConfirmation =>
      'Dette vil erstatte dine nuværende data med den valgte backup. Fortsæt?';
}
