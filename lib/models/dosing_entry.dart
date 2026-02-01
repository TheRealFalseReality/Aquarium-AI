import 'package:uuid/uuid.dart';

class DosingEntry {
  final String id;
  final String treatmentName; // Name of the treatment/product dosed
  final double amount; // Amount of treatment applied
  final String unit; // Volume unit (mL, L, oz, tsp, tbsp, drops, etc.)
  final DateTime dateDosed; // Date when treatment was applied
  final String? notes; // Optional notes about the dosing

  DosingEntry({
    required this.id,
    required this.treatmentName,
    required this.amount,
    required this.unit,
    required this.dateDosed,
    this.notes,
  });

  factory DosingEntry.create({
    required String treatmentName,
    required double amount,
    String unit = 'mL',
    DateTime? dateDosed,
    String? notes,
  }) {
    return DosingEntry(
      id: const Uuid().v4(),
      treatmentName: treatmentName,
      amount: amount,
      unit: unit,
      dateDosed: dateDosed ?? DateTime.now(),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treatmentName': treatmentName,
      'amount': amount,
      'unit': unit,
      'dateDosed': dateDosed.toIso8601String(),
      'notes': notes,
    };
  }

  factory DosingEntry.fromJson(Map<String, dynamic> json) {
    return DosingEntry(
      id: json['id'] as String,
      treatmentName: json['treatmentName'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      dateDosed: DateTime.parse(json['dateDosed'] as String),
      notes: json['notes'] as String?,
    );
  }

  DosingEntry copyWith({
    String? id,
    String? treatmentName,
    double? amount,
    String? unit,
    DateTime? dateDosed,
    String? notes,
  }) {
    return DosingEntry(
      id: id ?? this.id,
      treatmentName: treatmentName ?? this.treatmentName,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      dateDosed: dateDosed ?? this.dateDosed,
      notes: notes ?? this.notes,
    );
  }
}

