import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../models/field_definition.dart';
import '../services/add_entry_controller.dart';
import '../services/localization_service.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/responsive_layout.dart';
import 'widgets/dynamic_field_widget.dart';

class AddEntryPage extends StatefulWidget {
  final String? entryId;
  
  const AddEntryPage({super.key, this.entryId});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  late AddEntryController controller;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<AddEntryController>();
    controller.init(entryId: widget.entryId);
  }
  
  /// Returns the appropriate onChange handler based on field type.
  /// Text and number fields don't notify to prevent rebuild during typing.
  /// Sliders, toggles, etc. need immediate UI feedback.
  void Function(dynamic) _getOnChanged(FieldDefinition field) {
    switch (field.type) {
      case FieldType.text:
      case FieldType.number:
        return (value) => controller.updateFieldValue(field.id, value);
      case FieldType.slider:
      case FieldType.boolean:
      case FieldType.multipleChoice:
      case FieldType.date:
        return (value) => controller.updateFieldValueWithNotify(field.id, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleText = controller.isEditing
      ? (l10n?.editEntry ?? 'Edit Entry')
      : (l10n?.newEveningStatus ?? 'New Evening Status');
    
    return Scaffold(
      appBar: CommonAppBar(
        title: titleText,
        showSettings: false,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveLayout.getMaxWidth(context),
                    ),
                    child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: (controller.activeFields.length / 2).ceil(),
                            itemBuilder: (context, rowIndex) {
                              final firstIndex = rowIndex * 2;
                              final secondIndex = firstIndex + 1;
                              final hasSecond = secondIndex < controller.activeFields.length;
                              final firstField = controller.activeFields[firstIndex];
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: DynamicFieldWidget(
                                        field: firstField,
                                        value: controller.getFieldValue(firstField.id),
                                        onChanged: _getOnChanged(firstField),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: hasSecond
                                          ? DynamicFieldWidget(
                                              field: controller.activeFields[secondIndex],
                                              value: controller.getFieldValue(controller.activeFields[secondIndex].id),
                                              onChanged: _getOnChanged(controller.activeFields[secondIndex]),
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.getMaxWidth(context),
                  ),
                  child: Padding(
                    padding: ResponsiveLayout.getHorizontalPadding(context).add(
                      const EdgeInsets.all(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isSaving ? null : controller.saveCurrentStatus,
                        child: controller.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(controller.isEditing
                                ? (l10n?.update ?? 'Update')
                                : (l10n?.save ?? 'Save')),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
