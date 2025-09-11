class CompatibilityReport {
  final String harmonyLabel;
  final String harmonySummary;
  final String detailedSummary;
  final String tankSize;
  final String decorations;
  final String careGuide;
  final List<String> compatibleFish;
  final double groupHarmonyScore;

  CompatibilityReport({
    required this.harmonyLabel,
    required this.harmonySummary,
    required this.detailedSummary,
    required this.tankSize,
    required this.decorations,
    required this.careGuide,
    required this.compatibleFish,
    required this.groupHarmonyScore,
  });
}