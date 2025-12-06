import 'package:flutter/material.dart';
import '../../models/field_definition.dart';
import '../../services/localization_service.dart';

/// Dynamic widget that renders the appropriate input based on field type
class DynamicFieldWidget extends StatelessWidget {
  final FieldDefinition field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const DynamicFieldWidget({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  /// Get the localized label for this field
  String _getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // Fallback if localizations aren't available
      return field.labelKey;
    }
    
    // First check for custom labels
    final locale = Localizations.localeOf(context).languageCode;
    final customLabel = field.customLabels[locale];
    if (customLabel != null && customLabel.isNotEmpty) {
      return customLabel;
    }
    
    // Use the localization helper to get the translated label
    return getLocalizedFieldName(l10n, field.labelKey);
  }

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.rating:
        return _buildSliderField(context);
      case FieldType.text:
        return _buildTextField(context);
      case FieldType.number:
        return _buildNumberField(context);
      case FieldType.boolean:
        return _buildToggleField(context);
      default:
        return _buildTextField(context);
    }
  }

  Widget _buildSliderField(BuildContext context) {
    final theme = Theme.of(context);
    final currentValue = (value as num?)?.toDouble() ?? 5.0;
    final label = _getLabel(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(currentValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentValue.toInt().toString(),
                    style: TextStyle(
                      color: _getScoreColor(currentValue),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getScoreColor(currentValue),
                thumbColor: _getScoreColor(currentValue),
              ),
              child: Slider(
                value: currentValue,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (newValue) => onChanged(newValue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final theme = Theme.of(context);
    final label = _getLabel(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: value?.toString() ?? ''),
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(BuildContext context) {
    final theme = Theme.of(context);
    final label = _getLabel(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: value?.toString() ?? ''),
              keyboardType: TextInputType.number,
              onChanged: (text) {
                final parsed = double.tryParse(text);
                if (parsed != null) {
                  onChanged(parsed);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleField(BuildContext context) {
    final theme = Theme.of(context);
    final currentValue = value as bool? ?? false;
    final label = _getLabel(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
            Switch(
              value: currentValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score <= 3) {
      return Colors.green;
    } else if (score <= 6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
