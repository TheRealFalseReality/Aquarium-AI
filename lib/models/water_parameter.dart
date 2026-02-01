import 'package:uuid/uuid.dart';

class WaterParameter {
  final String id;
  final String parameterType; // 'ammonia', 'nitrite', 'nitrate', 'phosphate', 'salinity'
  final double value;
  final String? unit; // Optional unit like 'ppm', 'ppt', etc.
  final DateTime dateRecorded;
  final String? notes;

  WaterParameter({
    required this.id,
    required this.parameterType,
    required this.value,
    this.unit,
    required this.dateRecorded,
    this.notes,
  });

  factory WaterParameter.create({
    required String parameterType,
    required double value,
    String? unit,
    DateTime? dateRecorded,
    String? notes,
  }) {
    return WaterParameter(
      id: const Uuid().v4(),
      parameterType: parameterType,
      value: value,
      unit: unit,
      dateRecorded: dateRecorded ?? DateTime.now(),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parameterType': parameterType,
      'value': value,
      'unit': unit,
      'dateRecorded': dateRecorded.toIso8601String(),
      'notes': notes,
    };
  }

  factory WaterParameter.fromJson(Map<String, dynamic> json) {
    return WaterParameter(
      id: json['id'] as String,
      parameterType: json['parameterType'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      dateRecorded: DateTime.parse(json['dateRecorded'] as String),
      notes: json['notes'] as String?,
    );
  }

  WaterParameter copyWith({
    String? id,
    String? parameterType,
    double? value,
    String? unit,
    DateTime? dateRecorded,
    String? notes,
  }) {
    return WaterParameter(
      id: id ?? this.id,
      parameterType: parameterType ?? this.parameterType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      dateRecorded: dateRecorded ?? this.dateRecorded,
      notes: notes ?? this.notes,
    );
  }
}

