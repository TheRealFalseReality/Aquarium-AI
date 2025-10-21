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

    test('should create KH parameter with dKH unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'kh',
        value: 6.0,
        unit: 'dKH',
      );

      expect(parameter.parameterType, 'kh');
      expect(parameter.value, 6.0);
      expect(parameter.unit, 'dKH');
    });

    test('should create GH parameter with dGH unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'gh',
        value: 8.0,
        unit: 'dGH',
      );

      expect(parameter.parameterType, 'gh');
      expect(parameter.value, 8.0);
      expect(parameter.unit, 'dGH');
    });

    test('should create KH parameter with meq/L unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'kh',
        value: 3.5,
        unit: 'meq/L',
      );

      expect(parameter.parameterType, 'kh');
      expect(parameter.value, 3.5);
      expect(parameter.unit, 'meq/L');
    });

    test('should create GH parameter with meq/L unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'gh',
        value: 4.0,
        unit: 'meq/L',
      );

      expect(parameter.parameterType, 'gh');
      expect(parameter.value, 4.0);
      expect(parameter.unit, 'meq/L');
    });

    test('should create Alkalinity parameter with meq/L unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'alkalinity',
        value: 3.0,
        unit: 'meq/L',
      );

      expect(parameter.parameterType, 'alkalinity');
      expect(parameter.value, 3.0);
      expect(parameter.unit, 'meq/L');
    });

    test('should create ORP parameter with mV unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'orp',
        value: 350.0,
        unit: 'mV',
      );

      expect(parameter.parameterType, 'orp');
      expect(parameter.value, 350.0);
      expect(parameter.unit, 'mV');
    });

    test('should create pH parameter', () {
      final parameter = WaterParameter.create(
        parameterType: 'ph',
        value: 7.2,
        unit: 'pH',
      );

      expect(parameter.parameterType, 'ph');
      expect(parameter.value, 7.2);
      expect(parameter.unit, 'pH');
    });

    test('should create Potassium parameter with ppm unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'potassium',
        value: 15.0,
        unit: 'ppm',
      );

      expect(parameter.parameterType, 'potassium');
      expect(parameter.value, 15.0);
      expect(parameter.unit, 'ppm');
    });

    test('should create TDS parameter with ppm unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'tds',
        value: 200.0,
        unit: 'ppm',
      );

      expect(parameter.parameterType, 'tds');
      expect(parameter.value, 200.0);
      expect(parameter.unit, 'ppm');
    });

    test('should create Iodine parameter with ppm unit', () {
      final parameter = WaterParameter.create(
        parameterType: 'iodine',
        value: 0.08,
        unit: 'ppm',
      );

      expect(parameter.parameterType, 'iodine');
      expect(parameter.value, 0.08);
      expect(parameter.unit, 'ppm');
    });

    test('should serialize and deserialize new parameter types', () {
      final parameters = [
        WaterParameter(id: '1', parameterType: 'kh', value: 6.0, unit: 'dKH', dateRecorded: DateTime(2024, 1, 1)),
        WaterParameter(id: '2', parameterType: 'gh', value: 8.0, unit: 'dGH', dateRecorded: DateTime(2024, 1, 1)),
        WaterParameter(id: '3', parameterType: 'alkalinity', value: 3.0, unit: 'meq/L', dateRecorded: DateTime(2024, 1, 1)),
        WaterParameter(id: '4', parameterType: 'orp', value: 350.0, unit: 'mV', dateRecorded: DateTime(2024, 1, 1)),
        WaterParameter(id: '5', parameterType: 'ph', value: 7.2, unit: 'pH', dateRecorded: DateTime(2024, 1, 1)),
        WaterParameter(id: '6', parameterType: 'potassium', value: 15.0, unit: 'ppm', dateRecorded: DateTime(2024, 1, 1)),
        WaterParameter(id: '7', parameterType: 'tds', value: 200.0, unit: 'ppm', dateRecorded: DateTime(2024, 1, 1)),
        WaterParameter(id: '8', parameterType: 'iodine', value: 0.08, unit: 'ppm', dateRecorded: DateTime(2024, 1, 1)),
      ];

      for (var param in parameters) {
        final json = param.toJson();
        final deserialized = WaterParameter.fromJson(json);
        
        expect(deserialized.id, param.id);
        expect(deserialized.parameterType, param.parameterType);
        expect(deserialized.value, param.value);
        expect(deserialized.unit, param.unit);
      }
    });
  });
}
