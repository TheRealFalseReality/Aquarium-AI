import 'package:uuid/uuid.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
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

  TankInhabitant({
    required this.id,
    required this.customName,
    required this.fishUnit,
    required this.quantity,
    this.customImageUrl,
    this.customImagePath,
    this.dateAdded,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customName': customName,
      'fishUnit': fishUnit,
      'quantity': quantity,
      'customImageUrl': customImageUrl,
      'customImagePath': customImagePath,
      'dateAdded': dateAdded?.toIso8601String(),
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
  }) {
    return TankInhabitant(
      id: id ?? this.id,
      customName: customName ?? this.customName,
      fishUnit: fishUnit ?? this.fishUnit,
      quantity: quantity ?? this.quantity,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      customImagePath: customImagePath ?? this.customImagePath,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}

class Tank {
  final String id;
  final String name;
  final String type; // 'freshwater' or 'marine'
  final List<TankInhabitant> inhabitants;
  final double? sizeGallons; // Tank size in gallons
  final double? sizeLiters;  // Tank size in liters
  final String? notes; // User notes about the tank
  final double? harmonyScore; // Cached harmony score (0.0 to 1.0)
  final String? calculationBreakdown; // Cached calculation breakdown string
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TankPhoto> photos; // Photos of the tank (not fish)

  Tank({
    required this.id,
    required this.name,
    required this.type,
    required this.inhabitants,
    this.sizeGallons,
    this.sizeLiters,
    this.notes,
    this.harmonyScore,
    this.calculationBreakdown,
    required this.createdAt,
    required this.updatedAt,
    List<TankPhoto>? photos,
  }) : photos = photos ?? [];

  factory Tank.create({
    required String name,
    required String type,
    List<TankInhabitant>? inhabitants,
    double? sizeGallons,
    double? sizeLiters,
    String? notes,
    double? harmonyScore,
    String? calculationBreakdown,
    DateTime? createdAt,
    List<TankPhoto>? photos,
  }) {
    final now = DateTime.now();
    return Tank(
      id: const Uuid().v4(),
      name: name,
      type: type,
      inhabitants: inhabitants ?? [],
      sizeGallons: sizeGallons,
      sizeLiters: sizeLiters,
      notes: notes,
      harmonyScore: harmonyScore,
      calculationBreakdown: calculationBreakdown,
      createdAt: createdAt ?? now,
      updatedAt: now,
      photos: photos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'inhabitants': inhabitants.map((i) => i.toJson()).toList(),
      'sizeGallons': sizeGallons,
      'sizeLiters': sizeLiters,
      'notes': notes,
      'harmonyScore': harmonyScore,
      'calculationBreakdown': calculationBreakdown,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photos': photos.map((p) => p.toJson()).toList(),
    };
  }

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
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
    );
  }

  Tank copyWith({
    String? id,
    String? name,
    String? type,
    List<TankInhabitant>? inhabitants,
    double? sizeGallons,
    double? sizeLiters,
    String? notes,
    double? harmonyScore,
    String? calculationBreakdown,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TankPhoto>? photos,
  }) {
    return Tank(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      inhabitants: inhabitants ?? this.inhabitants,
      sizeGallons: sizeGallons ?? this.sizeGallons,
      sizeLiters: sizeLiters ?? this.sizeLiters,
      notes: notes ?? this.notes,
      harmonyScore: harmonyScore ?? this.harmonyScore,
      calculationBreakdown: calculationBreakdown ?? this.calculationBreakdown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
    );
  }
}