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

  // Normalize to one reading per calendar day (latest reading for that day) so
  // intra-day fluctuations do not break day-over-day trend analysis.
  final dailyReadingsByDate = <DateTime, WaterParameter>{};
  for (final reading in nitrateReadings) {
    final calendarDay = DateTime(
      reading.dateRecorded.year,
      reading.dateRecorded.month,
      reading.dateRecorded.day,
    );
    final existing = dailyReadingsByDate[calendarDay];
    if (existing == null || reading.dateRecorded.isAfter(existing.dateRecorded)) {
      dailyReadingsByDate[calendarDay] = reading;
    }
  }

  final dailyReadings = dailyReadingsByDate.values.toList()
    ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

  final risingStreak = <WaterParameter>[dailyReadings.last];

  for (var i = dailyReadings.length - 2; i >= 0; i--) {
    final older = dailyReadings[i];
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

  final latest = risingStreak.last;
  return ParameterTrendAlert(
    parameterType: 'nitrate',
    trendDays: risingStreak.length,
    latestValue: latest.value,
    unit: latest.unit,
  );
}
