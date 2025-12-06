import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../services/home_controller.dart';
import '../models/evening_status.dart';
import '../services/localization_service.dart';
import 'widgets/common_app_bar.dart';
import 'widgets/responsive_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<HomeController>();
    controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.appTitle,
        showSettings: true,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bedtime,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noEntriesYet,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addFirstReflection,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
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
                itemCount: controller.entries.length,
                itemBuilder: (context, index) {
                  final entry = controller.entries[index];
                  return _EntryCard(
                    entry: entry,
                    index: index,
                    onTap: () => controller.editEntry(index),
                    onDelete: () => _showDeleteDialog(context, index),
                    formatDate: (date) => controller.formatDate(date, context),
                    formatTime: controller.formatTime,
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addNewEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              controller.deleteEntry(index);
              Navigator.of(context).pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final EveningStatus entry;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  const _EntryCard({
    required this.entry,
    required this.index,
    required this.onTap,
    required this.onDelete,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate average score from field values
    final fieldValues = entry.fieldValues;
    double averageScore = 5.0;
    if (fieldValues.isNotEmpty) {
      final numericValues = fieldValues.values
          .whereType<num>()
          .map((v) => v.toDouble())
          .toList();
      if (numericValues.isNotEmpty) {
        averageScore = numericValues.reduce((a, b) => a + b) / numericValues.length;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(entry.timestamp),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatTime(entry.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getScoreColor(averageScore, theme).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getScoreColor(averageScore, theme).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.averageScore(averageScore.toStringAsFixed(1)),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: _getScoreColor(averageScore, theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        color: theme.colorScheme.error,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildScorePreview(theme, context),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score, ThemeData theme) {
    if (score <= 3) {
      return Colors.green;
    } else if (score <= 6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildScorePreview(ThemeData theme, BuildContext context) {
    final fieldValues = entry.fieldValues;
    if (fieldValues.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: fieldValues.entries
          .where((e) => e.value is num)
          .take(8) // Show max 8 fields in preview
          .map((e) => _buildScoreChip(
            e.key.length > 10 ? '${e.key.substring(0, 10)}...' : e.key,
            (e.value as num).toDouble(),
            theme,
          ))
          .toList(),
    );
  }

  Widget _buildScoreChip(String label, double score, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${score.toInt()}',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 9,
        ),
      ),
    );
  }
}
