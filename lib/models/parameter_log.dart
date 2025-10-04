import 'package:uuid/uuid.dart';

class ParameterLog {
  final String id;
  final DateTime dateRecorded;
  final double? ammonia; // ppm
  final double? nitrite; // ppm
  final double? nitrate; // ppm
  final double? phosphate; // ppm
  final double? pH;
  final double? salinity; // ppt or SG
  final bool isSalinitySg; // true if salinity is in SG, false if in ppt
  final String? notes;

  ParameterLog({
    required this.id,
    required this.dateRecorded,
    this.ammonia,
    this.nitrite,
    this.nitrate,
    this.phosphate,
    this.pH,
    this.salinity,
    this.isSalinitySg = false,
    this.notes,
  });

  factory ParameterLog.create({
    required DateTime dateRecorded,
    double? ammonia,
    double? nitrite,
    double? nitrate,
    double? phosphate,
    double? pH,
    double? salinity,
    bool isSalinitySg = false,
    String? notes,
  }) {
    return ParameterLog(
      id: const Uuid().v4(),
      dateRecorded: dateRecorded,
      ammonia: ammonia,
      nitrite: nitrite,
      nitrate: nitrate,
      phosphate: phosphate,
      pH: pH,
      salinity: salinity,
      isSalinitySg: isSalinitySg,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateRecorded': dateRecorded.toIso8601String(),
      'ammonia': ammonia,
      'nitrite': nitrite,
      'nitrate': nitrate,
      'phosphate': phosphate,
      'pH': pH,
      'salinity': salinity,
      'isSalinitySg': isSalinitySg,
      'notes': notes,
    };
  }

  factory ParameterLog.fromJson(Map<String, dynamic> json) {
    return ParameterLog(
      id: json['id'] as String,
      dateRecorded: DateTime.parse(json['dateRecorded'] as String),
      ammonia: json['ammonia']?.toDouble(),
      nitrite: json['nitrite']?.toDouble(),
      nitrate: json['nitrate']?.toDouble(),
      phosphate: json['phosphate']?.toDouble(),
      pH: json['pH']?.toDouble(),
      salinity: json['salinity']?.toDouble(),
      isSalinitySg: json['isSalinitySg'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  ParameterLog copyWith({
    String? id,
    DateTime? dateRecorded,
    double? ammonia,
    double? nitrite,
    double? nitrate,
    double? phosphate,
    double? pH,
    double? salinity,
    bool? isSalinitySg,
    String? notes,
    bool clearAmmonia = false,
    bool clearNitrite = false,
    bool clearNitrate = false,
    bool clearPhosphate = false,
    bool clearPH = false,
    bool clearSalinity = false,
    bool clearNotes = false,
  }) {
    return ParameterLog(
      id: id ?? this.id,
      dateRecorded: dateRecorded ?? this.dateRecorded,
      ammonia: clearAmmonia ? null : (ammonia ?? this.ammonia),
      nitrite: clearNitrite ? null : (nitrite ?? this.nitrite),
      nitrate: clearNitrate ? null : (nitrate ?? this.nitrate),
      phosphate: clearPhosphate ? null : (phosphate ?? this.phosphate),
      pH: clearPH ? null : (pH ?? this.pH),
      salinity: clearSalinity ? null : (salinity ?? this.salinity),
      isSalinitySg: isSalinitySg ?? this.isSalinitySg,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  bool get hasAnyParameter =>
      ammonia != null ||
      nitrite != null ||
      nitrate != null ||
      phosphate != null ||
      pH != null ||
      salinity != null;
}
