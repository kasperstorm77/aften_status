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
  slider, // Renamed from rating for clarity
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
  String labelKey; // Kept for backward compatibility, but no longer used for ARB lookup

  @HiveField(2)
  FieldType type;

  @HiveField(3)
  bool isRequired;

  @HiveField(4)
  int orderIndex;

  @HiveField(5)
  Map<String, dynamic> options; // For slider min/max, multiple choice options, etc.

  @HiveField(6)
  bool isSystemField; // Sample fields that came with the app (can be deleted now)

  @HiveField(7)
  Map<String, String> localizedNames; // Language code -> display name (e.g., {'en': 'Sound Sensibility', 'da': 'Lyd Følsomhed'})

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
    this.localizedNames = const {},
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get the display label for a given locale with fallback logic
  /// 1. Try exact locale match (e.g., 'da')
  /// 2. Try any available language
  /// 3. Fallback to labelKey
  String getDisplayLabel(String locale) {
    // First check for exact locale match
    if (localizedNames.containsKey(locale) && localizedNames[locale]!.isNotEmpty) {
      return localizedNames[locale]!;
    }
    
    // Try to find any available localized name
    if (localizedNames.isNotEmpty) {
      // Prefer English as secondary fallback, then any other
      if (localizedNames.containsKey('en') && localizedNames['en']!.isNotEmpty) {
        return localizedNames['en']!;
      }
      // Return first available non-empty name
      for (final name in localizedNames.values) {
        if (name.isNotEmpty) return name;
      }
    }
    
    // Final fallback to labelKey (for backward compatibility)
    return labelKey;
  }

  /// Set localized name for a specific locale
  void setLocalizedName(String locale, String name) {
    final newNames = Map<String, String>.from(localizedNames);
    newNames[locale] = name;
    localizedNames = newNames;
    updatedAt = DateTime.now();
  }

  /// Check if field has at least one localized name
  bool get hasLocalizedName {
    return localizedNames.values.any((name) => name.isNotEmpty);
  }

  /// Get all available locales for this field
  List<String> get availableLocales {
    return localizedNames.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
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
      'localizedNames': localizedNames,
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
        orElse: () => FieldType.slider,
      ),
      isRequired: map['isRequired'] ?? false,
      orderIndex: map['orderIndex'] ?? 0,
      options: Map<String, dynamic>.from(map['options'] ?? {}),
      isSystemField: map['isSystemField'] ?? false,
      localizedNames: Map<String, String>.from(map['localizedNames'] ?? {}),
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
    Map<String, String>? localizedNames,
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
      localizedNames: localizedNames ?? this.localizedNames,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}