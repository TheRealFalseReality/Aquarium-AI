import 'package:uuid/uuid.dart';

/// A user-configurable dosing preset that stores bottle-readable dose amounts.
///
/// Example: Seachem Prime → 5 mL per 50 gallons / 5 mL per 200 L.
class DosingPreset {
  final String id;
  final String name;
  final double doseAmountGal;
  final double perVolumeGal;
  final double doseAmountLiter;
  final double perVolumeLiter;
  final String unit; // 'mL', 'g', etc.
  final String iconName; // Material icon name for serialization

  DosingPreset({
    required this.id,
    required this.name,
    required this.doseAmountGal,
    required this.perVolumeGal,
    required this.doseAmountLiter,
    required this.perVolumeLiter,
    this.unit = 'mL',
    this.iconName = 'science_outlined',
  });

  factory DosingPreset.create({
    required String name,
    required double doseAmountGal,
    required double perVolumeGal,
    required double doseAmountLiter,
    required double perVolumeLiter,
    String unit = 'mL',
    String iconName = 'science_outlined',
  }) {
    return DosingPreset(
      id: const Uuid().v4(),
      name: name,
      doseAmountGal: doseAmountGal,
      perVolumeGal: perVolumeGal,
      doseAmountLiter: doseAmountLiter,
      perVolumeLiter: perVolumeLiter,
      unit: unit,
      iconName: iconName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'doseAmountGal': doseAmountGal,
      'perVolumeGal': perVolumeGal,
      'doseAmountLiter': doseAmountLiter,
      'perVolumeLiter': perVolumeLiter,
      'unit': unit,
      'iconName': iconName,
    };
  }

  factory DosingPreset.fromJson(Map<String, dynamic> json) {
    return DosingPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      doseAmountGal: (json['doseAmountGal'] as num).toDouble(),
      perVolumeGal: (json['perVolumeGal'] as num).toDouble(),
      doseAmountLiter: (json['doseAmountLiter'] as num).toDouble(),
      perVolumeLiter: (json['perVolumeLiter'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'mL',
      iconName: json['iconName'] as String? ?? 'science_outlined',
    );
  }

  DosingPreset copyWith({
    String? id,
    String? name,
    double? doseAmountGal,
    double? perVolumeGal,
    double? doseAmountLiter,
    double? perVolumeLiter,
    String? unit,
    String? iconName,
  }) {
    return DosingPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      doseAmountGal: doseAmountGal ?? this.doseAmountGal,
      perVolumeGal: perVolumeGal ?? this.perVolumeGal,
      doseAmountLiter: doseAmountLiter ?? this.doseAmountLiter,
      perVolumeLiter: perVolumeLiter ?? this.perVolumeLiter,
      unit: unit ?? this.unit,
      iconName: iconName ?? this.iconName,
    );
  }

  /// The default presets that ship with the app.
  static List<DosingPreset> get defaultPresets => [
    DosingPreset(
      id: 'seachemPrime',
      name: 'Seachem Prime',
      doseAmountGal: 5,
      perVolumeGal: 50,
      doseAmountLiter: 5,
      perVolumeLiter: 200,
      unit: 'mL',
      iconName: 'shield_outlined',
    ),
    DosingPreset(
      id: 'seachemStability',
      name: 'Seachem Stability',
      doseAmountGal: 5,
      perVolumeGal: 50,
      doseAmountLiter: 5,
      perVolumeLiter: 200,
      unit: 'mL',
      iconName: 'science_outlined',
    ),
    DosingPreset(
      id: 'seachemFlourish',
      name: 'Seachem Flourish',
      doseAmountGal: 5,
      perVolumeGal: 50,
      doseAmountLiter: 5,
      perVolumeLiter: 200,
      unit: 'mL',
      iconName: 'grass_outlined',
    ),
    DosingPreset(
      id: 'seachemFlourishExcel',
      name: 'Seachem Flourish Excel',
      doseAmountGal: 5,
      perVolumeGal: 50,
      doseAmountLiter: 5,
      perVolumeLiter: 200,
      unit: 'mL',
      iconName: 'eco_outlined',
    ),
    DosingPreset(
      id: 'apiStressCoat',
      name: 'API Stress Coat',
      doseAmountGal: 5,
      perVolumeGal: 25,
      doseAmountLiter: 5,
      perVolumeLiter: 100,
      unit: 'mL',
      iconName: 'water_drop_outlined',
    ),
    DosingPreset(
      id: 'apiMelafix',
      name: 'API Melafix',
      doseAmountGal: 5,
      perVolumeGal: 10,
      doseAmountLiter: 5,
      perVolumeLiter: 38,
      unit: 'mL',
      iconName: 'healing_outlined',
    ),
    DosingPreset(
      id: 'apiPimafix',
      name: 'API Pimafix',
      doseAmountGal: 5,
      perVolumeGal: 10,
      doseAmountLiter: 5,
      perVolumeLiter: 38,
      unit: 'mL',
      iconName: 'local_pharmacy_outlined',
    ),
    DosingPreset(
      id: 'seachemAlkalineBuffer',
      name: 'Seachem Alkaline Buffer',
      doseAmountGal: 5,
      perVolumeGal: 70,
      doseAmountLiter: 5,
      perVolumeLiter: 265,
      unit: 'g',
      iconName: 'balance_outlined',
    ),
    DosingPreset(
      id: 'seachemAcidBuffer',
      name: 'Seachem Acid Buffer',
      doseAmountGal: 5,
      perVolumeGal: 70,
      doseAmountLiter: 5,
      perVolumeLiter: 265,
      unit: 'g',
      iconName: 'science_outlined',
    ),
    DosingPreset(
      id: 'fritzsoDechlorinator',
      name: 'Fritz SO Dechlorinator',
      doseAmountGal: 1,
      perVolumeGal: 5,
      doseAmountLiter: 5,
      perVolumeLiter: 95,
      unit: 'mL',
      iconName: 'cleaning_services_outlined',
    ),
  ];
}
