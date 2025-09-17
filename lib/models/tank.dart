import 'package:uuid/uuid.dart';

class TankInhabitant {
  final String id;
  final String customName;
  final String fishUnit; // Matches fish name from fishcompat.json
  final int quantity;

  TankInhabitant({
    required this.id,
    required this.customName,
    required this.fishUnit,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customName': customName,
      'fishUnit': fishUnit,
      'quantity': quantity,
    };
  }

  factory TankInhabitant.fromJson(Map<String, dynamic> json) {
    return TankInhabitant(
      id: json['id'] as String,
      customName: json['customName'] as String,
      fishUnit: json['fishUnit'] as String,
      quantity: json['quantity'] as int,
    );
  }

  TankInhabitant copyWith({
    String? id,
    String? customName,
    String? fishUnit,
    int? quantity,
  }) {
    return TankInhabitant(
      id: id ?? this.id,
      customName: customName ?? this.customName,
      fishUnit: fishUnit ?? this.fishUnit,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Tank {
  final String id;
  final String name;
  final String type; // 'freshwater' or 'marine'
  final List<TankInhabitant> inhabitants;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tank({
    required this.id,
    required this.name,
    required this.type,
    required this.inhabitants,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tank.create({
    required String name,
    required String type,
    List<TankInhabitant>? inhabitants,
  }) {
    final now = DateTime.now();
    return Tank(
      id: const Uuid().v4(),
      name: name,
      type: type,
      inhabitants: inhabitants ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'inhabitants': inhabitants.map((i) => i.toJson()).toList(),
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Tank copyWith({
    String? id,
    String? name,
    String? type,
    List<TankInhabitant>? inhabitants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tank(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      inhabitants: inhabitants ?? this.inhabitants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}