import 'package:uuid/uuid.dart';

class TankInhabitant {
  final String id;
  final String customName;
  final String fishUnit; // Matches fish name from fishcompat.json
  final int quantity;
  final String? customImageUrl; // User-provided image URL
  final String? customImagePath; // User-provided image file path (for local images)

  TankInhabitant({
    required this.id,
    required this.customName,
    required this.fishUnit,
    required this.quantity,
    this.customImageUrl,
    this.customImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customName': customName,
      'fishUnit': fishUnit,
      'quantity': quantity,
      'customImageUrl': customImageUrl,
      'customImagePath': customImagePath,
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
    );
  }

  TankInhabitant copyWith({
    String? id,
    String? customName,
    String? fishUnit,
    int? quantity,
    String? customImageUrl,
    String? customImagePath,
  }) {
    return TankInhabitant(
      id: id ?? this.id,
      customName: customName ?? this.customName,
      fishUnit: fishUnit ?? this.fishUnit,
      quantity: quantity ?? this.quantity,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      customImagePath: customImagePath ?? this.customImagePath,
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
  final List<String> tags; // User-created tags for organizing/searching tanks
  final DateTime createdAt;
  final DateTime updatedAt;

  Tank({
    required this.id,
    required this.name,
    required this.type,
    required this.inhabitants,
    this.sizeGallons,
    this.sizeLiters,
    this.notes,
    this.harmonyScore,
    List<String>? tags,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = tags ?? [];

  factory Tank.create({
    required String name,
    required String type,
    List<TankInhabitant>? inhabitants,
    double? sizeGallons,
    double? sizeLiters,
    String? notes,
    double? harmonyScore,
    List<String>? tags,
    DateTime? createdAt,
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
      tags: tags,
      createdAt: createdAt ?? now,
      updatedAt: now,
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
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}