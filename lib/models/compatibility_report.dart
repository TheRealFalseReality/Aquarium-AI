import 'fish.dart';

class CompatibilityReport {
  final String harmonyLabel;
  final String harmonySummary;
  final String detailedSummary;
  final String tankSize;
  final String decorations;
  final String careGuide;
  final List<String> compatibleFish;
  final double groupHarmonyScore;
  final List<Fish> selectedFish;
  final String tankMatesSummary;
  // ADDED: New field for the calculation breakdown.
  final String calculationBreakdown;

  CompatibilityReport({
    required this.harmonyLabel,
    required this.harmonySummary,
    required this.detailedSummary,
    required this.tankSize,
    required this.decorations,
    required this.careGuide,
    required this.compatibleFish,
    required this.groupHarmonyScore,
    required this.selectedFish,
    required this.tankMatesSummary,
    // ADDED: Added the new field to the constructor.
    required this.calculationBreakdown,
  });
}