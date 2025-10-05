import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/water_parameter.dart';

void main() {
  group('WaterParameter', () {
    test('should create a WaterParameter with all fields', () {
      final parameter = WaterParameter(
        id: 'test-id',
        parameterType: 'ammonia',
        value: 0.5,
        unit: 'ppm',
        dateRecorded: DateTime(2024, 1, 1),
        notes: 'Test reading',
      );

      expect(parameter.id, 'test-id');
      expect(parameter.parameterType, 'ammonia');
      expect(parameter.value, 0.5);
      expect(parameter.unit, 'ppm');
      expect(parameter.dateRecorded, DateTime(2024, 1, 1));
      expect(parameter.notes, 'Test reading');
    });

    test('should create a WaterParameter using factory method', () {
      final parameter = WaterParameter.create(
        parameterType: 'nitrate',
        value: 10.0,
        unit: 'ppm',
      );

      expect(parameter.id, isNotEmpty);
      expect(parameter.parameterType, 'nitrate');
      expect(parameter.value, 10.0);
      expect(parameter.unit, 'ppm');
      expect(parameter.dateRecorded, isA<DateTime>());
    });

    test('should serialize to JSON correctly', () {
      final parameter = WaterParameter(
        id: 'test-id',
        parameterType: 'ammonia',
        value: 0.5,
        unit: 'ppm',
        dateRecorded: DateTime(2024, 1, 1),
        notes: 'Test reading',
      );

      final json = parameter.toJson();

      expect(json['id'], 'test-id');
      expect(json['parameterType'], 'ammonia');
      expect(json['value'], 0.5);
      expect(json['unit'], 'ppm');
      expect(json['dateRecorded'], '2024-01-01T00:00:00.000');
      expect(json['notes'], 'Test reading');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'parameterType': 'nitrite',
        'value': 0.25,
        'unit': 'mg/L',
        'dateRecorded': '2024-01-01T00:00:00.000',
        'notes': 'Morning reading',
      };

      final parameter = WaterParameter.fromJson(json);

      expect(parameter.id, 'test-id');
      expect(parameter.parameterType, 'nitrite');
      expect(parameter.value, 0.25);
      expect(parameter.unit, 'mg/L');
      expect(parameter.dateRecorded, DateTime(2024, 1, 1));
      expect(parameter.notes, 'Morning reading');
    });

    test('should create a copy with modified fields', () {
      final parameter = WaterParameter(
        id: 'test-id',
        parameterType: 'ammonia',
        value: 0.5,
        unit: 'ppm',
        dateRecorded: DateTime(2024, 1, 1),
        notes: 'Test reading',
      );

      final updatedParameter = parameter.copyWith(
        value: 1.0,
        notes: 'Updated reading',
      );

      expect(updatedParameter.id, 'test-id');
      expect(updatedParameter.parameterType, 'ammonia');
      expect(updatedParameter.value, 1.0);
      expect(updatedParameter.unit, 'ppm');
      expect(updatedParameter.dateRecorded, DateTime(2024, 1, 1));
      expect(updatedParameter.notes, 'Updated reading');
    });

    test('should handle optional fields', () {
      final parameter = WaterParameter(
        id: 'test-id',
        parameterType: 'salinity',
        value: 35.0,
        dateRecorded: DateTime(2024, 1, 1),
      );

      expect(parameter.unit, null);
      expect(parameter.notes, null);
    });
  });
}
