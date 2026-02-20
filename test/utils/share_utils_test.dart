import 'package:fish_ai/models/analysis_result.dart';
import 'package:fish_ai/models/compatibility_report.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/photo_analysis_result.dart';
import 'package:fish_ai/models/stocking_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper: builds the same plain-text body that [shareWaterAnalysisResult]
/// would produce, so we can unit-test the formatting without calling
/// [SharePlus] (which requires native platform support).
String _buildWaterAnalysisText(WaterAnalysisResult result) {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Water Parameter Analysis');
  buffer.writeln('Status: ${result.summary.status}');
  buffer.writeln('${result.summary.title}');
  buffer.writeln();
  buffer.writeln(result.summary.message);
  buffer.writeln();

  for (final param in result.parameters) {
    buffer.writeln('• ${param.name}: ${param.value} (${param.status})');
    buffer.writeln('  Ideal range: ${param.idealRange}');
    buffer.writeln('  ${param.advice}');
    buffer.writeln();
  }

  buffer.writeln('How AquaPi Can Help:');
  buffer.writeln(result.howAquaPiHelps);
  return buffer.toString();
}

String _buildPhotoAnalysisText(PhotoAnalysisResult result) {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Aquarium Photo Analysis');
  buffer.writeln();
  buffer.writeln(result.summary);
  buffer.writeln();

  if (result.identifiedFish.isNotEmpty) {
    buffer.writeln('Identified Fish:');
    for (final fish in result.identifiedFish) {
      final confidence = (fish.confidence * 100).toStringAsFixed(1);
      buffer.writeln(
          '• ${fish.commonName} (${fish.scientificName}) – $confidence% confidence');
      if (fish.notes.isNotEmpty) {
        buffer.writeln('  ${fish.notes}');
      }
    }
    buffer.writeln();
  }

  final th = result.tankHealth;
  if (th.observations.isNotEmpty) {
    buffer.writeln('Tank Observations:');
    for (final o in th.observations) {
      buffer.writeln('• $o');
    }
    buffer.writeln();
  }

  final g = result.waterQualityGuesses;
  buffer.writeln('Visual Water Quality:');
  buffer.writeln('  Clarity: ${g.clarity}');
  buffer.writeln('  Algae Level: ${g.algaeLevel}');
  buffer.writeln('  Stocking: ${g.stockingAssessment}');
  buffer.writeln();
  buffer.writeln('How AquaPi Can Help:');
  buffer.writeln(result.howAquaPiHelps);
  return buffer.toString();
}

String _buildCompatibilityText(CompatibilityReport report) {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Fish Compatibility Report');
  buffer.writeln();
  buffer.writeln(
      'Group Harmony: ${report.harmonyLabel} (${(report.groupHarmonyScore * 100).toStringAsFixed(0)}%)');
  buffer.writeln(report.harmonySummary);
  buffer.writeln();

  if (report.selectedFish.isNotEmpty) {
    buffer.writeln('Selected Fish:');
    for (final fish in report.selectedFish) {
      buffer.writeln('• ${fish.name}');
    }
    buffer.writeln();
  }

  buffer.writeln('Detailed Summary:');
  buffer.writeln(report.detailedSummary);
  return buffer.toString();
}

String _buildStockingText(StockingRecommendation report) {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Stocking Recommendation');
  buffer.writeln();
  buffer.writeln(report.title);
  buffer.writeln();
  buffer.writeln(report.summary);
  buffer.writeln();

  if (report.coreFish.isNotEmpty) {
    buffer.writeln('Core Fish:');
    for (final fish in report.coreFish) {
      buffer.writeln('• ${fish.name}');
    }
    buffer.writeln();
  }

  if (report.aiTankMatesSummary.isNotEmpty) {
    buffer.writeln('Recommended Tank Mates:');
    buffer.writeln(report.aiTankMatesSummary);
    if (report.aiRecommendedTankMates.isNotEmpty) {
      buffer.writeln(report.aiRecommendedTankMates.join(', '));
    }
  }
  return buffer.toString();
}

void main() {
  group('share_utils text formatting', () {
    test('water analysis share text contains header and status', () {
      final result = WaterAnalysisResult(
        summary: AnalysisSummary(
          status: 'Good',
          title: 'Water Analysis Complete',
          message: 'Parameters look fine.',
        ),
        parameters: [
          ParameterAnalysis(
            name: 'pH',
            value: '7.2',
            idealRange: '6.5-7.5',
            status: 'Good',
            advice: 'pH is ideal.',
          ),
        ],
        howAquaPiHelps: 'AquaPi can help.',
      );

      final text = _buildWaterAnalysisText(result);

      expect(text, contains('Aquarium AI'));
      expect(text, contains('Water Parameter Analysis'));
      expect(text, contains('Status: Good'));
      expect(text, contains('Water Analysis Complete'));
      expect(text, contains('pH: 7.2 (Good)'));
      expect(text, contains('Ideal range: 6.5-7.5'));
      expect(text, contains('pH is ideal.'));
      expect(text, contains('AquaPi can help.'));
    });

    test('photo analysis share text contains fish identification', () {
      final result = PhotoAnalysisResult(
        summary: 'Healthy aquarium detected.',
        identifiedFish: [
          IdentifiedFish(
            commonName: 'Clownfish',
            scientificName: 'Amphiprioninae',
            confidence: 0.95,
            notes: 'Bright orange coloration.',
          ),
        ],
        tankHealth: TankHealthAssessment(
          observations: ['Crystal clear water'],
          potentialIssues: [],
          recommendedActions: [],
        ),
        waterQualityGuesses: VisualWaterQualityGuesses(
          clarity: 'Clear',
          algaeLevel: 'Low',
          stockingAssessment: 'Adequate',
        ),
        howAquaPiHelps: 'AquaPi monitors water quality.',
        raw: {},
      );

      final text = _buildPhotoAnalysisText(result);

      expect(text, contains('Aquarium AI'));
      expect(text, contains('Photo Analysis'));
      expect(text, contains('Healthy aquarium detected.'));
      expect(text, contains('Clownfish'));
      expect(text, contains('Amphiprioninae'));
      expect(text, contains('95.0% confidence'));
      expect(text, contains('Crystal clear water'));
      expect(text, contains('Clarity: Clear'));
      expect(text, contains('Algae Level: Low'));
      expect(text, contains('AquaPi monitors water quality.'));
    });

    test('compatibility report share text contains harmony score', () {
      final fish = Fish(
        name: 'Neon Tetra',
        compatible: [],
        notCompatible: [],
        notRecommended: [],
        withCaution: [],
        imageURL: '',
        commonNames: ['Neon Tetra'],
      );

      final report = CompatibilityReport(
        harmonyLabel: 'Excellent',
        harmonySummary: 'Great combination.',
        detailedSummary: 'These fish work well together.',
        tankSize: '20 gallons',
        decorations: 'Plants and rocks.',
        careGuide: 'Feed twice daily.',
        compatibleFish: ['Guppy', 'Molly'],
        groupHarmonyScore: 0.9,
        selectedFish: [fish],
        tankMatesSummary: 'Compatible with many species.',
        calculationBreakdown: 'Score: 90%',
      );

      final text = _buildCompatibilityText(report);

      expect(text, contains('Aquarium AI'));
      expect(text, contains('Compatibility Report'));
      expect(text, contains('Excellent'));
      expect(text, contains('90%'));
      expect(text, contains('Neon Tetra'));
      expect(text, contains('These fish work well together.'));
    });

    test('stocking report share text contains fish list', () {
      final fish = Fish(
        name: 'Guppy',
        compatible: [],
        notCompatible: [],
        notRecommended: [],
        withCaution: [],
        imageURL: '',
        commonNames: ['Guppy'],
      );

      final report = StockingRecommendation(
        title: 'Beginner Community Tank',
        summary: 'A peaceful community setup.',
        coreFish: [fish],
        otherDataBasedFish: [],
        aiTankMatesSummary: 'Suitable for small community tanks.',
        aiRecommendedTankMates: ['Platy', 'Molly'],
        harmonyScore: 0.85,
      );

      final text = _buildStockingText(report);

      expect(text, contains('Aquarium AI'));
      expect(text, contains('Stocking Recommendation'));
      expect(text, contains('Beginner Community Tank'));
      expect(text, contains('A peaceful community setup.'));
      expect(text, contains('Guppy'));
      expect(text, contains('Suitable for small community tanks.'));
      expect(text, contains('Platy'));
      expect(text, contains('Molly'));
    });
  });
}
