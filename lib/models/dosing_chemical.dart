import 'package:uuid/uuid.dart';

class DosingChemical {
  final String id;
  final String name;
  final double amountPerUnit;
  final String perUnit; // gallon | liter
  final String doseUnit; // mL, drops, tsp, etc.

  const DosingChemical({
    required this.id,
    required this.name,
    required this.amountPerUnit,
    required this.perUnit,
    required this.doseUnit,
  });

  factory DosingChemical.create({
    required String name,
    required double amountPerUnit,
    required String perUnit,
    String doseUnit = 'mL',
  }) {
    return DosingChemical(
      id: const Uuid().v4(),
      name: name,
      amountPerUnit: amountPerUnit,
      perUnit: perUnit,
      doseUnit: doseUnit,
    );
  }

  DosingChemical copyWith({
    String? id,
    String? name,
    double? amountPerUnit,
    String? perUnit,
    String? doseUnit,
  }) {
    return DosingChemical(
      id: id ?? this.id,
      name: name ?? this.name,
      amountPerUnit: amountPerUnit ?? this.amountPerUnit,
      perUnit: perUnit ?? this.perUnit,
      doseUnit: doseUnit ?? this.doseUnit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amountPerUnit': amountPerUnit,
      'perUnit': perUnit,
      'doseUnit': doseUnit,
    };
  }

  factory DosingChemical.fromJson(Map<String, dynamic> json) {
    return DosingChemical(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      name: json['name'] as String,
      amountPerUnit: (json['amountPerUnit'] as num).toDouble(),
      perUnit: json['perUnit'] as String,
      doseUnit: (json['doseUnit'] as String?) ?? 'mL',
    );
  }
}
