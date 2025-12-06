import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models/field_definition.dart';
import '../services/field_definition_service.dart';
import '../services/localization_service.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/responsive_layout.dart';

class FieldManagementPage extends StatefulWidget {
  const FieldManagementPage({super.key});

  @override
  State<FieldManagementPage> createState() => _FieldManagementPageState();
}

class _FieldManagementPageState extends State<FieldManagementPage> {
  late FieldDefinitionService _fieldService;
  List<FieldDefinition> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fieldService = Modular.get<FieldDefinitionService>();
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() => _isLoading = true);
    try {
      await _fieldService.initialize();
      _fields = await _fieldService.getAllFields();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.manageFields,
        showSettings: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFieldList(context),
    );
  }

  Widget _buildFieldList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_fields.isEmpty) {
      return const Center(
        child: Text('No fields defined'),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.getMaxWidth(context),
        ),
        child: ListView.builder(
          padding: ResponsiveLayout.getHorizontalPadding(context).add(
            const EdgeInsets.symmetric(vertical: 16),
          ),
          itemCount: _fields.length,
          itemBuilder: (context, index) {
            final field = _fields[index];
            return _buildFieldTile(context, field, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildFieldTile(BuildContext context, FieldDefinition field, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final label = getLocalizedFieldName(l10n, field.labelKey);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getFieldTypeIcon(field.type),
          color: field.isActive 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: field.isActive 
                ? null 
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        subtitle: Text(
          field.isSystemField ? 'System field' : 'Custom field',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Switch(
          value: field.isActive,
          onChanged: field.isSystemField 
              ? null // System fields cannot be disabled
              : (value) => _toggleField(field, value),
        ),
      ),
    );
  }

  IconData _getFieldTypeIcon(FieldType type) {
    switch (type) {
      case FieldType.rating:
        return Icons.star;
      case FieldType.text:
        return Icons.text_fields;
      case FieldType.number:
        return Icons.numbers;
      case FieldType.boolean:
        return Icons.toggle_on;
      case FieldType.multipleChoice:
        return Icons.list;
      case FieldType.date:
        return Icons.calendar_today;
    }
  }

  Future<void> _toggleField(FieldDefinition field, bool isActive) async {
    if (isActive) {
      await _fieldService.activateField(field.id);
    } else {
      await _fieldService.deactivateField(field.id);
    }
    await _loadFields();
  }
}
