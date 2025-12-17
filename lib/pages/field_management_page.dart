import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:uuid/uuid.dart';
import '../models/field_definition.dart';
import '../services/field_definition_service.dart';
import '../l10n/app_localizations.dart';
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
        additionalActions: [
          // Restore default fields button
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: l10n.restoreDefaultFields,
            onPressed: _restoreDefaultFields,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFieldDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCustomField),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFieldList(context),
    );
  }

  Future<void> _restoreDefaultFields() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() => _isLoading = true);
    try {
      final restoredCount = await _fieldService.restoreDefaultFields();
      await _loadFields();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restoredCount > 0 
                ? l10n.restoredDefaultFields(restoredCount)
                : l10n.allDefaultFieldsExist),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFieldList(BuildContext context) {
    if (_fields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No fields defined', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to add your first field', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.getMaxWidth(context),
        ),
        child: ReorderableListView.builder(
          // Extra bottom padding to prevent FAB from overlapping last items
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
          itemCount: _fields.length,
          onReorder: _reorderFields,
          itemBuilder: (context, index) {
            final field = _fields[index];
            return _buildFieldTile(context, field, index);
          },
        ),
      ),
    );
  }

  Widget _buildFieldTile(BuildContext context, FieldDefinition field, int index) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final label = field.getDisplayLabel(locale);
    
    return Card(
      key: ValueKey(field.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.drag_handle,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            // Field type icon
            Icon(
              _getFieldTypeIcon(field.type),
              size: 20,
              color: field.isActive 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),
            // Field name - takes remaining space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: field.isActive 
                          ? null 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_hasOtherTranslations(field, locale))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _getOtherTranslationsText(field, locale),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Actions row
            Switch(
              value: field.isActive,
              onChanged: (value) => _toggleField(field, value),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showFieldDialog(context, field: field),
              tooltip: l10n.edit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
              onPressed: () => _confirmDeleteField(context, field, l10n),
              tooltip: l10n.delete,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  bool _hasOtherTranslations(FieldDefinition field, String locale) {
    final availableLocales = field.availableLocales;
    return availableLocales.length > 1 && 
           availableLocales.any((l) => l != locale);
  }

  String _getOtherTranslationsText(FieldDefinition field, String locale) {
    final otherLocales = field.availableLocales.where((l) => l != locale).toList();
    return otherLocales
        .map((l) => '${l.toUpperCase()}: ${field.localizedNames[l]}')
        .join(', ');
  }

  IconData _getFieldTypeIcon(FieldType type) {
    switch (type) {
      case FieldType.slider:
        return Icons.linear_scale;
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

  Future<void> _reorderFields(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final field = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, field);
    });
    
    // Update order indices
    for (int i = 0; i < _fields.length; i++) {
      await _fieldService.updateFieldOrder(_fields[i].id, i);
    }
  }

  Future<void> _showFieldDialog(BuildContext context, {FieldDefinition? field}) async {
    final result = await showDialog<FieldDefinition>(
      context: context,
      builder: (context) => FieldEditDialog(
        field: field,
        existingFields: _fields,
      ),
    );
    
    if (result != null) {
      if (field == null) {
        // Creating new field
        await _fieldService.saveField(result);
      } else {
        // Updating existing field
        await _fieldService.updateField(field.id, result);
      }
      await _loadFields();
    }
  }

  Future<void> _confirmDeleteField(BuildContext context, FieldDefinition field, AppLocalizations l10n) async {
    final locale = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteField),
        content: Text('${l10n.areYouSureYouWantToDeleteThisField}\n\n"${field.getDisplayLabel(locale)}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _fieldService.deleteField(field.id);
      await _loadFields();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fieldDeletedSuccessfully)),
        );
      }
    }
  }
}

/// Dialog for creating or editing a field
class FieldEditDialog extends StatefulWidget {
  final FieldDefinition? field;
  final List<FieldDefinition> existingFields;

  const FieldEditDialog({
    super.key,
    this.field,
    required this.existingFields,
  });

  @override
  State<FieldEditDialog> createState() => _FieldEditDialogState();
}

class _FieldEditDialogState extends State<FieldEditDialog> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();
  
  late TextEditingController _nameEnController;
  late TextEditingController _nameDaController;
  late FieldType _selectedType;
  late bool _isRequired;
  
  bool get isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.field?.localizedNames['en'] ?? '');
    _nameDaController = TextEditingController(text: widget.field?.localizedNames['da'] ?? '');
    _selectedType = widget.field?.type ?? FieldType.slider;
    _isRequired = widget.field?.isRequired ?? false;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameDaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(isEditing ? l10n.edit : l10n.addCustomField),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // English name (required)
                TextFormField(
                  controller: _nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'Name (English) *',
                    hintText: 'Enter field name in English',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'English name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Danish name (optional)
                TextFormField(
                  controller: _nameDaController,
                  decoration: const InputDecoration(
                    labelText: 'Name (Danish)',
                    hintText: 'Enter field name in Danish (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Field type dropdown
                DropdownButtonFormField<FieldType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Field Type',
                    border: OutlineInputBorder(),
                  ),
                  items: FieldType.values
                      .where((type) => type != FieldType.multipleChoice && type != FieldType.date)
                      .map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getFieldTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(_getFieldTypeName(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Required toggle
                SwitchListTile(
                  title: Text(l10n.requiredField),
                  subtitle: Text(l10n.usersMustFillThisField),
                  value: _isRequired,
                  onChanged: (value) => setState(() => _isRequired = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saveField,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  IconData _getFieldTypeIcon(FieldType type) {
    switch (type) {
      case FieldType.slider:
        return Icons.linear_scale;
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

  String _getFieldTypeName(FieldType type) {
    switch (type) {
      case FieldType.slider:
        return 'Slider (1-10)';
      case FieldType.text:
        return 'Text';
      case FieldType.number:
        return 'Number';
      case FieldType.boolean:
        return 'Yes/No Toggle';
      case FieldType.multipleChoice:
        return 'Multiple Choice';
      case FieldType.date:
        return 'Date';
    }
  }

  void _saveField() {
    if (!_formKey.currentState!.validate()) return;
    
    final localizedNames = <String, String>{};
    
    final enName = _nameEnController.text.trim();
    if (enName.isNotEmpty) {
      localizedNames['en'] = enName;
    }
    
    final daName = _nameDaController.text.trim();
    if (daName.isNotEmpty) {
      localizedNames['da'] = daName;
    }
    
    // Generate UUID for new fields
    final fieldId = isEditing ? widget.field!.id : _uuid.v4();
    
    final field = FieldDefinition(
      id: fieldId,
      labelKey: fieldId, // labelKey same as id for custom fields
      type: _selectedType,
      isRequired: _isRequired,
      orderIndex: isEditing ? widget.field!.orderIndex : widget.existingFields.length,
      isSystemField: false, // User-created fields are never system fields
      localizedNames: localizedNames,
      isActive: isEditing ? widget.field!.isActive : true,
      createdAt: isEditing ? widget.field!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    Navigator.of(context).pop(field);
  }
}
