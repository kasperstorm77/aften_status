import 'package:hive/hive.dart';

part 'field_definition.g.dart';

@HiveType(typeId: 2)
enum FieldType {
  @HiveField(0)
  text,
  @HiveField(1)
  number,
  @HiveField(2)
  boolean,
  @HiveField(3)
  rating,
  @HiveField(4)
  multipleChoice,
  @HiveField(5)
  date,
}

@HiveType(typeId: 1)
class FieldDefinition extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String labelKey; // Key for localization

  @HiveField(2)
  FieldType type;

  @HiveField(3)
  bool isRequired;

  @HiveField(4)
  int orderIndex;

  @HiveField(5)
  Map<String, dynamic> options; // For multiple choice options, min/max values, etc.

  @HiveField(6)
  bool isSystemField; // Core fields that can't be deleted

  @HiveField(7)
  Map<String, String> customLabels; // User custom labels per locale

  @HiveField(8)
  bool isActive; // Can be deactivated instead of deleted

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? updatedAt;

  FieldDefinition({
    required this.id,
    required this.labelKey,
    required this.type,
    this.isRequired = false,
    this.orderIndex = 0,
    this.options = const {},
    this.isSystemField = false,
    this.customLabels = const {},
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Get the display label for current locale
  String getDisplayLabel(String locale) {
    // First check for custom labels
    if (customLabels.containsKey(locale) && customLabels[locale]!.isNotEmpty) {
      return customLabels[locale]!;
    }
    
    // Fallback to localization key (will be handled by localization service)
    return labelKey;
  }

  // Set custom label for locale
  void setCustomLabel(String locale, String label) {
    final newLabels = Map<String, String>.from(customLabels);
    newLabels[locale] = label;
    customLabels = newLabels;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labelKey': labelKey,
      'type': type.name,
      'isRequired': isRequired,
      'orderIndex': orderIndex,
      'options': options,
      'isSystemField': isSystemField,
      'customLabels': customLabels,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FieldDefinition.fromMap(Map<String, dynamic> map) {
    return FieldDefinition(
      id: map['id'] ?? '',
      labelKey: map['labelKey'] ?? '',
      type: FieldType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FieldType.text,
      ),
      isRequired: map['isRequired'] ?? false,
      orderIndex: map['orderIndex'] ?? 0,
      options: Map<String, dynamic>.from(map['options'] ?? {}),
      isSystemField: map['isSystemField'] ?? false,
      customLabels: Map<String, String>.from(map['customLabels'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  FieldDefinition copyWith({
    String? id,
    String? labelKey,
    FieldType? type,
    bool? isRequired,
    int? orderIndex,
    Map<String, dynamic>? options,
    bool? isSystemField,
    Map<String, String>? customLabels,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldDefinition(
      id: id ?? this.id,
      labelKey: labelKey ?? this.labelKey,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      orderIndex: orderIndex ?? this.orderIndex,
      options: options ?? this.options,
      isSystemField: isSystemField ?? this.isSystemField,
      customLabels: customLabels ?? this.customLabels,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}