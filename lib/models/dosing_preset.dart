/// Sentinel value used by chemical dropdowns to represent "Add New Chemical".
/// Selecting this navigates to [ChemicalManagementScreen].
const String kAddChemicalSentinel = '__add_new_chemical__';

/// Data class for a single aquarium chemical with its typical dosing rate.
class DosingPreset {
  final String name;

  /// Typical dose amount. Null means no standard rate is available.
  final double? doseAmount;

  /// Unit for the dose (e.g. 'mL'). Null means no standard rate is available.
  final String? doseUnit;

  /// Reference volume in gallons this dose applies to.
  /// Null means no standard rate is available.
  final double? perGallons;

  const DosingPreset({
    required this.name,
    this.doseAmount,
    this.doseUnit,
    this.perGallons,
  });

  DosingPreset copyWith({
    String? name,
    double? doseAmount,
    String? doseUnit,
    double? perGallons,
  }) {
    return DosingPreset(
      name: name ?? this.name,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      perGallons: perGallons ?? this.perGallons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (doseAmount != null) 'doseAmount': doseAmount,
      if (doseUnit != null) 'doseUnit': doseUnit,
      if (perGallons != null) 'perGallons': perGallons,
    };
  }

  factory DosingPreset.fromJson(Map<String, dynamic> json) {
    return DosingPreset(
      name: json['name'] as String,
      doseAmount: (json['doseAmount'] as num?)?.toDouble(),
      doseUnit: json['doseUnit'] as String?,
      perGallons: (json['perGallons'] as num?)?.toDouble(),
    );
  }
}

/// Built-in default aquarium chemicals with typical maintenance dosing rates.
/// Entries with null rates have no universally agreed standard dose.
const List<DosingPreset> kDefaultDosingPresets = [
  DosingPreset(name: 'Prime (Seachem)', doseAmount: 1, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Stability (Seachem)', doseAmount: 5, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Flourish (Seachem)', doseAmount: 5, doseUnit: 'mL', perGallons: 60),
  DosingPreset(name: 'Excel (Seachem)', doseAmount: 5, doseUnit: 'mL', perGallons: 50),
  DosingPreset(name: 'Stress Coat (API)', doseAmount: 5, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Quick Start (API)', doseAmount: 10, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Stress Zyme (API)', doseAmount: 10, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Ich-X', doseAmount: 5, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Paraguard (Seachem)', doseAmount: 5, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Kanaplex (Seachem)'),
  DosingPreset(name: 'MetroPlex (Seachem)'),
  DosingPreset(name: 'Focus (Seachem)'),
  DosingPreset(name: 'AmGuard (Seachem)', doseAmount: 1, doseUnit: 'mL', perGallons: 20),
  DosingPreset(name: 'Safe (Seachem)'),
  DosingPreset(name: 'Purigen (Seachem)'),
  DosingPreset(name: 'Fritz Complete', doseAmount: 1, doseUnit: 'mL', perGallons: 10),
  DosingPreset(name: 'Alkalinity Buffer'),
  DosingPreset(name: 'pH Buffer'),
];
