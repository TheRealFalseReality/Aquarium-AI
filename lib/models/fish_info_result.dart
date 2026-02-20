import 'dart:convert';

class FishCare {
  final String minimumTankSize;
  final String waterParameters;
  final String tankSetup;
  final String difficultyLevel;

  FishCare({
    required this.minimumTankSize,
    required this.waterParameters,
    required this.tankSetup,
    required this.difficultyLevel,
  });

  factory FishCare.fromJson(Map<String, dynamic> json) {
    return FishCare(
      minimumTankSize: json['minimumTankSize'] as String? ?? 'Unknown',
      waterParameters: json['waterParameters'] as String? ?? '',
      tankSetup: json['tankSetup'] as String? ?? '',
      difficultyLevel: json['difficultyLevel'] as String? ?? 'Unknown',
    );
  }
}

class FishInfoEntry {
  final String commonName;
  final String scientificName;
  final String originHabitat;
  final List<String> keyFacts;
  final List<String> funFacts;
  final FishCare care;
  final List<String> compatibleTankMates;
  final List<String> incompatibleSpecies;

  FishInfoEntry({
    required this.commonName,
    required this.scientificName,
    required this.originHabitat,
    required this.keyFacts,
    required this.funFacts,
    required this.care,
    required this.compatibleTankMates,
    required this.incompatibleSpecies,
  });

  factory FishInfoEntry.fromJson(Map<String, dynamic> json) {
    return FishInfoEntry(
      commonName: json['commonName'] as String? ?? 'Unknown',
      scientificName: json['scientificName'] as String? ?? '',
      originHabitat: json['originHabitat'] as String? ?? '',
      keyFacts: List<String>.from(json['keyFacts'] as List? ?? []),
      funFacts: List<String>.from(json['funFacts'] as List? ?? []),
      care: FishCare.fromJson(
        json['care'] is Map<String, dynamic>
            ? json['care'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      compatibleTankMates:
          List<String>.from(json['compatibleTankMates'] as List? ?? []),
      incompatibleSpecies:
          List<String>.from(json['incompatibleSpecies'] as List? ?? []),
    );
  }
}

class FishInfoResult {
  final List<FishInfoEntry> fish;

  FishInfoResult({required this.fish});

  factory FishInfoResult.fromJson(Map<String, dynamic> json) {
    final fishList = (json['fish'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FishInfoEntry.fromJson)
        .toList();
    return FishInfoResult(fish: fishList);
  }

  static FishInfoResult? tryParseJson(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return FishInfoResult.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
