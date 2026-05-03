import 'package:fish_ai/models/water_parameter.dart';
import 'package:fish_ai/utils/parameter_range_alerts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // getParameterStatus – threshold coverage
  // ---------------------------------------------------------------------------
  group('getParameterStatus', () {
    group('ammonia', () {
      test('returns normal when value is 0', () {
        expect(
          getParameterStatus('ammonia', 0),
          ParameterStatus.normal,
        );
      });
      test('returns caution when 0 < value <= 1', () {
        expect(getParameterStatus('ammonia', 0.5), ParameterStatus.caution);
        expect(getParameterStatus('ammonia', 1.0), ParameterStatus.caution);
      });
      test('returns warning when 1 < value < 4', () {
        expect(getParameterStatus('ammonia', 2.0), ParameterStatus.warning);
        expect(getParameterStatus('ammonia', 3.9), ParameterStatus.warning);
      });
      test('returns critical when value >= 4', () {
        expect(getParameterStatus('ammonia', 4.0), ParameterStatus.critical);
        expect(getParameterStatus('ammonia', 10.0), ParameterStatus.critical);
      });
    });

    group('nitrite', () {
      test('returns normal when value is 0', () {
        expect(getParameterStatus('nitrite', 0), ParameterStatus.normal);
      });
      test('returns caution when 0 < value <= 1', () {
        expect(getParameterStatus('nitrite', 1.0), ParameterStatus.caution);
      });
      test('returns warning when 1 < value < 2', () {
        expect(getParameterStatus('nitrite', 1.5), ParameterStatus.warning);
      });
      test('returns critical when value >= 2', () {
        expect(getParameterStatus('nitrite', 2.0), ParameterStatus.critical);
      });
    });

    group('nitrate', () {
      test('returns normal when value <= 5', () {
        expect(getParameterStatus('nitrate', 5.0), ParameterStatus.normal);
      });
      test('returns caution when 5 < value <= 40', () {
        expect(getParameterStatus('nitrate', 20.0), ParameterStatus.caution);
        expect(getParameterStatus('nitrate', 40.0), ParameterStatus.caution);
      });
      test('returns warning when value > 40', () {
        expect(getParameterStatus('nitrate', 41.0), ParameterStatus.warning);
      });
    });

    group('ph', () {
      test('returns normal in ideal range 6.8–7.8', () {
        expect(getParameterStatus('ph', 7.0), ParameterStatus.normal);
        expect(getParameterStatus('ph', 6.8), ParameterStatus.normal);
        expect(getParameterStatus('ph', 7.8), ParameterStatus.normal);
      });
      test('returns caution just outside ideal', () {
        expect(getParameterStatus('ph', 6.5), ParameterStatus.caution);
        expect(getParameterStatus('ph', 8.0), ParameterStatus.caution);
      });
      test('returns warning further outside', () {
        expect(getParameterStatus('ph', 6.2), ParameterStatus.warning);
        expect(getParameterStatus('ph', 8.3), ParameterStatus.warning);
      });
      test('returns critical beyond warning range', () {
        expect(getParameterStatus('ph', 5.0), ParameterStatus.critical);
        expect(getParameterStatus('ph', 9.0), ParameterStatus.critical);
      });
    });

    group('temperature – unit-sensitive', () {
      test('Celsius: normal in 24–27', () {
        expect(
          getParameterStatus('temperature', 25, unit: '°C'),
          ParameterStatus.normal,
        );
      });
      test('Celsius: critical below 20', () {
        expect(
          getParameterStatus('temperature', 18, unit: '°C'),
          ParameterStatus.critical,
        );
      });
      test('Fahrenheit: normal in 76–80', () {
        expect(
          getParameterStatus('temperature', 78, unit: '°F'),
          ParameterStatus.normal,
        );
      });
      test('Fahrenheit: caution outside 76–80 but within 72–84', () {
        expect(
          getParameterStatus('temperature', 73, unit: '°F'),
          ParameterStatus.caution,
        );
      });
      test('Fahrenheit: critical above 88', () {
        expect(
          getParameterStatus('temperature', 90, unit: '°F'),
          ParameterStatus.critical,
        );
      });
    });

    group('salinity – unit-sensitive', () {
      test('SG: normal 1.023–1.025', () {
        expect(
          getParameterStatus('salinity', 1.024, unit: 'SG'),
          ParameterStatus.normal,
        );
      });
      test('SG: critical outside 1.019–1.029', () {
        expect(
          getParameterStatus('salinity', 1.010, unit: 'SG'),
          ParameterStatus.critical,
        );
      });
      test('ppt: normal 32–35', () {
        expect(
          getParameterStatus('salinity', 33, unit: 'ppt'),
          ParameterStatus.normal,
        );
      });
      test('ppt: caution just outside ideal', () {
        expect(
          getParameterStatus('salinity', 31.5, unit: 'ppt'),
          ParameterStatus.caution,
        );
      });
    });

    test('custom parameter type always returns normal', () {
      expect(
        getParameterStatus('my_custom_param', 999),
        ParameterStatus.normal,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // buildCurrentOutOfRangeAlerts
  // ---------------------------------------------------------------------------
  group('buildCurrentOutOfRangeAlerts', () {
    WaterParameter _make(
      String type,
      double value, {
      String? unit,
      DateTime? date,
    }) => WaterParameter.create(
          parameterType: type,
          value: value,
          unit: unit,
          dateRecorded: date,
        );

    test('returns empty list when all parameters are normal', () {
      final alerts = buildCurrentOutOfRangeAlerts([
        _make('ammonia', 0),
        _make('nitrite', 0),
      ]);
      expect(alerts, isEmpty);
    });

    test('returns alert for out-of-range reading', () {
      final alerts = buildCurrentOutOfRangeAlerts([
        _make('ammonia', 5), // critical
      ]);
      expect(alerts, hasLength(1));
      expect(alerts.first.parameterType, 'ammonia');
      expect(alerts.first.status, ParameterStatus.critical);
    });

    test('selects the latest reading per parameter type', () {
      final base = DateTime(2026, 1, 1);
      // Older reading is out of range; latest is normal.
      final alerts = buildCurrentOutOfRangeAlerts([
        _make('ammonia', 5, date: base),
        _make('ammonia', 0, date: base.add(const Duration(days: 1))),
      ]);
      expect(alerts, isEmpty);
    });

    test('uses newer reading over older when both are out of range', () {
      final base = DateTime(2026, 1, 1);
      // caution on day 0, critical on day 1 → should report critical
      final alerts = buildCurrentOutOfRangeAlerts([
        _make('ammonia', 0.5, date: base),
        _make('ammonia', 5.0, date: base.add(const Duration(days: 1))),
      ]);
      expect(alerts, hasLength(1));
      expect(alerts.first.status, ParameterStatus.critical);
    });

    test('sorts results most-severe first', () {
      final alerts = buildCurrentOutOfRangeAlerts([
        _make('nitrate', 50), // warning
        _make('ammonia', 5), // critical
      ]);
      expect(alerts.first.status, ParameterStatus.critical);
      expect(alerts.last.status, ParameterStatus.warning);
    });

    group('tankType filtering', () {
      final marineOnlyParams = ['salinity', 'calcium', 'magnesium', 'iodine'];

      for (final param in marineOnlyParams) {
        test('suppresses $param alert for freshwater tanks', () {
          // Pick an out-of-range value for each marine-only parameter.
          final value = switch (param) {
            'salinity' => 10.0, // critical for both ppt and SG
            'calcium' => 100.0, // critical (ideal 400–450)
            'magnesium' => 100.0, // critical (ideal 1250–1350)
            'iodine' => 1.0, // critical (ideal 0.06–0.10)
            _ => 0.0,
          };
          final alerts = buildCurrentOutOfRangeAlerts(
            [_make(param, value)],
            tankType: 'freshwater',
          );
          expect(
            alerts,
            isEmpty,
            reason: '$param should be suppressed for freshwater tanks',
          );
        });

        test('includes $param alert for marine tanks', () {
          final value = switch (param) {
            'salinity' => 10.0,
            'calcium' => 100.0,
            'magnesium' => 100.0,
            'iodine' => 1.0,
            _ => 0.0,
          };
          final alerts = buildCurrentOutOfRangeAlerts(
            [_make(param, value)],
            tankType: 'marine',
          );
          expect(
            alerts,
            isNotEmpty,
            reason: '$param should be reported for marine tanks',
          );
        });
      }

      test('includes all non-marine-only alerts for freshwater tanks', () {
        final alerts = buildCurrentOutOfRangeAlerts(
          [_make('ammonia', 5)], // not marine-only → should be reported
          tankType: 'freshwater',
        );
        expect(alerts, hasLength(1));
      });

      test('includes all alerts when tankType is null', () {
        // Without a tankType filter, marine-only params are always checked.
        final alerts = buildCurrentOutOfRangeAlerts([
          _make('salinity', 10.0),
          _make('ammonia', 5.0),
        ]);
        expect(alerts, hasLength(2));
      });
    });
  });
}
