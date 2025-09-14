import 'package:fish_ai/models/fish.dart';

class StockingRecommendation {
  final String title;
  final String summary;
  final List<Fish> fish;
  final double harmonyScore;
  final String tankMatesSummary;
  final List<String> tankMates;

  StockingRecommendation({
    required this.title,
    required this.summary,
    required this.fish,
    required this.harmonyScore,
    required this.tankMatesSummary,
    required this.tankMates,
  });
}