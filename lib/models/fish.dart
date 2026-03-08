class Fish {
  final String? uuid; // Stable unique identifier; null for legacy entries without UUID
  final String name;
  final String? description; // Optional plain-text description of this fish type
  final List<String> commonNames;
  final String imageURL;
  final String? reefSafe;
  final List<String> compatible;
  final List<String> notRecommended;
  final List<String> notCompatible;
  final List<String> withCaution;

  Fish({
    this.uuid,
    required this.name,
    this.description,
    required this.commonNames,
    required this.imageURL,
    this.reefSafe,
    required this.compatible,
    required this.notRecommended,
    required this.notCompatible,
    required this.withCaution,
  });

  /// Local asset path for the fish image.
  ///
  /// [imageURL] follows the convention:
  ///   `https://raw.githubusercontent.com/.../assets/images/fish/XXX.webp`
  ///
  /// The bundled asset lives at the same relative path `assets/images/fish/XXX.webp`,
  /// so we simply extract the `assets/…` suffix from the URL.
  String get localImagePath {
    const assetsMarker = 'assets/';
    final idx = imageURL.indexOf(assetsMarker);
    if (idx != -1) {
      return imageURL.substring(idx);
    }
    // Fallback for bare filenames (no URL prefix).
    final filename = imageURL.contains('/') ? imageURL.split('/').last : imageURL;
    final base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return 'assets/images/fish/$base.webp';
  }

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
      uuid: json['uuid'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      commonNames: List<String>.from(json['commonNames'] ?? []),
      imageURL: json['imageURL'] as String,
      reefSafe: json['reefSafe'] as String?,
      // Use the new helper function to parse each list
      compatible: parseStringList(json['compatible']),
      notRecommended: parseStringList(json['notRecommended']),
      notCompatible: parseStringList(json['notCompatible']),
      withCaution: parseStringList(json['withCaution']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (uuid != null) 'uuid': uuid,
    'name': name,
    if (description != null) 'description': description,
    'commonNames': commonNames,
    'imageURL': imageURL,
    if (reefSafe != null) 'reefSafe': reefSafe,
    'compatible': compatible,
    'notRecommended': notRecommended,
    'notCompatible': notCompatible,
    'withCaution': withCaution,
  };
}
