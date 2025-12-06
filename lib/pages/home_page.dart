import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../services/home_controller.dart';
import '../services/field_definition_service.dart';
import '../models/evening_status.dart';
import '../models/field_definition.dart';
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
        showGraph: true,
        onSettingsReturn: () {
          // Reload entries when returning from settings (in case data was deleted)
          controller.loadEntries();
        },
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
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    
    // Calculate average score from field values
    final fieldValues = entry.fieldValues;
    final numericEntries = fieldValues.entries
        .where((e) => e.value is num)
        .toList();
    
    double? averageScore;
    if (numericEntries.isNotEmpty) {
      final sum = numericEntries
          .map((e) => (e.value as num).toDouble())
          .reduce((a, b) => a + b);
      averageScore = sum / numericEntries.length;
    }

    return Dismissible(
      key: Key(entry.timestamp.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false; // Let the dialog handle the actual deletion
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with date/time and average score
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDate(entry.timestamp),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTime(entry.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Average score badge
                    if (averageScore != null)
                      _AverageScoreBadge(
                        score: averageScore,
                        label: l10n.averageScore(averageScore.toStringAsFixed(1)),
                      ),
                  ],
                ),
                
                // Score visualization
                if (numericEntries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ScoreBarChart(
                    entries: numericEntries,
                    locale: locale,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A colored badge showing the average score
class _AverageScoreBadge extends StatelessWidget {
  final double score;
  final String label;

  const _AverageScoreBadge({
    required this.score,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getScoreIcon(score),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score <= 3) return Colors.green;
    if (score <= 5) return Colors.teal;
    if (score <= 7) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score <= 3) return Icons.sentiment_very_satisfied;
    if (score <= 5) return Icons.sentiment_satisfied;
    if (score <= 7) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }
}

/// A horizontal bar chart showing individual field scores
class _ScoreBarChart extends StatefulWidget {
  final List<MapEntry<String, dynamic>> entries;
  final String locale;

  const _ScoreBarChart({
    required this.entries,
    required this.locale,
  });

  @override
  State<_ScoreBarChart> createState() => _ScoreBarChartState();
}

class _ScoreBarChartState extends State<_ScoreBarChart> {
  List<_FieldScoreData>? _fieldScores;
  bool _isLoading = true;
  bool _isExpanded = false;
  static const int _collapsedCount = 2;

  @override
  void initState() {
    super.initState();
    _loadFieldDefinitions();
  }

  @override
  void didUpdateWidget(covariant _ScoreBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the entries or locale changed
    if (widget.locale != oldWidget.locale ||
        widget.entries.length != oldWidget.entries.length ||
        !_entriesEqual(widget.entries, oldWidget.entries)) {
      _loadFieldDefinitions();
    }
  }

  bool _entriesEqual(List<MapEntry<String, dynamic>> a, List<MapEntry<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].key != b[i].key || a[i].value != b[i].value) return false;
    }
    return true;
  }

  Future<void> _loadFieldDefinitions() async {
    try {
      final fieldService = Modular.get<FieldDefinitionService>();
      
      final List<_FieldScoreData> scores = [];
      
      debugPrint('_ScoreBarChart: Processing ${widget.entries.length} entry values');
      
      for (final entry in widget.entries) {
        final key = entry.key;
        
        // Try to find field - could be stored by ID (UUID) or labelKey
        FieldDefinition? fieldDef;
        
        // First try by ID (newer entries use UUID as key)
        fieldDef = await fieldService.getFieldById(key);
        
        // If not found, try by labelKey (older entries use labelKey as key)
        if (fieldDef == null) {
          fieldDef = await fieldService.getFieldByLabelKey(key);
        }
        
        // Only include fields that still exist and are active
        if (fieldDef != null && fieldDef.isActive) {
          scores.add(_FieldScoreData(
            label: fieldDef.getDisplayLabel(widget.locale),
            score: (entry.value as num).toDouble(),
            orderIndex: fieldDef.orderIndex,
          ));
        } else {
          debugPrint('_ScoreBarChart: Field not found or inactive for key: $key (fieldDef=${fieldDef != null}, active=${fieldDef?.isActive})');
        }
      }
      
      // Sort by order index (as defined in field management)
      scores.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      
      debugPrint('_ScoreBarChart: Loaded ${scores.length} field scores');
      
      if (mounted) {
        setState(() {
          _fieldScores = scores;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_ScoreBarChart: Error loading field definitions: $e');
      if (mounted) {
        setState(() {
          _fieldScores = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const SizedBox(height: 40); // Placeholder height while loading
    }
    
    if (_fieldScores == null || _fieldScores!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final hasMoreFields = _fieldScores!.length > _collapsedCount;
    final displayScores = _isExpanded 
        ? _fieldScores! 
        : _fieldScores!.take(_collapsedCount).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < displayScores.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < displayScores.length - 1 ? 6 : 0),
            child: _ScoreBarItem(
              label: displayScores[i].label,
              score: displayScores[i].score,
              maxScore: 10,
            ),
          ),
        
        // Show expand/collapse toggle if there are more fields
        if (hasMoreFields)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isExpanded 
                        ? l10n.showLess
                        : l10n.showMore(_fieldScores!.length - _collapsedCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Data class for field score display
class _FieldScoreData {
  final String label;
  final double score;
  final int orderIndex;

  _FieldScoreData({
    required this.label,
    required this.score,
    required this.orderIndex,
  });
}

/// Individual score bar with label and visual indicator
class _ScoreBarItem extends StatelessWidget {
  final String label;
  final double score;
  final double maxScore;

  const _ScoreBarItem({
    required this.label,
    required this.score,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = score / maxScore;
    final color = _getScoreColor(score);
    
    return Row(
      children: [
        // Label
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Bar
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Score value
        SizedBox(
          width: 24,
          child: Text(
            score.toInt().toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score <= 3) return Colors.green;
    if (score <= 5) return Colors.teal;
    if (score <= 7) return Colors.orange;
    return Colors.red;
  }
}
