// lib/models/fish.dart

class Fish {
  final String name;
  final List<String> commonNames;
  final String imageURL;
  final List<String> compatible;
  final List<String> notRecommended;
  final List<String> notCompatible;
  final List<String> withCaution;

  Fish({
    required this.name,
    required this.commonNames,
    required this.imageURL,
    required this.compatible,
    required this.notRecommended,
    required this.notCompatible,
    required this.withCaution,
  });

  factory Fish.fromJson(Map<String, dynamic> json) {
    return Fish(
      name: json['name'] as String,
      commonNames: List<String>.from(json['commonNames'] ?? []),
      imageURL: json['imageURL'] as String,
      compatible: List<String>.from(json['compatible'] ?? []),
      notRecommended: List<String>.from(json['notRecommended'] ?? []),
      notCompatible: List<String>.from(json['notCompatible'] ?? []),
      withCaution: List<String>.from(json['withCaution'] ?? []),
    );
  }
}