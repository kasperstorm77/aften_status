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

class _EntryCard extends StatefulWidget {
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
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  double? _sliderAverage;
  bool _isLoadingAverage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSliderAverage();
    });
  }

  Future<void> _calculateSliderAverage() async {
    try {
      final fieldService = Modular.get<FieldDefinitionService>();
      final fieldValues = widget.entry.fieldValues;
      
      double sum = 0;
      int count = 0;
      
      for (final entry in fieldValues.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is! num) continue;
        
        // Check if this field is a slider type
        FieldDefinition? fieldDef = await fieldService.getFieldById(key);
        fieldDef ??= await fieldService.getFieldByLabelKey(key);
        
        if (fieldDef != null && fieldDef.type == FieldType.slider) {
          sum += value.toDouble();
          count++;
        }
      }
      
      if (mounted) {
        setState(() {
          _sliderAverage = count > 0 ? sum / count : null;
          _isLoadingAverage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sliderAverage = null;
          _isLoadingAverage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fieldValues = widget.entry.fieldValues;

    return Dismissible(
      key: Key(widget.entry.timestamp.toIso8601String()),
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
        widget.onDelete();
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
          onTap: widget.onTap,
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
                            widget.formatDate(widget.entry.timestamp),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.formatTime(widget.entry.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Average score badge (slider fields only)
                    if (!_isLoadingAverage && _sliderAverage != null)
                      _AverageScoreBadge(
                        score: _sliderAverage!,
                        label: l10n.averageScore(_sliderAverage!.toStringAsFixed(1)),
                      ),
                  ],
                ),
                
                // Field values grouped by type
                if (fieldValues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _GroupedFieldsDisplay(
                    fieldValues: fieldValues,
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

/// Widget that displays field values grouped by type
class _GroupedFieldsDisplay extends StatefulWidget {
  final Map<String, dynamic> fieldValues;

  const _GroupedFieldsDisplay({
    required this.fieldValues,
  });

  @override
  State<_GroupedFieldsDisplay> createState() => _GroupedFieldsDisplayState();
}

class _GroupedFieldsDisplayState extends State<_GroupedFieldsDisplay> {
  Map<FieldType, List<_FieldDisplayData>>? _groupedFields;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldDefinitions();
    });
  }

  @override
  void didUpdateWidget(covariant _GroupedFieldsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fieldValues != oldWidget.fieldValues) {
      _loadFieldDefinitions();
    }
  }

  Future<void> _loadFieldDefinitions() async {
    if (!mounted) return;
    
    try {
      final fieldService = Modular.get<FieldDefinitionService>();
      final locale = Localizations.localeOf(context).languageCode;
      
      final Map<FieldType, List<_FieldDisplayData>> grouped = {};
      
      for (final entry in widget.fieldValues.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // Try to find field by ID or labelKey
        FieldDefinition? fieldDef = await fieldService.getFieldById(key);
        fieldDef ??= await fieldService.getFieldByLabelKey(key);
        
        if (fieldDef != null && fieldDef.isActive) {
          final type = fieldDef.type;
          grouped.putIfAbsent(type, () => []);
          grouped[type]!.add(_FieldDisplayData(
            label: fieldDef.getDisplayLabel(locale),
            value: value,
            orderIndex: fieldDef.orderIndex,
          ));
        }
      }
      
      // Sort each group by order index
      for (final list in grouped.values) {
        list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }
      
      if (mounted) {
        setState(() {
          _groupedFields = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _groupedFields = {};
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
      return const SizedBox(height: 40);
    }
    
    if (_groupedFields == null || _groupedFields!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final sliders = _groupedFields![FieldType.slider] ?? [];
    final numbers = _groupedFields![FieldType.number] ?? [];
    final booleans = _groupedFields![FieldType.boolean] ?? [];
    final texts = _groupedFields![FieldType.text] ?? [];
    
    // Count total fields for expand/collapse
    final totalFields = sliders.length + numbers.length + booleans.length + texts.length;
    final hasMany = totalFields > 3;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sliders - show as bar charts (most important, always show first 2)
        if (sliders.isNotEmpty)
          _SliderFieldsSection(
            fields: sliders,
            isExpanded: _isExpanded,
            collapsedCount: 2,
          ),
        
        // Numbers - show as compact chips
        if (numbers.isNotEmpty) ...[
          if (sliders.isNotEmpty) const SizedBox(height: 8),
          _NumberFieldsSection(
            fields: numbers,
            isExpanded: _isExpanded,
          ),
        ],
        
        // Booleans - show as icon row
        if (booleans.isNotEmpty) ...[
          if (sliders.isNotEmpty || numbers.isNotEmpty) const SizedBox(height: 8),
          _BooleanFieldsSection(
            fields: booleans,
            isExpanded: _isExpanded,
          ),
        ],
        
        // Text fields - show as snippets (only when expanded)
        if (texts.isNotEmpty && _isExpanded) ...[
          const SizedBox(height: 8),
          _TextFieldsSection(fields: texts),
        ],
        
        // Expand/collapse toggle
        if (hasMany || texts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
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
                    _isExpanded ? l10n.showLess : l10n.showMore(totalFields),
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

/// Data class for field display
class _FieldDisplayData {
  final String label;
  final dynamic value;
  final int orderIndex;

  _FieldDisplayData({
    required this.label,
    required this.value,
    required this.orderIndex,
  });
}

/// Section for slider fields - displayed as bar charts
class _SliderFieldsSection extends StatelessWidget {
  final List<_FieldDisplayData> fields;
  final bool isExpanded;
  final int collapsedCount;

  const _SliderFieldsSection({
    required this.fields,
    required this.isExpanded,
    this.collapsedCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final displayFields = isExpanded ? fields : fields.take(collapsedCount).toList();
    
    return Column(
      children: [
        for (int i = 0; i < displayFields.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < displayFields.length - 1 ? 6 : 0),
            child: _ScoreBarItem(
              label: displayFields[i].label,
              score: (displayFields[i].value as num).toDouble(),
              maxScore: 10,
            ),
          ),
      ],
    );
  }
}

/// Section for number fields - displayed as compact chips
class _NumberFieldsSection extends StatelessWidget {
  final List<_FieldDisplayData> fields;
  final bool isExpanded;

  const _NumberFieldsSection({
    required this.fields,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayFields = isExpanded ? fields : fields.take(3).toList();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: displayFields.map((field) {
        final value = field.value;
        final displayValue = value is double && value == value.toInt()
            ? value.toInt().toString()
            : value.toString();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                field.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                displayValue,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Section for boolean fields - displayed as icons
class _BooleanFieldsSection extends StatelessWidget {
  final List<_FieldDisplayData> fields;
  final bool isExpanded;

  const _BooleanFieldsSection({
    required this.fields,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayFields = isExpanded ? fields : fields.take(4).toList();
    
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: displayFields.map((field) {
        final isTrue = field.value == true;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTrue ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: isTrue ? Colors.green : Colors.red.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              field.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Section for text fields - displayed as snippets
class _TextFieldsSection extends StatelessWidget {
  final List<_FieldDisplayData> fields;

  const _TextFieldsSection({required this.fields});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.map((field) {
        final text = field.value?.toString() ?? '';
        if (text.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notes,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      text.length > 50 ? '${text.substring(0, 50)}...' : text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
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
