/// Model representing a species tag that can be associated with a fish type
class SpeciesTag {
  final String fishType;
  final List<String> tags;

  SpeciesTag({
    required this.fishType,
    required this.tags,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'fishType': fishType,
      'tags': tags,
    };
  }

  // Create from JSON
  factory SpeciesTag.fromJson(Map<String, dynamic> json) {
    return SpeciesTag(
      fishType: json['fishType'] as String,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // Create a copy with updated tags
  SpeciesTag copyWith({
    String? fishType,
    List<String>? tags,
  }) {
    return SpeciesTag(
      fishType: fishType ?? this.fishType,
      tags: tags ?? this.tags,
    );
  }
}

