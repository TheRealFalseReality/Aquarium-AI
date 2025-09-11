import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tank Volume Calculations', () {
    // --- Test Data ---
    const double length = 20.0;
    const double width = 10.0;
    const double height = 12.0;
    const double diameter = 15.0;
    const double edge = 8.0;
    const double fullWidth = 12.0;

    // --- Conversion Factors ---
    const double inchesToGallons = 0.004329;
    const double inchesToLiters = 0.0163871;

    test('Rectangle Volume Calculation', () {
      final double volumeInches = length * width * height;
      final double gallons = volumeInches * inchesToGallons;
      final double liters = volumeInches * inchesToLiters;
      expect(gallons, closeTo(10.39, 0.01));
      expect(liters, closeTo(39.33, 0.01));
    });

    test('Cube Volume Calculation', () {
      final double volumeInches = pow(length, 3).toDouble();
      final double gallons = volumeInches * inchesToGallons;
      final double liters = volumeInches * inchesToLiters;
      expect(gallons, closeTo(34.63, 0.01));
      expect(liters, closeTo(131.10, 0.01));
    });

    test('Cylinder Volume Calculation', () {
      final double radius = diameter / 2.0;
      final double volumeInches = pi * pow(radius, 2) * height;
      final double gallons = volumeInches * inchesToGallons;
      final double liters = volumeInches * inchesToLiters;
      expect(gallons, closeTo(9.18, 0.01));
      expect(liters, closeTo(34.75, 0.01));
    });

    test('Hexagonal Volume Calculation', () {
      final double volumeInches = (3 * sqrt(3) / 2) * pow(edge, 2) * height;
      final double gallons = volumeInches * inchesToGallons;
      final double liters = volumeInches * inchesToLiters;
      expect(gallons, closeTo(8.64, 0.01));
      expect(liters, closeTo(32.70, 0.01));
    });

    test('BowFront Volume Calculation', () {
      final double bowDepth = fullWidth - width;
      final double r = (pow(length / 2, 2) + pow(bowDepth, 2)) / (2 * bowDepth);
      final double theta = 2 * asin((length / 2) / r);
      final double segmentArea = pow(r, 2) / 2 * (theta - sin(theta));
      final double volumeInches = (length * width * height) + (segmentArea * height);
      final double gallons = volumeInches * inchesToGallons;
      final double liters = volumeInches * inchesToLiters;
      expect(gallons, closeTo(11.78, 0.01));
      expect(liters, closeTo(44.61, 0.01));
    });
  });
}