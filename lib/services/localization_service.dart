// Re-export the l10n generated localizations
export '../l10n/app_localizations.dart';

import '../l10n/app_localizations.dart';
import '../models/field_definition.dart';

/// Helper to get localized field name from a FieldDefinition
/// Uses the field's embedded localizedNames with fallback logic
String getLocalizedFieldNameFromDefinition(FieldDefinition field, String locale) {
  return field.getDisplayLabel(locale);
}

/// Legacy helper for backward compatibility - uses labelKey as fallback
/// @deprecated Use getLocalizedFieldNameFromDefinition instead
String getLocalizedFieldName(AppLocalizations l10n, String labelKey) {
  // This is now just a fallback for any code still using labelKey directly
  // The actual localization should come from FieldDefinition.getDisplayLabel()
  return labelKey;
}
