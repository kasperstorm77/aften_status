// Re-export the l10n generated localizations
export '../l10n/app_localizations.dart';

import '../l10n/app_localizations.dart';

/// Helper to get localized field name from labelKey
/// Since ARB getters are static, we need a manual mapping
String getLocalizedFieldName(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    // Default system fields
    case 'soundSensibility':
      return l10n.soundSensibility;
    case 'sleepQuality':
      return l10n.sleepQuality;
    case 'irritability':
      return l10n.irritability;
    case 'socialWithdrawal':
      return l10n.socialWithdrawal;
    case 'emotionalWithdrawal':
      return l10n.emotionalWithdrawal;
    case 'skinPicking':
      return l10n.skinPicking;
    case 'tiredness':
      return l10n.tiredness;
    case 'forgetfulnessOnConversations':
      return l10n.forgetfulnessOnConversations;
    case 'lackOfFocus':
      return l10n.lackOfFocus;
    case 'lowToleranceTowardPeople':
      return l10n.lowToleranceTowardPeople;
    case 'easyToTears':
      return l10n.easyToTears;
    case 'interrupting':
      return l10n.interrupting;
    case 'misunderstanding':
      return l10n.misunderstanding;
    case 'selfBlaming':
      return l10n.selfBlaming;
    default:
      // For custom fields, return the labelKey as-is (user-defined)
      return labelKey;
  }
}
