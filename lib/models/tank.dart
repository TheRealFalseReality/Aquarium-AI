import 'package:uuid/uuid.dart';
import 'water_parameter.dart';
import 'dosing_entry.dart';
import 'tank_notification.dart';
import 'notification_log.dart';
import 'tank_note.dart';

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
    return TankTag(
      name: map['name'] as String,
      color: map['color'] as int?,
    );
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
  final String fishUnit; // Matches fish name from fishcompat.json
  final int quantity;
  final String? customImageUrl; // User-provided image URL
  final String? customImagePath; // User-provided image file path (for local images)
  final DateTime? dateAdded; // Date when inhabitant was added to tank
  final List<String> speciesTags; // Selected species tags for more granular identification

  TankInhabitant({
    required this.id,
    required this.customName,
    required this.fishUnit,
    required this.quantity,
    this.customImageUrl,
    this.customImagePath,
    this.dateAdded,
    List<String>? speciesTags,
  }) : speciesTags = speciesTags ?? [];

  Map<String, dynamic> toJson({bool includeLocalPaths = true}) {
    return {
      'id': id,
      'customName': customName,
      'fishUnit': fishUnit,
      'quantity': quantity,
      'customImageUrl': customImageUrl,
      // Exclude customImagePath from backup to prevent restore errors
      if (includeLocalPaths && customImagePath != null) 'customImagePath': customImagePath,
      'dateAdded': dateAdded?.toIso8601String(),
      'speciesTags': speciesTags,
    };
  }

  factory TankInhabitant.fromJson(Map<String, dynamic> json) {
    return TankInhabitant(
      id: json['id'] as String,
      customName: json['customName'] as String,
      fishUnit: json['fishUnit'] as String,
      quantity: json['quantity'] as int,
      customImageUrl: json['customImageUrl'] as String?,
      customImagePath: json['customImagePath'] as String?,
      dateAdded: json['dateAdded'] != null 
          ? DateTime.parse(json['dateAdded'] as String)
          : null,
      speciesTags: (json['speciesTags'] as List?)
          ?.map((t) => t.toString())
          .toList() ?? [],
    );
  }

  TankInhabitant copyWith({
    String? id,
    String? customName,
    String? fishUnit,
    int? quantity,
    String? customImageUrl,
    String? customImagePath,
    DateTime? dateAdded,
    List<String>? speciesTags,
  }) {
    return TankInhabitant(
      id: id ?? this.id,
      customName: customName ?? this.customName,
      fishUnit: fishUnit ?? this.fishUnit,
      quantity: quantity ?? this.quantity,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      customImagePath: customImagePath ?? this.customImagePath,
      dateAdded: dateAdded ?? this.dateAdded,
      speciesTags: speciesTags ?? this.speciesTags,
    );
  }
}

class Tank {
  final String id;
  final String name;
  final String type; // 'freshwater' or 'marine'
  final bool isReef; // Only relevant when type == 'marine'
  final List<TankInhabitant> inhabitants;
  final double? sizeGallons; // Tank size in gallons
  final double? sizeLiters;  // Tank size in liters
  final String? notes; // User notes about the tank
  final double? harmonyScore; // Cached harmony score (0.0 to 1.0)
  final String? calculationBreakdown; // Cached calculation breakdown string
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TankPhoto> photos; // Photos of the tank (not fish)
  final String? customBackgroundPhotoId; // ID of photo to use as card background
  final String? customIconPhotoId; // ID of photo to use as tank icon
  final int? customIconCodePoint; // Custom icon code point for tank card
  final List<WaterParameter> waterParameters; // Water parameter logs
  final List<DosingEntry> dosingEntries; // Dosing diary entries
  final List<TankNotification> notifications; // Task notifications
  final List<NotificationLog> notificationLogs; // Notification action logs
  final List<TankNote> tankNotes; // User notes for the tank
  final List<TankTag> tags; // User-created tags for this tank

  Tank({
    required this.id,
    required this.name,
    required this.type,
    this.isReef = false,
    required this.inhabitants,
    this.sizeGallons,
    this.sizeLiters,
    this.notes,
    this.harmonyScore,
    this.calculationBreakdown,
    required this.createdAt,
    required this.updatedAt,
    List<TankPhoto>? photos,
    this.customBackgroundPhotoId,
    this.customIconPhotoId,
    this.customIconCodePoint,
    List<WaterParameter>? waterParameters,
    List<DosingEntry>? dosingEntries,
    List<TankNotification>? notifications,
    List<NotificationLog>? notificationLogs,
    List<TankNote>? tankNotes,
    List<TankTag>? tags,
  }) : photos = photos ?? [],
       waterParameters = waterParameters ?? [],
       dosingEntries = dosingEntries ?? [],
       notifications = notifications ?? [],
       notificationLogs = notificationLogs ?? [],
       tankNotes = tankNotes ?? [],
       tags = tags ?? [];

  factory Tank.create({
    required String name,
    required String type,
    bool isReef = false,
    List<TankInhabitant>? inhabitants,
    double? sizeGallons,
    double? sizeLiters,
    String? notes,
    double? harmonyScore,
    String? calculationBreakdown,
    DateTime? createdAt,
    List<TankPhoto>? photos,
    String? customBackgroundPhotoId,
    String? customIconPhotoId,
    int? customIconCodePoint,
    List<WaterParameter>? waterParameters,
    List<DosingEntry>? dosingEntries,
    List<TankNotification>? notifications,
    List<NotificationLog>? notificationLogs,
    List<TankNote>? tankNotes,
    List<TankTag>? tags,
  }) {
    final now = DateTime.now();
    return Tank(
      id: const Uuid().v4(),
      name: name,
      type: type,
      isReef: isReef,
      inhabitants: inhabitants ?? [],
      sizeGallons: sizeGallons,
      sizeLiters: sizeLiters,
      notes: notes,
      harmonyScore: harmonyScore,
      calculationBreakdown: calculationBreakdown,
      createdAt: createdAt ?? now,
      updatedAt: now,
      photos: photos,
      customBackgroundPhotoId: customBackgroundPhotoId,
      customIconPhotoId: customIconPhotoId,
      customIconCodePoint: customIconCodePoint,
      waterParameters: waterParameters,
      dosingEntries: dosingEntries,
      notifications: notifications,
      notificationLogs: notificationLogs,
      tankNotes: tankNotes,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson({bool includeLocalPaths = true}) {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isReef': isReef,
      'inhabitants': inhabitants.map((i) => i.toJson(includeLocalPaths: includeLocalPaths)).toList(),
      'sizeGallons': sizeGallons,
      'sizeLiters': sizeLiters,
      'notes': notes,
      'harmonyScore': harmonyScore,
      'calculationBreakdown': calculationBreakdown,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photos': photos.map((p) => p.toJson(includeLocalPaths: includeLocalPaths)).toList(),
      'customBackgroundPhotoId': customBackgroundPhotoId,
      'customIconPhotoId': customIconPhotoId,
      'customIconCodePoint': customIconCodePoint,
      'waterParameters': waterParameters.map((wp) => wp.toJson()).toList(),
      'dosingEntries': dosingEntries.map((de) => de.toJson()).toList(),
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'notificationLogs': notificationLogs.map((nl) => nl.toJson()).toList(),
      'tankNotes': tankNotes.map((tn) => tn.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
    };
  }

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isReef: json['isReef'] as bool? ?? false,
      inhabitants: (json['inhabitants'] as List)
          .map((i) => TankInhabitant.fromJson(i))
          .toList(),
      sizeGallons: json['sizeGallons']?.toDouble(),
      sizeLiters: json['sizeLiters']?.toDouble(),
      notes: json['notes'] as String?,
      harmonyScore: json['harmonyScore']?.toDouble(),
      calculationBreakdown: json['calculationBreakdown'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      photos: (json['photos'] as List?)
          ?.map((p) => TankPhoto.fromJson(p))
          .toList() ?? [],
      customBackgroundPhotoId: json['customBackgroundPhotoId'] as String?,
      customIconPhotoId: json['customIconPhotoId'] as String?,
      customIconCodePoint: json['customIconCodePoint'] as int?,
      waterParameters: (json['waterParameters'] as List?)
          ?.map((wp) => WaterParameter.fromJson(wp))
          .toList() ?? [],
      dosingEntries: (json['dosingEntries'] as List?)
          ?.map((de) => DosingEntry.fromJson(de))
          .toList() ?? [],
      notifications: (json['notifications'] as List?)
          ?.map((n) => TankNotification.fromJson(n))
          .toList() ?? [],
      notificationLogs: (json['notificationLogs'] as List?)
          ?.map((nl) => NotificationLog.fromJson(nl))
          .toList() ?? [],
      tankNotes: (json['tankNotes'] as List?)
          ?.map((tn) => TankNote.fromJson(tn))
          .toList() ?? [],
      tags: (json['tags'] as List?)
          ?.map((t) => TankTag.fromJson(t))
          .toList() ?? [],
    );
  }

  Tank copyWith({
    String? id,
    String? name,
    String? type,
    bool? isReef,
    List<TankInhabitant>? inhabitants,
    double? sizeGallons,
    double? sizeLiters,
    String? notes,
    double? harmonyScore,
    String? calculationBreakdown,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TankPhoto>? photos,
    String? customBackgroundPhotoId,
    String? customIconPhotoId,
    int? customIconCodePoint,
    List<WaterParameter>? waterParameters,
    List<DosingEntry>? dosingEntries,
    List<TankNotification>? notifications,
    List<NotificationLog>? notificationLogs,
    List<TankNote>? tankNotes,
    List<TankTag>? tags,
    bool clearCustomBackgroundPhotoId = false,
    bool clearCustomIconPhotoId = false,
    bool clearCustomIconCodePoint = false,
  }) {
    return Tank(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isReef: isReef ?? this.isReef,
      inhabitants: inhabitants ?? this.inhabitants,
      sizeGallons: sizeGallons ?? this.sizeGallons,
      sizeLiters: sizeLiters ?? this.sizeLiters,
      notes: notes ?? this.notes,
      harmonyScore: harmonyScore ?? this.harmonyScore,
      calculationBreakdown: calculationBreakdown ?? this.calculationBreakdown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      customBackgroundPhotoId: clearCustomBackgroundPhotoId ? null : (customBackgroundPhotoId ?? this.customBackgroundPhotoId),
      customIconPhotoId: clearCustomIconPhotoId ? null : (customIconPhotoId ?? this.customIconPhotoId),
      customIconCodePoint: clearCustomIconCodePoint ? null : (customIconCodePoint ?? this.customIconCodePoint),
      waterParameters: waterParameters ?? this.waterParameters,
      dosingEntries: dosingEntries ?? this.dosingEntries,
      notifications: notifications ?? this.notifications,
      notificationLogs: notificationLogs ?? this.notificationLogs,
      tankNotes: tankNotes ?? this.tankNotes,
      tags: tags ?? this.tags,
    );
  }
}
