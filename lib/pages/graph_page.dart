import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/evening_status.dart';
import '../models/field_definition.dart';
import '../services/storage_service.dart';
import '../services/field_definition_service.dart';
import '../services/localization_service.dart';

/// A full-screen graph page showing the last 20 entries as a line chart
/// Always displayed in landscape orientation
class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final StorageService _storageService = Modular.get<StorageService>();
  final FieldDefinitionService _fieldService = Modular.get<FieldDefinitionService>();
  
  List<EveningStatus> _entries = [];
  List<FieldDefinition> _fields = [];
  Map<String, bool> _visibleFields = {};
  bool _isLoading = true;
  
  // Predefined colors for fields
  static const List<Color> _fieldColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF3F51B5), // Indigo
    Color(0xFF009688), // Teal
    Color(0xFFCDDC39), // Lime
    Color(0xFF673AB7), // Deep Purple
    Color(0xFFFF5722), // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadData();
  }

  @override
  void dispose() {
    // Restore orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _storageService.init();
      await _fieldService.initialize();
      
      final entries = await _storageService.getAllEveningStatus();
      final fields = await _fieldService.getActiveFields();
      
      // Sort entries by timestamp (oldest first for chart)
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Take only the last 20 entries
      final last20 = entries.length > 20 
          ? entries.sublist(entries.length - 20) 
          : entries;
      
      // Initialize all fields as visible
      final visibleFields = <String, bool>{};
      for (final field in fields) {
        visibleFields[field.id] = true;
      }
      
      setState(() {
        _entries = last20;
        _fields = fields;
        _visibleFields = visibleFields;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('GraphPage: Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getFieldColor(int index) {
    return _fieldColors[index % _fieldColors.length];
  }

  List<LineChartBarData> _buildLineData() {
    final List<LineChartBarData> lines = [];
    
    for (int fieldIndex = 0; fieldIndex < _fields.length; fieldIndex++) {
      final field = _fields[fieldIndex];
      
      // Skip if field is not visible
      if (_visibleFields[field.id] != true) continue;
      
      final spots = <FlSpot>[];
      
      for (int i = 0; i < _entries.length; i++) {
        final entry = _entries[i];
        final value = entry.getFieldValue(field.id);
        
        if (value != null && value is num) {
          spots.add(FlSpot(i.toDouble(), value.toDouble()));
        }
      }
      
      if (spots.isNotEmpty) {
        lines.add(LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: _getFieldColor(fieldIndex),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: _getFieldColor(fieldIndex),
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }
    
    return lines;
  }

  Widget _buildLegend(String locale) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _fields.length; i++)
            _buildLegendItem(i, locale),
        ],
      ),
    );
  }

  Widget _buildLegendItem(int index, String locale) {
    final field = _fields[index];
    final color = _getFieldColor(index);
    final isVisible = _visibleFields[field.id] ?? true;
    final label = field.getDisplayLabel(locale);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _visibleFields[field.id] = !isVisible;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isVisible ? color : color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
                border: isVisible ? null : Border.all(color: color, width: 1),
              ),
              child: isVisible 
                  ? null 
                  : const Icon(Icons.close, size: 10, color: Colors.white54),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  color: isVisible ? null : Colors.grey,
                  decoration: isVisible ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int index) {
    if (index < 0 || index >= _entries.length) return '';
    final date = _entries[index].timestamp;
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.graph),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Toggle all visibility
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: l10n.showAll,
            onPressed: () {
              setState(() {
                final allVisible = _visibleFields.values.every((v) => v);
                for (final field in _fields) {
                  _visibleFields[field.id] = !allVisible;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    l10n.noEntriesYet,
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : SafeArea(
                  child: Row(
                    children: [
                      // Chart area
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 10,
                              minX: 0,
                              maxX: (_entries.length - 1).toDouble(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: 2,
                                verticalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    strokeWidth: 1,
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: _entries.length > 10 ? 2 : 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= _entries.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _formatDate(index),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 2,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  left: BorderSide(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                  bottom: BorderSide(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((touchedSpot) {
                                      // Use barIndex to identify which field line was touched
                                      final lineIndex = touchedSpot.barIndex;
                                      
                                      // Find the actual field for this line
                                      int visibleFieldIndex = 0;
                                      int actualFieldIndex = -1;
                                      for (int i = 0; i < _fields.length; i++) {
                                        if (_visibleFields[_fields[i].id] == true) {
                                          if (visibleFieldIndex == lineIndex) {
                                            actualFieldIndex = i;
                                            break;
                                          }
                                          visibleFieldIndex++;
                                        }
                                      }
                                      
                                      if (actualFieldIndex == -1) return null;
                                      
                                      final field = _fields[actualFieldIndex];
                                      return LineTooltipItem(
                                        '${field.getDisplayLabel(locale)}: ${touchedSpot.y.toStringAsFixed(1)}',
                                        TextStyle(
                                          color: _getFieldColor(actualFieldIndex),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: _buildLineData(),
                            ),
                          ),
                        ),
                      ),
                      // Legend area
                      Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.legend,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(child: _buildLegend(locale)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
