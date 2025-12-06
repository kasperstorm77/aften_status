class FieldSettings {
  final String label;
  final String unit;
  final bool isEnabled;
  final bool isCustomLabel; // Tracks if user has customized the label

  FieldSettings({
    required this.label,
    this.unit = '',
    this.isEnabled = true,
    this.isCustomLabel = false,
  });

  FieldSettings copyWith({
    String? label,
    String? unit,
    bool? isEnabled,
    bool? isCustomLabel,
  }) {
    return FieldSettings(
      label: label ?? this.label,
      unit: unit ?? this.unit,
      isEnabled: isEnabled ?? this.isEnabled,
      isCustomLabel: isCustomLabel ?? this.isCustomLabel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'unit': unit,
      'isEnabled': isEnabled,
      'isCustomLabel': isCustomLabel,
    };
  }

  factory FieldSettings.fromMap(Map<String, dynamic> map) {
    return FieldSettings(
      label: map['label'] ?? '',
      unit: map['unit'] ?? '',
      isEnabled: map['isEnabled'] ?? true,
      isCustomLabel: map['isCustomLabel'] ?? false,
    );
  }
}

class AppSettings {
  static const Map<String, String> defaultLabels = {
    'soundSensibility': 'Sound Sensibility',
    'sleepQuality': 'Sleep Quality',
    'irritability': 'Irritability',
    'socialWithdrawal': 'Social Withdrawal',
    'emotionalWithdrawal': 'Emotional Withdrawal',
    'skinPicking': 'Skin Picking',
    'tiredness': 'Tiredness',
    'forgetfulnessOnConversations': 'Forgetfulness on Conversations',
    'lackOfFocus': 'Lack of Focus',
    'lowToleranceTowardPeople': 'Low Tolerance Toward People',
    'easyToTears': 'Easy to Tears',
    'interrupting': 'Interrupting',
    'misunderstanding': 'Misunderstanding',
    'selfBlaming': 'Self Blaming',
  };

  final Map<String, FieldSettings> fieldSettings;

  AppSettings({Map<String, FieldSettings>? fieldSettings})
      : fieldSettings = fieldSettings ?? _createDefaultSettings();

  static Map<String, FieldSettings> _createDefaultSettings() {
    final Map<String, FieldSettings> settings = {};
    for (final entry in defaultLabels.entries) {
      settings[entry.key] = FieldSettings(
        label: entry.value,
        isCustomLabel: false, // Default labels are not custom
      );
    }
    return settings;
  }
  
  /// Gets the display label for a field, using localized name if not customized
  String getFieldLabel(String fieldKey, Map<String, String> localizedNames) {
    final fieldSettings = this.fieldSettings[fieldKey];
    if (fieldSettings == null) {
      return localizedNames[fieldKey] ?? fieldKey;
    }
    
    // If user has customized the label, use it
    if (fieldSettings.isCustomLabel && fieldSettings.label.isNotEmpty) {
      return fieldSettings.label;
    }
    
    // Otherwise use localized name
    return localizedNames[fieldKey] ?? fieldSettings.label;
  }

  AppSettings copyWith({Map<String, FieldSettings>? fieldSettings}) {
    return AppSettings(
      fieldSettings: fieldSettings ?? this.fieldSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldSettings': fieldSettings.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final fieldSettingsMap = map['fieldSettings'] as Map<String, dynamic>? ?? {};
    final settings = <String, FieldSettings>{};
    
    for (final entry in defaultLabels.entries) {
      final key = entry.key;
      if (fieldSettingsMap.containsKey(key)) {
        settings[key] = FieldSettings.fromMap(fieldSettingsMap[key]);
      } else {
        settings[key] = FieldSettings(label: entry.value);
      }
    }
    
    return AppSettings(fieldSettings: settings);
  }
}