import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/parameter_log.dart';

void main() {
  group('ParameterLog', () {
    test('should create a ParameterLog with all fields', () {
      final log = ParameterLog(
        id: 'test-id',
        dateRecorded: DateTime(2024, 1, 1),
        ammonia: 0.5,
        nitrite: 0.2,
        nitrate: 10.0,
        phosphate: 0.1,
        pH: 7.5,
        salinity: 35.0,
        isSalinitySg: false,
        notes: 'Test notes',
      );

      expect(log.id, 'test-id');
      expect(log.dateRecorded, DateTime(2024, 1, 1));
      expect(log.ammonia, 0.5);
      expect(log.nitrite, 0.2);
      expect(log.nitrate, 10.0);
      expect(log.phosphate, 0.1);
      expect(log.pH, 7.5);
      expect(log.salinity, 35.0);
      expect(log.isSalinitySg, false);
      expect(log.notes, 'Test notes');
    });

    test('should create a ParameterLog with factory method', () {
      final log = ParameterLog.create(
        dateRecorded: DateTime(2024, 1, 1),
        ammonia: 0.5,
        pH: 7.5,
      );

      expect(log.id, isNotEmpty);
      expect(log.dateRecorded, DateTime(2024, 1, 1));
      expect(log.ammonia, 0.5);
      expect(log.pH, 7.5);
      expect(log.nitrite, null);
      expect(log.nitrate, null);
    });

    test('should serialize to JSON correctly', () {
      final log = ParameterLog(
        id: 'test-id',
        dateRecorded: DateTime(2024, 1, 1),
        ammonia: 0.5,
        pH: 7.5,
        isSalinitySg: false,
      );

      final json = log.toJson();

      expect(json['id'], 'test-id');
      expect(json['dateRecorded'], '2024-01-01T00:00:00.000');
      expect(json['ammonia'], 0.5);
      expect(json['pH'], 7.5);
      expect(json['isSalinitySg'], false);
      expect(json['nitrite'], null);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'dateRecorded': '2024-01-01T00:00:00.000',
        'ammonia': 0.5,
        'nitrite': 0.2,
        'nitrate': 10.0,
        'phosphate': 0.1,
        'pH': 7.5,
        'salinity': 35.0,
        'isSalinitySg': true,
        'notes': 'Test notes',
      };

      final log = ParameterLog.fromJson(json);

      expect(log.id, 'test-id');
      expect(log.dateRecorded, DateTime(2024, 1, 1));
      expect(log.ammonia, 0.5);
      expect(log.nitrite, 0.2);
      expect(log.nitrate, 10.0);
      expect(log.phosphate, 0.1);
      expect(log.pH, 7.5);
      expect(log.salinity, 35.0);
      expect(log.isSalinitySg, true);
      expect(log.notes, 'Test notes');
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 'test-id',
        'dateRecorded': '2024-01-01T00:00:00.000',
      };

      final log = ParameterLog.fromJson(json);

      expect(log.id, 'test-id');
      expect(log.ammonia, null);
      expect(log.pH, null);
      expect(log.isSalinitySg, false);
    });

    test('should create a copy with modified fields', () {
      final log = ParameterLog(
        id: 'test-id',
        dateRecorded: DateTime(2024, 1, 1),
        ammonia: 0.5,
        pH: 7.5,
      );

      final updatedLog = log.copyWith(
        ammonia: 0.3,
        nitrite: 0.1,
      );

      expect(updatedLog.id, 'test-id');
      expect(updatedLog.ammonia, 0.3);
      expect(updatedLog.nitrite, 0.1);
      expect(updatedLog.pH, 7.5);
    });

    test('should clear fields when using copyWith with clear flags', () {
      final log = ParameterLog(
        id: 'test-id',
        dateRecorded: DateTime(2024, 1, 1),
        ammonia: 0.5,
        pH: 7.5,
        notes: 'Test notes',
      );

      final updatedLog = log.copyWith(
        clearAmmonia: true,
        clearNotes: true,
      );

      expect(updatedLog.ammonia, null);
      expect(updatedLog.notes, null);
      expect(updatedLog.pH, 7.5);
    });

    test('hasAnyParameter should return true when at least one parameter is set', () {
      final log = ParameterLog(
        id: 'test-id',
        dateRecorded: DateTime(2024, 1, 1),
        pH: 7.5,
      );

      expect(log.hasAnyParameter, true);
    });

    test('hasAnyParameter should return false when no parameters are set', () {
      final log = ParameterLog(
        id: 'test-id',
        dateRecorded: DateTime(2024, 1, 1),
      );

      expect(log.hasAnyParameter, false);
    });
  });
}
