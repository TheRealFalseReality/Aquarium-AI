import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/dosing_entry.dart';

void main() {
  group('DosingEntry', () {
    test('should create a DosingEntry with all fields', () {
      final entry = DosingEntry(
        id: 'test-id',
        treatmentName: 'Prime',
        amount: 5.0,
        unit: 'mL',
        dateDosed: DateTime(2024, 1, 1),
        notes: 'Added after water change',
      );

      expect(entry.id, 'test-id');
      expect(entry.treatmentName, 'Prime');
      expect(entry.amount, 5.0);
      expect(entry.unit, 'mL');
      expect(entry.dateDosed, DateTime(2024, 1, 1));
      expect(entry.notes, 'Added after water change');
    });

    test('should create a DosingEntry using factory method', () {
      final entry = DosingEntry.create(
        treatmentName: 'Flourish',
        amount: 2.5,
        unit: 'mL',
      );

      expect(entry.id, isNotEmpty);
      expect(entry.treatmentName, 'Flourish');
      expect(entry.amount, 2.5);
      expect(entry.unit, 'mL');
      expect(entry.dateDosed, isA<DateTime>());
    });

    test('should default to mL unit when not specified', () {
      final entry = DosingEntry.create(
        treatmentName: 'Test Treatment',
        amount: 1.0,
      );

      expect(entry.unit, 'mL');
    });

    test('should serialize to JSON correctly', () {
      final entry = DosingEntry(
        id: 'test-id',
        treatmentName: 'Prime',
        amount: 5.0,
        unit: 'mL',
        dateDosed: DateTime(2024, 1, 1),
        notes: 'Test notes',
      );

      final json = entry.toJson();

      expect(json['id'], 'test-id');
      expect(json['treatmentName'], 'Prime');
      expect(json['amount'], 5.0);
      expect(json['unit'], 'mL');
      expect(json['dateDosed'], '2024-01-01T00:00:00.000');
      expect(json['notes'], 'Test notes');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'treatmentName': 'Seachem Excel',
        'amount': 10.0,
        'unit': 'mL',
        'dateDosed': '2024-01-01T00:00:00.000',
        'notes': 'Daily dose',
      };

      final entry = DosingEntry.fromJson(json);

      expect(entry.id, 'test-id');
      expect(entry.treatmentName, 'Seachem Excel');
      expect(entry.amount, 10.0);
      expect(entry.unit, 'mL');
      expect(entry.dateDosed, DateTime(2024, 1, 1));
      expect(entry.notes, 'Daily dose');
    });

    test('should create a copy with modified fields', () {
      final entry = DosingEntry(
        id: 'test-id',
        treatmentName: 'Prime',
        amount: 5.0,
        unit: 'mL',
        dateDosed: DateTime(2024, 1, 1),
        notes: 'Test notes',
      );

      final updatedEntry = entry.copyWith(
        amount: 10.0,
        notes: 'Updated notes',
      );

      expect(updatedEntry.id, 'test-id');
      expect(updatedEntry.treatmentName, 'Prime');
      expect(updatedEntry.amount, 10.0);
      expect(updatedEntry.unit, 'mL');
      expect(updatedEntry.dateDosed, DateTime(2024, 1, 1));
      expect(updatedEntry.notes, 'Updated notes');
    });

    test('should handle optional notes field', () {
      final entry = DosingEntry(
        id: 'test-id',
        treatmentName: 'Prime',
        amount: 5.0,
        unit: 'mL',
        dateDosed: DateTime(2024, 1, 1),
      );

      expect(entry.notes, null);
    });

    test('should support different volume units', () {
      final units = ['mL', 'L', 'oz', 'tsp', 'tbsp', 'drops', 'gal', 'cups'];
      
      for (var unit in units) {
        final entry = DosingEntry.create(
          treatmentName: 'Test',
          amount: 1.0,
          unit: unit,
        );
        
        expect(entry.unit, unit);
      }
    });

    test('should serialize and deserialize with different units', () {
      final testDate = DateTime(2024, 1, 1);
      final entries = [
        DosingEntry.create(treatmentName: 'Test1', amount: 5.0, unit: 'mL', dateDosed: testDate),
        DosingEntry.create(treatmentName: 'Test2', amount: 2.0, unit: 'L', dateDosed: testDate),
        DosingEntry.create(treatmentName: 'Test3', amount: 1.0, unit: 'oz', dateDosed: testDate),
        DosingEntry.create(treatmentName: 'Test4', amount: 0.5, unit: 'tsp', dateDosed: testDate),
        DosingEntry.create(treatmentName: 'Test5', amount: 0.25, unit: 'tbsp', dateDosed: testDate),
        DosingEntry.create(treatmentName: 'Test6', amount: 10.0, unit: 'drops', dateDosed: testDate),
      ];

      for (var entry in entries) {
        final json = entry.toJson();
        final deserialized = DosingEntry.fromJson(json);
        
        expect(deserialized.id, entry.id);
        expect(deserialized.treatmentName, entry.treatmentName);
        expect(deserialized.amount, entry.amount);
        expect(deserialized.unit, entry.unit);
      }
    });

    test('should handle decimal amounts correctly', () {
      final entry = DosingEntry.create(
        treatmentName: 'Test',
        amount: 2.5,
        unit: 'mL',
      );

      expect(entry.amount, 2.5);
      
      final json = entry.toJson();
      final deserialized = DosingEntry.fromJson(json);
      
      expect(deserialized.amount, 2.5);
    });

    test('should preserve date and time when serializing', () {
      final specificDate = DateTime(2024, 3, 15, 14, 30);
      final entry = DosingEntry.create(
        treatmentName: 'Test',
        amount: 5.0,
        unit: 'mL',
        dateDosed: specificDate,
      );

      final json = entry.toJson();
      final deserialized = DosingEntry.fromJson(json);
      
      expect(deserialized.dateDosed.year, specificDate.year);
      expect(deserialized.dateDosed.month, specificDate.month);
      expect(deserialized.dateDosed.day, specificDate.day);
      expect(deserialized.dateDosed.hour, specificDate.hour);
      expect(deserialized.dateDosed.minute, specificDate.minute);
    });
  });
}

