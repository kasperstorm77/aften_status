import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/field_definition.dart';

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

  /// Get the localized label for this field using embedded localizedNames
  String _getLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return field.getDisplayLabel(locale);
  }

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.slider:
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getScoreColor(currentValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentValue.toInt().toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getScoreColor(currentValue),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _TextInputField(
              initialValue: value?.toString() ?? '',
              onChanged: onChanged,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _NumberInputField(
              initialValue: value,
              onChanged: onChanged,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Switch(
                value: currentValue,
                onChanged: onChanged,
              ),
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

/// Stateful number input field that maintains its own TextEditingController
/// to avoid the digit reversal bug when rebuilding
class _NumberInputField extends StatefulWidget {
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;

  const _NumberInputField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialText = widget.initialValue != null 
        ? _formatNumber(widget.initialValue)
        : '';
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '';
    if (value is double) {
      // Show as integer if it's a whole number
      return value == value.toInt() ? value.toInt().toString() : value.toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: (text) {
        if (text.isEmpty) {
          widget.onChanged(null);
        } else {
          final parsed = double.tryParse(text);
          if (parsed != null) {
            widget.onChanged(parsed);
          }
        }
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(10),
        isDense: true,
      ),
    );
  }
}

/// Stateful text input field that maintains its own TextEditingController
/// to avoid text input issues when rebuilding
class _TextInputField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<dynamic> onChanged;

  const _TextInputField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<_TextInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(10),
        isDense: true,
      ),
    );
  }
}