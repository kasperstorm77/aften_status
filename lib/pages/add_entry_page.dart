import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
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
                    child: ResponsiveLayout.isTablet(context)
                        ? GridView.extent(
                            padding: ResponsiveLayout.getHorizontalPadding(context).add(
                              const EdgeInsets.all(16),
                            ),
                            maxCrossAxisExtent: ResponsiveLayout.getSliderCardMaxWidth(context),
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: _buildSliderCards(),
                          )
                        : ListView(
                            padding: ResponsiveLayout.getHorizontalPadding(context).add(
                              const EdgeInsets.all(16),
                            ),
                            children: _buildSliderCards(),
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

  List<Widget> _buildSliderCards() {
    return controller.activeFields.map((field) {
      return DynamicFieldWidget(
        field: field,
        value: controller.getFieldValue(field.id),
        onChanged: (value) => controller.updateFieldValue(field.id, value),
      );
    }).toList();
  }
}
