import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../services/settings_controller.dart';
import '../services/localization_service.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/responsive_layout.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsController controller;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<SettingsController>();
    controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.settings,
        showSettings: false,
        additionalActions: [
          TextButton(
            onPressed: () => _showResetDialog(context),
            child: Text(l10n.reset),
          ),
        ],
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
                    child: ListView(
                      padding: ResponsiveLayout.getHorizontalPadding(context).add(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                      children: _buildSettingsCards(context),
                    ),
                  ),
                ),
              ),
              _buildBottomBar(context),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSettingsCards(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return [
      // Google Drive Sync Card
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.cloud),
          title: Text(l10n.googleDriveSync),
          subtitle: Text(l10n.syncYourData),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Modular.to.pushNamed('/settings/google-drive'),
        ),
      ),
      
      // Field Management Card
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.tune),
          title: Text(l10n.manageFields),
          subtitle: Text(l10n.customizeFields),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Modular.to.pushNamed('/settings/fields'),
        ),
      ),
    ];
  }

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
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
              onPressed: controller.isSaving ? null : () async {
                await controller.saveSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.settingsSaved),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: controller.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveSettings),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetSettings),
        content: Text(l10n.resetSettingsConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              controller.resetToDefaults();
              Navigator.of(context).pop();
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
}
