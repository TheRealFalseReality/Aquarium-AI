import 'package:fish_ai/models/water_parameter.dart';
import 'package:fish_ai/utils/parameter_trend_alerts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildProactiveParameterAlerts', () {
    test('returns nitrate alert when nitrate rises for at least 5 days', () {
      final base = DateTime(2026, 1, 1);
      final alerts = buildProactiveParameterAlerts([
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 5,
          unit: 'ppm',
          dateRecorded: base,
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 8,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 1)),
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 10,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 2)),
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 13,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 3)),
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 16,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 4)),
        ),
      ]);

      expect(alerts, hasLength(1));
      expect(alerts.first.parameterType, 'nitrate');
      expect(alerts.first.trendDays, 5);
      expect(alerts.first.latestValue, 16);
      expect(alerts.first.unit, 'ppm');
    });

    test('returns no alert when nitrate does not rise continuously', () {
      final base = DateTime(2026, 1, 1);
      final alerts = buildProactiveParameterAlerts([
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 5,
          unit: 'ppm',
          dateRecorded: base,
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 8,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 1)),
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 7,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 2)),
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 9,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 3)),
        ),
        WaterParameter.create(
          parameterType: 'nitrate',
          value: 10,
          unit: 'ppm',
          dateRecorded: base.add(const Duration(days: 4)),
        ),
      ]);

      expect(alerts, isEmpty);
    });
  });
}
