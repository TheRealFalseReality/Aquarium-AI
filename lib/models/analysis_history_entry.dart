import 'package:uuid/uuid.dart';

/// The type of AI analysis stored in a history entry.
enum AnalysisType {
  waterParameters,
  photoAnalysis,
  fishInfo,
  automationScript,
  compatibilityReport,
  stockingRecommendation;

  String get displayName {
    switch (this) {
      case AnalysisType.waterParameters:
        return 'Water Parameter Analysis';
      case AnalysisType.photoAnalysis:
        return 'Photo Analysis';
      case AnalysisType.fishInfo:
        return 'Fish Info';
      case AnalysisType.automationScript:
        return 'Automation Script';
      case AnalysisType.compatibilityReport:
        return 'Compatibility Report';
      case AnalysisType.stockingRecommendation:
        return 'Stocking Recommendation';
    }
  }

  static AnalysisType fromString(String value) {
    return AnalysisType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisType.waterParameters,
    );
  }
}

/// A single saved AI analysis report in the history log.
class AnalysisHistoryEntry {
  final String id;
  final AnalysisType type;
  final String title;
  final DateTime timestamp;
  final bool isFavorite;

  /// Serialized result data (parsed back via the relevant model's fromJson).
  final Map<String, dynamic> resultData;

  /// Base64-encoded photo bytes for photo analyses (may be null).
  final String? photoBase64;

  /// Name of the AI model used for this analysis (e.g. 'gemini-2.0-flash').
  final String? modelName;

  AnalysisHistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.timestamp,
    this.isFavorite = false,
    required this.resultData,
    this.photoBase64,
    this.modelName,
  });

  /// Creates a new entry with a generated UUID and the current time.
  factory AnalysisHistoryEntry.create({
    required AnalysisType type,
    required String title,
    required Map<String, dynamic> resultData,
    String? photoBase64,
    String? modelName,
  }) {
    return AnalysisHistoryEntry(
      id: const Uuid().v4(),
      type: type,
      title: title,
      timestamp: DateTime.now(),
      resultData: resultData,
      photoBase64: photoBase64,
      modelName: modelName,
    );
  }

  AnalysisHistoryEntry copyWith({bool? isFavorite}) {
    return AnalysisHistoryEntry(
      id: id,
      type: type,
      title: title,
      timestamp: timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      resultData: resultData,
      photoBase64: photoBase64,
      modelName: modelName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'timestamp': timestamp.toIso8601String(),
    'isFavorite': isFavorite,
    'resultData': resultData,
    'photoBase64': photoBase64,
    'modelName': modelName,
  };

  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryEntry(
      id: json['id'] as String,
      type: AnalysisType.fromString(json['type'] as String),
      title: json['title'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      resultData: (json['resultData'] as Map<String, dynamic>?) ?? {},
      photoBase64: json['photoBase64'] as String?,
      modelName: json['modelName'] as String?,
    );
  }
}
