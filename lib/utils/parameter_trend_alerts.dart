import '../models/water_parameter.dart';

const int _minTrendDaysForAlert = 5;
const int _maxDayGapForContinuousTrend = 2;

class ParameterTrendAlert {
  final String parameterType;
  final int trendDays;
  final double latestValue;
  final String? unit;

  const ParameterTrendAlert({
    required this.parameterType,
    required this.trendDays,
    required this.latestValue,
    this.unit,
  });
}

List<ParameterTrendAlert> buildProactiveParameterAlerts(
  List<WaterParameter> parameters,
) {
  final alerts = <ParameterTrendAlert>[];
  final nitrateAlert = _buildNitrateRisingAlert(parameters);
  if (nitrateAlert != null) {
    alerts.add(nitrateAlert);
  }
  return alerts;
}

ParameterTrendAlert? _buildNitrateRisingAlert(List<WaterParameter> parameters) {
  final nitrateReadings = parameters
      .where((p) => p.parameterType == 'nitrate')
      .toList()
    ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

  if (nitrateReadings.length < _minTrendDaysForAlert) {
    return null;
  }

  final risingStreak = <WaterParameter>[nitrateReadings.last];

  for (var i = nitrateReadings.length - 2; i >= 0; i--) {
    final older = nitrateReadings[i];
    final newer = risingStreak.first;
    final dayGap = newer.dateRecorded.difference(older.dateRecorded).inDays;

    final isRising = newer.value > older.value;
    final isReasonablyContinuous = dayGap <= _maxDayGapForContinuousTrend;

    if (isRising && isReasonablyContinuous) {
      risingStreak.insert(0, older);
      continue;
    }
    break;
  }

  if (risingStreak.length < _minTrendDaysForAlert) {
    return null;
  }

  final firstDate = risingStreak.first.dateRecorded;
  final lastDate = risingStreak.last.dateRecorded;
  final trendDays = lastDate.difference(firstDate).inDays + 1;

  if (trendDays < _minTrendDaysForAlert) {
    return null;
  }

  final latest = risingStreak.last;
  return ParameterTrendAlert(
    parameterType: 'nitrate',
    trendDays: trendDays,
    latestValue: latest.value,
    unit: latest.unit,
  );
}
