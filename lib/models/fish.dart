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
    // Helper function to safely parse lists that might contain objects
    List<String> parseStringList(List<dynamic>? data) {
      if (data == null) return [];
      // Check if the first item is a String or a Map
      if (data.isNotEmpty && data.first is Map) {
        return data.map((item) => item['name'] as String).toList();
      }
      return List<String>.from(data);
    }

    return Fish(
      name: json['name'] as String,
      commonNames: List<String>.from(json['commonNames'] ?? []),
      imageURL: json['imageURL'] as String,
      // Use the new helper function to parse each list
      compatible: parseStringList(json['compatible']),
      notRecommended: parseStringList(json['notRecommended']),
      notCompatible: parseStringList(json['notCompatible']),
      withCaution: parseStringList(json['withCaution']),
    );
  }
}