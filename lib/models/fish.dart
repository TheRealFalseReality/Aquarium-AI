class Fish {
  final String? uuid; // Stable unique identifier; null for legacy entries without UUID
  final String name;
  final String? originHabitat; // Where the fish originates / its natural habitat
  final List<String> careFacts; // Bullet-point care information
  final String? generalInfo; // General aquarium information (short paragraph)
  final List<String> compatibilityHighlights; // Compatibility highlight bullets
  final String? funFact; // Short fun fact about the species
  final List<String> commonNames;
  final String imageURL;
  final String? reefSafe;
  final List<String> compatible;
  final List<String> notRecommended;
  final List<String> notCompatible;
  final List<String> withCaution;
  // Custom fish fields (not present on library fish from Firestore)
  final bool isCustom; // true for user-created fish stored locally
  final String? category; // 'freshwater' or 'marine' (required for custom fish)
  final String? customLocalImagePath; // local file path for uploaded image (excluded from backup)

  Fish({
    this.uuid,
    required this.name,
    this.originHabitat,
    this.careFacts = const [],
    this.generalInfo,
    this.compatibilityHighlights = const [],
    this.funFact,
    required this.commonNames,
    required this.imageURL,
    this.reefSafe,
    required this.compatible,
    required this.notRecommended,
    required this.notCompatible,
    required this.withCaution,
    this.isCustom = false,
    this.category,
    this.customLocalImagePath,
  });

  /// Whether this fish uses a locally uploaded image file.
  bool get hasLocalImage =>
      customLocalImagePath != null && customLocalImagePath!.isNotEmpty;

  /// Whether [imageURL] is a Firebase Storage download URL.
  bool get isStorageUrl =>
      !hasLocalImage && imageURL.contains('firebasestorage.googleapis.com');

  /// Local asset path for the fish image.
  ///
  /// [imageURL] follows the convention:
  ///   `https://raw.githubusercontent.com/.../assets/images/fish/XXX.webp`
  ///
  /// The bundled asset lives at the same relative path `assets/images/fish/XXX.webp`,
  /// so we simply extract the `assets/…` suffix from the URL.
  ///
  /// Returns an empty string for Firebase Storage URLs or custom local-image fish
  /// — those images have no corresponding local asset, so [FishImage] should fall
  /// back to the network URL immediately.
  String get localImagePath {
    // Custom fish with an uploaded local image — handled separately by FishImage.
    if (hasLocalImage) return '';
    // Firebase Storage images have no bundled local asset counterpart.
    if (isStorageUrl) return '';
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
      originHabitat: json['originHabitat'] as String?,
      careFacts: List<String>.from(json['careFacts'] ?? []),
      generalInfo: json['generalInfo'] as String?,
      compatibilityHighlights: List<String>.from(
        json['compatibilityHighlights'] ?? [],
      ),
      funFact: json['funFact'] as String?,
      commonNames: List<String>.from(json['commonNames'] ?? []),
      imageURL: json['imageURL'] as String,
      reefSafe: json['reefSafe'] as String?,
      // Use the new helper function to parse each list
      compatible: parseStringList(json['compatible']),
      notRecommended: parseStringList(json['notRecommended']),
      notCompatible: parseStringList(json['notCompatible']),
      withCaution: parseStringList(json['withCaution']),
      isCustom: json['isCustom'] as bool? ?? false,
      category: json['category'] as String?,
      customLocalImagePath: json['customLocalImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeLocalPaths = true}) => {
    if (uuid != null) 'uuid': uuid,
    'name': name,
    if (originHabitat != null) 'originHabitat': originHabitat,
    if (careFacts.isNotEmpty) 'careFacts': careFacts,
    if (generalInfo != null) 'generalInfo': generalInfo,
    if (compatibilityHighlights.isNotEmpty)
      'compatibilityHighlights': compatibilityHighlights,
    if (funFact != null) 'funFact': funFact,
    'commonNames': commonNames,
    'imageURL': imageURL,
    if (reefSafe != null) 'reefSafe': reefSafe,
    'compatible': compatible,
    'notRecommended': notRecommended,
    'notCompatible': notCompatible,
    'withCaution': withCaution,
    if (isCustom) 'isCustom': isCustom,
    if (category != null) 'category': category,
    // Exclude local image paths from backups to prevent restore errors on different devices
    if (includeLocalPaths && customLocalImagePath != null)
      'customLocalImagePath': customLocalImagePath,
  };

  Fish copyWith({
    String? uuid,
    String? name,
    String? originHabitat,
    List<String>? careFacts,
    String? generalInfo,
    List<String>? compatibilityHighlights,
    String? funFact,
    List<String>? commonNames,
    String? imageURL,
    String? reefSafe,
    List<String>? compatible,
    List<String>? notRecommended,
    List<String>? notCompatible,
    List<String>? withCaution,
    bool? isCustom,
    String? category,
    String? customLocalImagePath,
    bool clearCustomLocalImagePath = false,
  }) {
    return Fish(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      originHabitat: originHabitat ?? this.originHabitat,
      careFacts: careFacts ?? this.careFacts,
      generalInfo: generalInfo ?? this.generalInfo,
      compatibilityHighlights:
          compatibilityHighlights ?? this.compatibilityHighlights,
      funFact: funFact ?? this.funFact,
      commonNames: commonNames ?? this.commonNames,
      imageURL: imageURL ?? this.imageURL,
      reefSafe: reefSafe ?? this.reefSafe,
      compatible: compatible ?? this.compatible,
      notRecommended: notRecommended ?? this.notRecommended,
      notCompatible: notCompatible ?? this.notCompatible,
      withCaution: withCaution ?? this.withCaution,
      isCustom: isCustom ?? this.isCustom,
      category: category ?? this.category,
      customLocalImagePath: clearCustomLocalImagePath
          ? null
          : (customLocalImagePath ?? this.customLocalImagePath),
    );
  }
}
