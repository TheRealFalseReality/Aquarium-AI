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

  Map<String, dynamic> toJson() => {
    'harmonyLabel': harmonyLabel,
    'harmonySummary': harmonySummary,
    'detailedSummary': detailedSummary,
    'tankSize': tankSize,
    'decorations': decorations,
    'careGuide': careGuide,
    'compatibleFish': compatibleFish,
    'groupHarmonyScore': groupHarmonyScore,
    'selectedFish': selectedFish.map((f) => f.toJson()).toList(),
    'tankMatesSummary': tankMatesSummary,
    'calculationBreakdown': calculationBreakdown,
  };

  factory CompatibilityReport.fromJson(Map<String, dynamic> json) {
    return CompatibilityReport(
      harmonyLabel: json['harmonyLabel'] as String? ?? '',
      harmonySummary: json['harmonySummary'] as String? ?? '',
      detailedSummary: json['detailedSummary'] as String? ?? '',
      tankSize: json['tankSize'] as String? ?? '',
      decorations: json['decorations'] as String? ?? '',
      careGuide: json['careGuide'] as String? ?? '',
      compatibleFish: List<String>.from(json['compatibleFish'] as List? ?? []),
      groupHarmonyScore:
          (json['groupHarmonyScore'] as num?)?.toDouble() ?? 0.0,
      selectedFish: (json['selectedFish'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Fish.fromJson)
          .toList(),
      tankMatesSummary: json['tankMatesSummary'] as String? ?? '',
      calculationBreakdown: json['calculationBreakdown'] as String? ?? '',
    );
  }
}
