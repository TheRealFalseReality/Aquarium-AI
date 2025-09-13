import 'dart:convert';
import 'dart:typed_data';

/// Represents a single identified fish in the photo.
class IdentifiedFish {
  final String commonName;
  final String scientificName;
  final double confidence;
  final String notes;

  IdentifiedFish({
    required this.commonName,
    required this.scientificName,
    required this.confidence,
    required this.notes,
  });

  factory IdentifiedFish.fromJson(Map<String, dynamic> json) {
    return IdentifiedFish(
      commonName: json['commonName'] ?? 'Unknown',
      scientificName: json['scientificName'] ?? 'Unknown',
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : 0.0,
      notes: json['notes'] ?? '',
    );
  }
}

class TankHealthAssessment {
  final List<String> observations;
  final List<String> potentialIssues;
  final List<String> recommendedActions;

  TankHealthAssessment({
    required this.observations,
    required this.potentialIssues,
    required this.recommendedActions,
  });

  factory TankHealthAssessment.fromJson(Map<String, dynamic> json) {
    return TankHealthAssessment(
      observations: List<String>.from(json['observations'] ?? []),
      potentialIssues: List<String>.from(json['potentialIssues'] ?? []),
      recommendedActions: List<String>.from(json['recommendedActions'] ?? []),
    );
  }
}

class VisualWaterQualityGuesses {
  final String clarity;
  final String algaeLevel;
  final String stockingAssessment;

  VisualWaterQualityGuesses({
    required this.clarity,
    required this.algaeLevel,
    required this.stockingAssessment,
  });

  factory VisualWaterQualityGuesses.fromJson(Map<String, dynamic> json) {
    return VisualWaterQualityGuesses(
      clarity: json['clarity'] ?? 'Unknown',
      algaeLevel: json['algaeLevel'] ?? 'Unknown',
      stockingAssessment: json['stockingAssessment'] ?? 'Unknown',
    );
  }
}

class PhotoAnalysisResult {
  final String summary;
  final List<IdentifiedFish> identifiedFish;
  final TankHealthAssessment tankHealth;
  final VisualWaterQualityGuesses waterQualityGuesses;
  final String howAquaPiHelps;
  final Map<String, dynamic> raw;

  PhotoAnalysisResult({
    required this.summary,
    required this.identifiedFish,
    required this.tankHealth,
    required this.waterQualityGuesses,
    required this.howAquaPiHelps,
    required this.raw,
  });

  factory PhotoAnalysisResult.fromJson(Map<String, dynamic> json) {
    final fishList = (json['identifiedFish'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IdentifiedFish.fromJson)
        .toList();

    return PhotoAnalysisResult(
      summary: json['summary'] ?? 'No summary generated.',
      identifiedFish: fishList,
      tankHealth: TankHealthAssessment.fromJson(
        json['tankHealth'] is Map ? json['tankHealth'] : <String, dynamic>{},
      ),
      waterQualityGuesses: VisualWaterQualityGuesses.fromJson(
        json['waterQualityGuesses'] is Map
            ? json['waterQualityGuesses']
            : <String, dynamic>{},
      ),
      howAquaPiHelps: json['howAquaPiHelps'] ??
          'AquaPi helps automate monitoring. [Shop AquaPi](https://www.capitalcityaquatics.com/store)',
      raw: json,
    );
  }

  static PhotoAnalysisResult? tryParseJson(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return PhotoAnalysisResult.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

/// Optional helpers if you later store images as base64.
String encodeBytes(Uint8List bytes) => base64Encode(bytes);
Uint8List? decodeBytes(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty) return null;
  try {
    return base64Decode(base64Str);
  } catch (_) {
    return null;
  }
}