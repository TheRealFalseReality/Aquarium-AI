import 'package:fish_ai/models/fish.dart';

class StockingRecommendation {
  final String title;
  final String summary;
  final List<Fish> coreFish;
  final List<Fish> otherDataBasedFish;
  final String aiTankMatesSummary;
  final List<String> aiRecommendedTankMates;
  final double harmonyScore;
  final String? compatibilityNotes;
  final bool isAdditionRecommendation;

  StockingRecommendation({
    required this.title,
    required this.summary,
    required this.coreFish,
    required this.otherDataBasedFish,
    required this.aiTankMatesSummary,
    required this.aiRecommendedTankMates,
    required this.harmonyScore,
    this.compatibilityNotes,
    this.isAdditionRecommendation = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'coreFish': coreFish.map((f) => f.toJson()).toList(),
    'otherDataBasedFish': otherDataBasedFish.map((f) => f.toJson()).toList(),
    'aiTankMatesSummary': aiTankMatesSummary,
    'aiRecommendedTankMates': aiRecommendedTankMates,
    'harmonyScore': harmonyScore,
    'compatibilityNotes': compatibilityNotes,
    'isAdditionRecommendation': isAdditionRecommendation,
  };

  factory StockingRecommendation.fromJson(Map<String, dynamic> json) {
    return StockingRecommendation(
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      coreFish: (json['coreFish'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Fish.fromJson)
          .toList(),
      otherDataBasedFish: (json['otherDataBasedFish'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Fish.fromJson)
          .toList(),
      aiTankMatesSummary: json['aiTankMatesSummary'] as String? ?? '',
      aiRecommendedTankMates:
          List<String>.from(json['aiRecommendedTankMates'] as List? ?? []),
      harmonyScore: (json['harmonyScore'] as num?)?.toDouble() ?? 0.0,
      compatibilityNotes: json['compatibilityNotes'] as String?,
      isAdditionRecommendation:
          json['isAdditionRecommendation'] as bool? ?? false,
    );
  }
}
