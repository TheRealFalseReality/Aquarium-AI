import 'package:uuid/uuid.dart';

import 'dosing_entry.dart';
import 'notification_log.dart';
import 'tank_note.dart';
import 'tank_notification.dart';
import 'water_parameter.dart';

/// A user-created label for a tank.
///
/// [color] is an ARGB integer (e.g. `0xFF4CAF50`). When null the UI falls back
/// to the current theme's secondary colour so that tags created before this
/// field existed continue to look correct.
class TankTag {
  final String name;
  final int? color; // ARGB, nullable = use theme secondary

  const TankTag({required this.name, this.color});

  Map<String, dynamic> toJson() => {
    'name': name,
    if (color != null) 'color': color,
  };

  /// Accepts both the new object format `{"name":"…","color":…}` and the
  /// legacy plain-string format that was used before this class existed.
  factory TankTag.fromJson(dynamic json) {
    if (json is String) {
      return TankTag(name: json);
    }
    final map = json as Map<String, dynamic>;
    return TankTag(name: map['name'] as String, color: map['color'] as int?);
  }

  TankTag copyWith({String? name, int? color, bool clearColor = false}) {
    return TankTag(
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TankTag && other.name == name && other.color == color;

  @override
  int get hashCode => Object.hash(name, color);
}

class TankPhoto {
  final String id;
  final String? imageUrl; // User-provided image URL
  final String? imagePath; // User-provided image file path (for local images)
  final DateTime dateTaken; // Date when photo was taken

  TankPhoto({
    required this.id,
    this.imageUrl,
    this.imagePath,
    required this.dateTaken,
  });

  Map<String, dynamic> toJson({bool includeLocalPaths = true}) {
    return {
      'id': id,
      'imageUrl': imageUrl,
      // Exclude imagePath from backup to prevent restore errors
      if (includeLocalPaths && imagePath != null) 'imagePath': imagePath,
      'dateTaken': dateTaken.toIso8601String(),
    };
  }

  factory TankPhoto.fromJson(Map<String, dynamic> json) {
    return TankPhoto(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String?,
      imagePath: json['imagePath'] as String?,
      dateTaken: DateTime.parse(json['dateTaken'] as String),
    );
  }

  TankPhoto copyWith({
    String? id,
    String? imageUrl,
    String? imagePath,
    DateTime? dateTaken,
  }) {
    return TankPhoto(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      dateTaken: dateTaken ?? this.dateTaken,
    );
  }
}

class TankInhabitant {
  final String id;
  final String customName;
  final String fishUnit; // Matches fish name from the fish-compat database
  /// Stable UUID from the fish-compat Firestore database.  Null for
  /// inhabitants created before UUID support was added. Use for fish lookups
  /// when present; fall back to [fishUnit] name matching for backward
  /// compatibility.
  final String? fishUuid;
  final int quantity;
  final String? customImageUrl; // User-provided image URL
  final String?
  customImagePath; // User-provided image file path (for local images)
  final DateTime? dateAdded; // Date when inhabitant was added to tank
  final DateTime? dateDied; // Date when inhabitant passed away
  final List<String>
  speciesTags; // Selected species tags for more granular identification
  final String? userNotes; // User-added notes/details about this inhabitant
  final String? memorialNote; // Optional note added when memorializing

  TankInhabitant({
    required this.id,
    required this.customName,
    required this.fishUnit,
    this.fishUuid,
    required this.quantity,
    this.customImageUrl,
    this.customImagePath,
    this.dateAdded,
    this.dateDied,
    List<String>? speciesTags,
    this.userNotes,
    this.memorialNote,
  }) : speciesTags = speciesTags ?? [];

  Map<String, dynamic> toJson({bool includeLocalPaths = true}) {
    return {
      'id': id,
      'customName': customName,
      'fishUnit': fishUnit,
      if (fishUuid != null) 'fishUuid': fishUuid,
      'quantity': quantity,
      'customImageUrl': customImageUrl,
      // Exclude customImagePath from backup to prevent restore errors
      if (includeLocalPaths && customImagePath != null)
        'customImagePath': customImagePath,
      'dateAdded': dateAdded?.toIso8601String(),
      'dateDied': dateDied?.toIso8601String(),
      'speciesTags': speciesTags,
      if (userNotes != null) 'userNotes': userNotes,
      if (memorialNote != null) 'memorialNote': memorialNote,
    };
  }

  factory TankInhabitant.fromJson(Map<String, dynamic> json) {
    return TankInhabitant(
      id: json['id'] as String,
      customName: json['customName'] as String,
      fishUnit: json['fishUnit'] as String,
      fishUuid: json['fishUuid'] as String?,
      quantity: json['quantity'] as int,
      customImageUrl: json['customImageUrl'] as String?,
      customImagePath: json['customImagePath'] as String?,
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded'] as String)
          : null,
      dateDied: json['dateDied'] != null
          ? DateTime.parse(json['dateDied'] as String)
          : null,
      speciesTags:
          (json['speciesTags'] as List?)?.map((t) => t.toString()).toList() ??
          [],
      userNotes: json['userNotes'] as String?,
      memorialNote: json['memorialNote'] as String?,
    );
  }

  TankInhabitant copyWith({
    String? id,
    String? customName,
    String? fishUnit,
    String? fishUuid,
    int? quantity,
    String? customImageUrl,
    String? customImagePath,
    DateTime? dateAdded,
    DateTime? dateDied,
    List<String>? speciesTags,
    String? userNotes,
    String? memorialNote,
    bool clearUserNotes = false,
    bool clearDateDied = false,
    bool clearMemorialNote = false,
  }) {
    return TankInhabitant(
      id: id ?? this.id,
      customName: customName ?? this.customName,
      fishUnit: fishUnit ?? this.fishUnit,
      fishUuid: fishUuid ?? this.fishUuid,
      quantity: quantity ?? this.quantity,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      customImagePath: customImagePath ?? this.customImagePath,
      dateAdded: dateAdded ?? this.dateAdded,
      dateDied: clearDateDied ? null : (dateDied ?? this.dateDied),
      speciesTags: speciesTags ?? this.speciesTags,
      userNotes: clearUserNotes ? null : (userNotes ?? this.userNotes),
      memorialNote: clearMemorialNote
          ? null
          : (memorialNote ?? this.memorialNote),
    );
  }
}

class Tank {
  final String id;
  final String name;
  final String type; // 'freshwater' or 'marine'
  final bool isReef; // Only relevant when type == 'marine'
  final String? freshwaterSubtype; // Only relevant when type == 'freshwater': 'planted' or 'brackish'
  final double? substrateOverrideLbs; // User-specified substrate amount (lbs); overrides calculated recommendation
  final List<TankInhabitant> inhabitants;
  final double? sizeGallons; // Tank size in gallons
  final double? sizeLiters; // Tank size in liters
  final String? notes; // User notes about the tank
  final double? harmonyScore; // Cached harmony score (0.0 to 1.0)
  final double?
  previousHarmonyScore; // Harmony score before last inhabitants change
  final String? calculationBreakdown; // Cached calculation breakdown string
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TankPhoto> photos; // Photos of the tank (not fish)
  final String?
  customBackgroundPhotoId; // ID of photo to use as card background
  final String? customIconPhotoId; // ID of photo to use as tank icon
  final String?
  bannerPhotoId; // ID of photo to use as banner in tank details screen
  final int? customIconCodePoint; // Custom icon code point for tank card
  final List<WaterParameter> waterParameters; // Water parameter logs
  final List<DosingEntry> dosingEntries; // Dosing diary entries
  final List<TankNotification> notifications; // Task notifications
  final List<NotificationLog> notificationLogs; // Notification action logs
  final List<TankNote> tankNotes; // User notes for the tank
  final List<TankTag> tags; // User-created tags for this tank
  final List<TankInhabitant>
  memorializedInhabitants; // Inhabitants preserved after they pass away

  Tank({
    required this.id,
    required this.name,
    required this.type,
    this.isReef = false,
    this.freshwaterSubtype,
    this.substrateOverrideLbs,
    required this.inhabitants,
    this.sizeGallons,
    this.sizeLiters,
    this.notes,
    this.harmonyScore,
    this.previousHarmonyScore,
    this.calculationBreakdown,
    required this.createdAt,
    required this.updatedAt,
    List<TankPhoto>? photos,
    this.customBackgroundPhotoId,
    this.customIconPhotoId,
    this.bannerPhotoId,
    this.customIconCodePoint,
    List<WaterParameter>? waterParameters,
    List<DosingEntry>? dosingEntries,
    List<TankNotification>? notifications,
    List<NotificationLog>? notificationLogs,
    List<TankNote>? tankNotes,
    List<TankTag>? tags,
    List<TankInhabitant>? memorializedInhabitants,
  }) : photos = photos ?? [],
       waterParameters = waterParameters ?? [],
       dosingEntries = dosingEntries ?? [],
       notifications = notifications ?? [],
       notificationLogs = notificationLogs ?? [],
       tankNotes = tankNotes ?? [],
       tags = tags ?? [],
       memorializedInhabitants = memorializedInhabitants ?? [];

  factory Tank.create({
    required String name,
    required String type,
    bool isReef = false,
    String? freshwaterSubtype,
    double? substrateOverrideLbs,
    List<TankInhabitant>? inhabitants,
    double? sizeGallons,
    double? sizeLiters,
    String? notes,
    double? harmonyScore,
    double? previousHarmonyScore,
    String? calculationBreakdown,
    DateTime? createdAt,
    List<TankPhoto>? photos,
    String? customBackgroundPhotoId,
    String? customIconPhotoId,
    String? bannerPhotoId,
    int? customIconCodePoint,
    List<WaterParameter>? waterParameters,
    List<DosingEntry>? dosingEntries,
    List<TankNotification>? notifications,
    List<NotificationLog>? notificationLogs,
    List<TankNote>? tankNotes,
    List<TankTag>? tags,
    List<TankInhabitant>? memorializedInhabitants,
  }) {
    final now = DateTime.now();
    return Tank(
      id: const Uuid().v4(),
      name: name,
      type: type,
      isReef: isReef,
      freshwaterSubtype: freshwaterSubtype,
      substrateOverrideLbs: substrateOverrideLbs,
      inhabitants: inhabitants ?? [],
      sizeGallons: sizeGallons,
      sizeLiters: sizeLiters,
      notes: notes,
      harmonyScore: harmonyScore,
      previousHarmonyScore: previousHarmonyScore,
      calculationBreakdown: calculationBreakdown,
      createdAt: createdAt ?? now,
      updatedAt: now,
      photos: photos,
      customBackgroundPhotoId: customBackgroundPhotoId,
      customIconPhotoId: customIconPhotoId,
      bannerPhotoId: bannerPhotoId,
      customIconCodePoint: customIconCodePoint,
      waterParameters: waterParameters,
      dosingEntries: dosingEntries,
      notifications: notifications,
      notificationLogs: notificationLogs,
      tankNotes: tankNotes,
      tags: tags,
      memorializedInhabitants: memorializedInhabitants,
    );
  }

  Map<String, dynamic> toJson({bool includeLocalPaths = true}) {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isReef': isReef,
      if (freshwaterSubtype != null) 'freshwaterSubtype': freshwaterSubtype,
      if (substrateOverrideLbs != null)
        'substrateOverrideLbs': substrateOverrideLbs,
      'inhabitants': inhabitants
          .map((i) => i.toJson(includeLocalPaths: includeLocalPaths))
          .toList(),
      'sizeGallons': sizeGallons,
      'sizeLiters': sizeLiters,
      'notes': notes,
      'harmonyScore': harmonyScore,
      if (previousHarmonyScore != null)
        'previousHarmonyScore': previousHarmonyScore,
      'calculationBreakdown': calculationBreakdown,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photos': photos
          .map((p) => p.toJson(includeLocalPaths: includeLocalPaths))
          .toList(),
      'customBackgroundPhotoId': customBackgroundPhotoId,
      'customIconPhotoId': customIconPhotoId,
      'bannerPhotoId': bannerPhotoId,
      'customIconCodePoint': customIconCodePoint,
      'waterParameters': waterParameters.map((wp) => wp.toJson()).toList(),
      'dosingEntries': dosingEntries.map((de) => de.toJson()).toList(),
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'notificationLogs': notificationLogs.map((nl) => nl.toJson()).toList(),
      'tankNotes': tankNotes.map((tn) => tn.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'memorializedInhabitants': memorializedInhabitants
          .map((i) => i.toJson(includeLocalPaths: includeLocalPaths))
          .toList(),
    };
  }

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isReef: json['isReef'] as bool? ?? false,
      freshwaterSubtype: json['freshwaterSubtype'] as String?,
      substrateOverrideLbs: json['substrateOverrideLbs']?.toDouble(),
      inhabitants: (json['inhabitants'] as List)
          .map((i) => TankInhabitant.fromJson(i))
          .toList(),
      sizeGallons: json['sizeGallons']?.toDouble(),
      sizeLiters: json['sizeLiters']?.toDouble(),
      notes: json['notes'] as String?,
      harmonyScore: json['harmonyScore']?.toDouble(),
      previousHarmonyScore: json['previousHarmonyScore']?.toDouble(),
      calculationBreakdown: json['calculationBreakdown'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      photos:
          (json['photos'] as List?)
              ?.map((p) => TankPhoto.fromJson(p))
              .toList() ??
          [],
      customBackgroundPhotoId: json['customBackgroundPhotoId'] as String?,
      customIconPhotoId: json['customIconPhotoId'] as String?,
      bannerPhotoId: json['bannerPhotoId'] as String?,
      customIconCodePoint: json['customIconCodePoint'] as int?,
      waterParameters:
          (json['waterParameters'] as List?)
              ?.map((wp) => WaterParameter.fromJson(wp))
              .toList() ??
          [],
      dosingEntries:
          (json['dosingEntries'] as List?)
              ?.map((de) => DosingEntry.fromJson(de))
              .toList() ??
          [],
      notifications:
          (json['notifications'] as List?)
              ?.map((n) => TankNotification.fromJson(n))
              .toList() ??
          [],
      notificationLogs:
          (json['notificationLogs'] as List?)
              ?.map((nl) => NotificationLog.fromJson(nl))
              .toList() ??
          [],
      tankNotes:
          (json['tankNotes'] as List?)
              ?.map((tn) => TankNote.fromJson(tn))
              .toList() ??
          [],
      tags:
          (json['tags'] as List?)?.map((t) => TankTag.fromJson(t)).toList() ??
          [],
      memorializedInhabitants: (json['memorializedInhabitants'] as List?)
             ?.map((i) => TankInhabitant.fromJson(i))
             .toList() ??
         [],
    );
  }

  Tank copyWith({
    String? id,
    String? name,
    String? type,
    bool? isReef,
    String? freshwaterSubtype,
    bool clearFreshwaterSubtype = false,
    double? substrateOverrideLbs,
    bool clearSubstrateOverrideLbs = false,
    List<TankInhabitant>? inhabitants,
    double? sizeGallons,
    double? sizeLiters,
    String? notes,
    double? harmonyScore,
    double? previousHarmonyScore,
    String? calculationBreakdown,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TankPhoto>? photos,
    String? customBackgroundPhotoId,
    String? customIconPhotoId,
    String? bannerPhotoId,
    int? customIconCodePoint,
    List<WaterParameter>? waterParameters,
    List<DosingEntry>? dosingEntries,
    List<TankNotification>? notifications,
    List<NotificationLog>? notificationLogs,
    List<TankNote>? tankNotes,
    List<TankTag>? tags,
    List<TankInhabitant>? memorializedInhabitants,
    bool clearCustomBackgroundPhotoId = false,
    bool clearCustomIconPhotoId = false,
    bool clearBannerPhotoId = false,
    bool clearCustomIconCodePoint = false,
  }) {
    return Tank(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isReef: isReef ?? this.isReef,
      freshwaterSubtype: clearFreshwaterSubtype
          ? null
          : (freshwaterSubtype ?? this.freshwaterSubtype),
      substrateOverrideLbs: clearSubstrateOverrideLbs
          ? null
          : (substrateOverrideLbs ?? this.substrateOverrideLbs),
      inhabitants: inhabitants ?? this.inhabitants,
      sizeGallons: sizeGallons ?? this.sizeGallons,
      sizeLiters: sizeLiters ?? this.sizeLiters,
      notes: notes ?? this.notes,
      harmonyScore: harmonyScore ?? this.harmonyScore,
      previousHarmonyScore: previousHarmonyScore ?? this.previousHarmonyScore,
      calculationBreakdown: calculationBreakdown ?? this.calculationBreakdown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      customBackgroundPhotoId: clearCustomBackgroundPhotoId
          ? null
          : (customBackgroundPhotoId ?? this.customBackgroundPhotoId),
      customIconPhotoId: clearCustomIconPhotoId
          ? null
          : (customIconPhotoId ?? this.customIconPhotoId),
      bannerPhotoId: clearBannerPhotoId
          ? null
          : (bannerPhotoId ?? this.bannerPhotoId),
      customIconCodePoint: clearCustomIconCodePoint
          ? null
          : (customIconCodePoint ?? this.customIconCodePoint),
      waterParameters: waterParameters ?? this.waterParameters,
      dosingEntries: dosingEntries ?? this.dosingEntries,
      notifications: notifications ?? this.notifications,
      notificationLogs: notificationLogs ?? this.notificationLogs,
      tankNotes: tankNotes ?? this.tankNotes,
      tags: tags ?? this.tags,
      memorializedInhabitants:
          memorializedInhabitants ?? this.memorializedInhabitants,
    );
  }
}
