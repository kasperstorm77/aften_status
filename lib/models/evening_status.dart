import 'package:hive/hive.dart';

part 'evening_status.g.dart';

@HiveType(typeId: 0)
class EveningStatus extends HiveObject {
  @HiveField(14)
  DateTime timestamp;

  @HiveField(15)
  bool isSynced;

  @HiveField(16)
  DateTime? lastSyncedAt;

  @HiveField(17)
  Map<String, dynamic> fieldValues; // New flexible field values

  @HiveField(18)
  int schemaVersion; // Track schema changes

  // Legacy fields - preserved for backward compatibility
  @HiveField(0)
  double? soundSensibility;

  @HiveField(1)
  double? sleepQuality;

  @HiveField(2)
  double? irritability;

  @HiveField(3)
  double? socialWithdrawal;

  @HiveField(4)
  double? emotionalWithdrawal;

  @HiveField(5)
  double? skinPicking;

  @HiveField(6)
  double? tiredness;

  @HiveField(7)
  double? forgetfulnessOnConversations;

  @HiveField(8)
  double? lackOfFocus;

  @HiveField(9)
  double? lowToleranceTowardPeople;

  @HiveField(10)
  double? easyToTears;

  @HiveField(11)
  double? interrupting;

  @HiveField(12)
  double? misunderstanding;

  @HiveField(13)
  double? selfBlaming;

  EveningStatus({
    DateTime? timestamp,
    this.isSynced = false,
    this.lastSyncedAt,
    Map<String, dynamic>? fieldValues,
    this.schemaVersion = 1,
    // Legacy fields for migration
    this.soundSensibility,
    this.sleepQuality,
    this.irritability,
    this.socialWithdrawal,
    this.emotionalWithdrawal,
    this.skinPicking,
    this.tiredness,
    this.forgetfulnessOnConversations,
    this.lackOfFocus,
    this.lowToleranceTowardPeople,
    this.easyToTears,
    this.interrupting,
    this.misunderstanding,
    this.selfBlaming,
  }) : timestamp = timestamp ?? DateTime.now(),
       fieldValues = fieldValues ?? {} {
    // Auto-migrate legacy data if needed
    if (schemaVersion == 0 || (fieldValues?.isEmpty == true && _hasLegacyData())) {
      _migrateLegacyData();
    }
  }

  // Helper to check if legacy data exists
  bool _hasLegacyData() {
    return soundSensibility != null ||
           sleepQuality != null ||
           irritability != null ||
           socialWithdrawal != null ||
           emotionalWithdrawal != null ||
           skinPicking != null ||
           tiredness != null ||
           forgetfulnessOnConversations != null ||
           lackOfFocus != null ||
           lowToleranceTowardPeople != null ||
           easyToTears != null ||
           interrupting != null ||
           misunderstanding != null ||
           selfBlaming != null;
  }

  // Migrate legacy data to new flexible format
  void _migrateLegacyData() {
    if (soundSensibility != null) fieldValues['soundSensibility'] = soundSensibility;
    if (sleepQuality != null) fieldValues['sleepQuality'] = sleepQuality;
    if (irritability != null) fieldValues['irritability'] = irritability;
    if (socialWithdrawal != null) fieldValues['socialWithdrawal'] = socialWithdrawal;
    if (emotionalWithdrawal != null) fieldValues['emotionalWithdrawal'] = emotionalWithdrawal;
    if (skinPicking != null) fieldValues['skinPicking'] = skinPicking;
    if (tiredness != null) fieldValues['tiredness'] = tiredness;
    if (forgetfulnessOnConversations != null) fieldValues['forgetfulnessOnConversations'] = forgetfulnessOnConversations;
    if (lackOfFocus != null) fieldValues['lackOfFocus'] = lackOfFocus;
    if (lowToleranceTowardPeople != null) fieldValues['lowToleranceTowardPeople'] = lowToleranceTowardPeople;
    if (easyToTears != null) fieldValues['easyToTears'] = easyToTears;
    if (interrupting != null) fieldValues['interrupting'] = interrupting;
    if (misunderstanding != null) fieldValues['misunderstanding'] = misunderstanding;
    if (selfBlaming != null) fieldValues['selfBlaming'] = selfBlaming;
    
    schemaVersion = 1;
  }

  // Get field value with type safety
  T? getFieldValue<T>(String fieldId) {
    final value = fieldValues[fieldId];
    if (value is T) return value;
    return null;
  }

  // Set field value
  void setFieldValue(String fieldId, dynamic value) {
    fieldValues[fieldId] = value;
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'fieldValues': fieldValues,
      'schemaVersion': schemaVersion,
    };
  }

  static EveningStatus fromMap(Map<String, dynamic> map) {
    // Check if this is legacy data format
    final hasLegacyFields = map.containsKey('soundSensibility') || 
                           map.containsKey('sleepQuality') ||
                           map.containsKey('irritability');
    
    if (hasLegacyFields && !map.containsKey('fieldValues')) {
      // Legacy format - migrate on load
      return EveningStatus(
        timestamp: DateTime.parse(map['timestamp']),
        isSynced: map['isSynced'] ?? false,
        lastSyncedAt: map['lastSyncedAt'] != null ? DateTime.parse(map['lastSyncedAt']) : null,
        schemaVersion: 0, // Mark for migration
        // Legacy fields
        soundSensibility: map['soundSensibility']?.toDouble(),
        sleepQuality: map['sleepQuality']?.toDouble(),
        irritability: map['irritability']?.toDouble(),
        socialWithdrawal: map['socialWithdrawal']?.toDouble(),
        emotionalWithdrawal: map['emotionalWithdrawal']?.toDouble(),
        skinPicking: map['skinPicking']?.toDouble(),
        tiredness: map['tiredness']?.toDouble(),
        forgetfulnessOnConversations: map['forgetfulnessOnConversations']?.toDouble(),
        lackOfFocus: map['lackOfFocus']?.toDouble(),
        lowToleranceTowardPeople: map['lowToleranceTowardPeople']?.toDouble(),
        easyToTears: map['easyToTears']?.toDouble(),
        interrupting: map['interrupting']?.toDouble(),
        misunderstanding: map['misunderstanding']?.toDouble(),
        selfBlaming: map['selfBlaming']?.toDouble(),
      );
    }
    
    // New flexible format
    return EveningStatus(
      timestamp: DateTime.parse(map['timestamp']),
      isSynced: map['isSynced'] ?? false,
      lastSyncedAt: map['lastSyncedAt'] != null ? DateTime.parse(map['lastSyncedAt']) : null,
      fieldValues: Map<String, dynamic>.from(map['fieldValues'] ?? {}),
      schemaVersion: map['schemaVersion'] ?? 1,
    );
  }

  EveningStatus copyWith({
    DateTime? timestamp,
    bool? isSynced,
    DateTime? lastSyncedAt,
    Map<String, dynamic>? fieldValues,
    int? schemaVersion,
  }) {
    return EveningStatus(
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      fieldValues: fieldValues ?? Map<String, dynamic>.from(this.fieldValues),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}