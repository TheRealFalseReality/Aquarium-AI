import '../models/water_parameter.dart';

/// Severity level for a parameter reading.
enum ParameterStatus {
  /// Value is within the ideal range.
  normal,

  /// Value is slightly outside the ideal range (mild concern).
  caution,

  /// Value is moderately outside the ideal range.
  warning,

  /// Value is far outside the ideal range (urgent action needed).
  critical,
}

/// An out-of-range alert for a single parameter type based on its latest
/// recorded reading.
class ParameterRangeAlert {
  final String parameterType;
  final double value;
  final String? unit;
  final ParameterStatus status;

  const ParameterRangeAlert({
    required this.parameterType,
    required this.value,
    this.unit,
    required this.status,
  });
}

/// Returns the [ParameterStatus] for the given [parameterType] value.
///
/// Thresholds mirror the colour bands used in [_getThresholdColor] in
/// `parameter_logger_screen.dart`.  Custom / unknown parameter types always
/// return [ParameterStatus.normal] because no reference range is available.
ParameterStatus getParameterStatus(
  String parameterType,
  double value, {
  String? unit,
}) {
  switch (parameterType) {
    case 'ammonia':
      if (value == 0) return ParameterStatus.normal;
      if (value <= 1) return ParameterStatus.caution;
      if (value < 4) return ParameterStatus.warning;
      return ParameterStatus.critical;

    case 'nitrite':
      if (value == 0) return ParameterStatus.normal;
      if (value <= 1) return ParameterStatus.caution;
      if (value < 2) return ParameterStatus.warning;
      return ParameterStatus.critical;

    case 'nitrate':
      if (value <= 5) return ParameterStatus.normal;
      if (value <= 40) return ParameterStatus.caution;
      return ParameterStatus.warning;

    case 'phosphate':
      if (value == 0) return ParameterStatus.normal;
      if (value < 1) return ParameterStatus.caution;
      if (value < 5) return ParameterStatus.warning;
      return ParameterStatus.critical;

    case 'salinity':
      final isSG = unit == 'SG';
      if (isSG) {
        if (value >= 1.023 && value <= 1.025) return ParameterStatus.normal;
        if (value >= 1.021 && value <= 1.027) return ParameterStatus.caution;
        if (value >= 1.019 && value <= 1.029) return ParameterStatus.warning;
        return ParameterStatus.critical;
      } else {
        if (value >= 32 && value <= 35) return ParameterStatus.normal;
        if ((value >= 31 && value < 32) || (value > 35 && value <= 36)) {
          return ParameterStatus.caution;
        }
        if ((value >= 29 && value < 31) || (value > 36 && value <= 38)) {
          return ParameterStatus.warning;
        }
        return ParameterStatus.critical;
      }

    case 'calcium':
      if (value >= 400 && value <= 450) return ParameterStatus.normal;
      if ((value >= 380 && value < 400) || (value > 450 && value <= 480)) {
        return ParameterStatus.caution;
      }
      if ((value >= 350 && value < 380) || (value > 480 && value <= 520)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'magnesium':
      if (value >= 1250 && value <= 1350) return ParameterStatus.normal;
      if ((value >= 1200 && value < 1250) ||
          (value > 1350 && value <= 1400)) {
        return ParameterStatus.caution;
      }
      if ((value >= 1100 && value < 1200) ||
          (value > 1400 && value <= 1500)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'kh':
      if (value >= 4 && value <= 8) return ParameterStatus.normal;
      if ((value >= 3 && value < 4) || (value > 8 && value <= 10)) {
        return ParameterStatus.caution;
      }
      if ((value >= 2 && value < 3) || (value > 10 && value <= 12)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'gh':
      if (value >= 4 && value <= 12) return ParameterStatus.normal;
      if ((value >= 3 && value < 4) || (value > 12 && value <= 15)) {
        return ParameterStatus.caution;
      }
      if ((value >= 2 && value < 3) || (value > 15 && value <= 18)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'alkalinity':
      if (value >= 2.5 && value <= 4.0) return ParameterStatus.normal;
      if ((value >= 2.0 && value < 2.5) || (value > 4.0 && value <= 5.0)) {
        return ParameterStatus.caution;
      }
      if ((value >= 1.5 && value < 2.0) || (value > 5.0 && value <= 6.0)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'orp':
      if (value >= 300 && value <= 450) return ParameterStatus.normal;
      if ((value >= 250 && value < 300) || (value > 450 && value <= 500)) {
        return ParameterStatus.caution;
      }
      if ((value >= 200 && value < 250) || (value > 500 && value <= 550)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'ph':
      if (value >= 6.8 && value <= 7.8) return ParameterStatus.normal;
      if ((value >= 6.5 && value < 6.8) || (value > 7.8 && value <= 8.2)) {
        return ParameterStatus.caution;
      }
      if ((value >= 6.0 && value < 6.5) || (value > 8.2 && value <= 8.5)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'potassium':
      if (value >= 10 && value <= 30) return ParameterStatus.normal;
      if ((value >= 5 && value < 10) || (value > 30 && value <= 40)) {
        return ParameterStatus.caution;
      }
      if ((value >= 2 && value < 5) || (value > 40 && value <= 50)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'tds':
      if (value >= 150 && value <= 250) return ParameterStatus.normal;
      if ((value >= 100 && value < 150) || (value > 250 && value <= 350)) {
        return ParameterStatus.caution;
      }
      if ((value >= 50 && value < 100) || (value > 350 && value <= 450)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'iodine':
      if (value >= 0.06 && value <= 0.10) return ParameterStatus.normal;
      if ((value >= 0.04 && value < 0.06) ||
          (value > 0.10 && value <= 0.12)) {
        return ParameterStatus.caution;
      }
      if ((value >= 0.02 && value < 0.04) ||
          (value > 0.12 && value <= 0.15)) {
        return ParameterStatus.warning;
      }
      return ParameterStatus.critical;

    case 'temperature':
      final isFahrenheit = unit == '°F';
      if (isFahrenheit) {
        if (value >= 76 && value <= 80) return ParameterStatus.normal;
        if ((value >= 72 && value < 76) || (value > 80 && value <= 84)) {
          return ParameterStatus.caution;
        }
        if ((value >= 68 && value < 72) || (value > 84 && value <= 88)) {
          return ParameterStatus.warning;
        }
        return ParameterStatus.critical;
      } else {
        if (value >= 24 && value <= 27) return ParameterStatus.normal;
        if ((value >= 22 && value < 24) || (value > 27 && value <= 29)) {
          return ParameterStatus.caution;
        }
        if ((value >= 20 && value < 22) || (value > 29 && value <= 31)) {
          return ParameterStatus.warning;
        }
        return ParameterStatus.critical;
      }

    default:
      // Custom parameters have no known reference range.
      return ParameterStatus.normal;
  }
}

/// Inspects [parameters], takes the **latest reading per parameter type**, and
/// returns [ParameterRangeAlert]s for every type whose latest reading is not
/// [ParameterStatus.normal].
///
/// Results are sorted from most-severe to least-severe.
List<ParameterRangeAlert> buildCurrentOutOfRangeAlerts(
  List<WaterParameter> parameters,
) {
  // Keep only the most recent reading per parameter type.
  // When two readings share the same timestamp, prefer the one with the
  // lexicographically larger UUID (deterministic tiebreaker).
  final latestByType = <String, WaterParameter>{};
  for (final p in parameters) {
    final existing = latestByType[p.parameterType];
    if (existing == null ||
        p.dateRecorded.isAfter(existing.dateRecorded) ||
        (p.dateRecorded == existing.dateRecorded &&
            p.id.compareTo(existing.id) > 0)) {
      latestByType[p.parameterType] = p;
    }
  }

  final alerts = <ParameterRangeAlert>[];
  for (final p in latestByType.values) {
    final status = getParameterStatus(p.parameterType, p.value, unit: p.unit);
    if (status != ParameterStatus.normal) {
      alerts.add(
        ParameterRangeAlert(
          parameterType: p.parameterType,
          value: p.value,
          unit: p.unit,
          status: status,
        ),
      );
    }
  }

  // Sort: critical → warning → caution.
  alerts.sort((a, b) => b.status.index.compareTo(a.status.index));
  return alerts;
}
