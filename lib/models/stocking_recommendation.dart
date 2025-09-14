import 'package:fish_ai/models/fish.dart';

class StockingRecommendation {
  final String title;
  final String summary;
  final List<Fish> coreFish;
  final List<Fish> otherDataBasedFish;
  final String aiTankMatesSummary;
  final List<String> aiRecommendedTankMates;
  final double harmonyScore;

  StockingRecommendation({
    required this.title,
    required this.summary,
    required this.coreFish,
    required this.otherDataBasedFish,
    required this.aiTankMatesSummary,
    required this.aiRecommendedTankMates,
    required this.harmonyScore,
  });
}