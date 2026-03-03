import 'package:share_plus/share_plus.dart';

import '../models/analysis_result.dart';
import '../models/compatibility_report.dart';
import '../models/fish_info_result.dart';
import '../models/photo_analysis_result.dart';
import '../models/stocking_recommendation.dart';

const _appFooter =
    '\n─────────────────────\n'
    'Shared via Aquarium AI\n'
    'Get the app: https://play.google.com/store/apps/details?id=com.cca.fishai';

/// Converts a [WaterAnalysisResult] to a plain-text summary and shares it.
Future<void> shareWaterAnalysisResult(WaterAnalysisResult result) async {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Water Parameter Analysis');
  buffer.writeln('Status: ${result.summary.status}');
  buffer.writeln(result.summary.title);
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
  buffer.write(_appFooter);

  await Share.share(
    buffer.toString(),
    subject: 'Aquarium AI – Water Parameter Analysis',
  );
}

/// Converts a [PhotoAnalysisResult] to a plain-text summary and shares it.
Future<void> sharePhotoAnalysisResult(PhotoAnalysisResult result) async {
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
        '• ${fish.commonName} (${fish.scientificName}) – $confidence% confidence',
      );
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
  if (th.potentialIssues.isNotEmpty) {
    buffer.writeln('Potential Issues:');
    for (final i in th.potentialIssues) {
      buffer.writeln('• $i');
    }
    buffer.writeln();
  }
  if (th.recommendedActions.isNotEmpty) {
    buffer.writeln('Recommended Actions:');
    for (final a in th.recommendedActions) {
      buffer.writeln('• $a');
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
  buffer.write(_appFooter);

  await Share.share(buffer.toString(), subject: 'Aquarium AI – Photo Analysis');
}

/// Converts a [CompatibilityReport] to a plain-text summary and shares it.
Future<void> shareCompatibilityReport(CompatibilityReport report) async {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Fish Compatibility Report');
  buffer.writeln();
  buffer.writeln(
    'Group Harmony: ${report.harmonyLabel} (${(report.groupHarmonyScore * 100).toStringAsFixed(0)}%)',
  );
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
  buffer.writeln();
  buffer.writeln('Compatible Tank Mates:');
  buffer.writeln(report.tankMatesSummary);
  if (report.compatibleFish.isNotEmpty) {
    buffer.writeln(report.compatibleFish.join(', '));
  }
  buffer.writeln();
  buffer.writeln('Recommended Tank Size: ${report.tankSize}');
  buffer.writeln();
  buffer.writeln('Decorations and Setup:');
  buffer.writeln(report.decorations);
  buffer.writeln();
  buffer.writeln('Care Guide:');
  buffer.writeln(report.careGuide);
  buffer.write(_appFooter);

  await Share.share(
    buffer.toString(),
    subject: 'Aquarium AI – Fish Compatibility Report',
  );
}

/// Converts a list of [StockingRecommendation] objects (one tab) to plain text
/// and shares it.
Future<void> shareStockingReport(StockingRecommendation report) async {
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
  buffer.write(_appFooter);

  await Share.share(
    buffer.toString(),
    subject: 'Aquarium AI – Stocking Recommendation',
  );
}

/// Shares a plain-text AI chat response.
Future<void> shareChatResponse(String text) async {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Chat Response');
  buffer.writeln();
  buffer.write(text);
  buffer.write(_appFooter);

  await Share.share(buffer.toString(), subject: 'Aquarium AI – Chat Response');
}

/// Converts a [FishInfoResult] to a plain-text summary and shares it.
Future<void> shareFishInfoResult(FishInfoResult result) async {
  final buffer = StringBuffer();
  buffer.writeln('🐠 Aquarium AI – Fish Info Lookup');

  for (final fish in result.fish) {
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(fish.commonName);
    if (fish.scientificName.isNotEmpty) {
      buffer.writeln(fish.scientificName);
    }
    buffer.writeln();

    if (fish.originHabitat.isNotEmpty) {
      buffer.writeln('📍 Origin & Habitat');
      buffer.writeln(fish.originHabitat);
      buffer.writeln();
    }

    if (fish.keyFacts.isNotEmpty) {
      buffer.writeln('📋 Key Facts');
      for (final fact in fish.keyFacts) {
        buffer.writeln('• $fact');
      }
      buffer.writeln();
    }

    if (fish.funFacts.isNotEmpty) {
      buffer.writeln('✨ Fun Facts');
      for (final fact in fish.funFacts) {
        buffer.writeln('• $fact');
      }
      buffer.writeln();
    }

    buffer.writeln('🪣 Tank Care');
    if (fish.care.minimumTankSize.isNotEmpty) {
      buffer.writeln('Minimum Tank Size: ${fish.care.minimumTankSize}');
    }
    if (fish.care.difficultyLevel.isNotEmpty) {
      buffer.writeln('Difficulty: ${fish.care.difficultyLevel}');
    }
    if (fish.care.waterParameters.isNotEmpty) {
      buffer.writeln('Water Parameters: ${fish.care.waterParameters}');
    }
    if (fish.care.tankSetup.isNotEmpty) {
      buffer.writeln('Tank Setup: ${fish.care.tankSetup}');
    }
    buffer.writeln();

    if (fish.compatibleTankMates.isNotEmpty) {
      buffer.writeln('🤝 Compatible Tank Mates');
      buffer.writeln(fish.compatibleTankMates.join(', '));
      buffer.writeln();
    }

    if (fish.incompatibleSpecies.isNotEmpty) {
      buffer.writeln('⚠️ Species to Avoid');
      buffer.writeln(fish.incompatibleSpecies.join(', '));
      buffer.writeln();
    }
  }
  buffer.write(_appFooter);

  await Share.share(buffer.toString(), subject: 'Aquarium AI – Fish Info');
}
