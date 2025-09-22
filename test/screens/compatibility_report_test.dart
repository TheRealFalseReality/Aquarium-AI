import 'package:fish_ai/models/compatibility_report.dart';
import 'package:fish_ai/screens/compatibility_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper to create a mock CompatibilityReport
  CompatibilityReport createMockReport() {
    return CompatibilityReport(
      summary: 'Your fish selection shows good compatibility.',
      overallScore: 0.85,
      recommendations: [
        'Add more hiding spots for the shy fish.',
        'Consider adding a bottom feeder like Corydoras.',
      ],
      fishAnalysis: [
        FishCompatibilityAnalysis(
          fishName: 'Angelfish',
          compatibilityStatus: 'Good',
          issues: [],
          recommendations: ['Provide adequate space for swimming.'],
        ),
        FishCompatibilityAnalysis(
          fishName: 'Neon Tetra',
          compatibilityStatus: 'Excellent',
          issues: [],
          recommendations: ['Keep in schools of 6 or more.'],
        ),
      ],
      tankConditions: TankConditions(
        size: '20 gallons',
        type: 'Freshwater',
        overcrowding: false,
        territorialIssues: false,
      ),
    );
  }

  testWidgets('CompatibilityReport UI Test', (WidgetTester tester) async {
    final mockReport = createMockReport();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CompatibilityReport(report: mockReport),
        ),
      ),
    );

    // Verify that the screen loads with compatibility results
    expect(find.text('Fish Compatibility Report'), findsOneWidget);
    expect(find.text('Your fish selection shows good compatibility.'), findsOneWidget);
    
    // Verify overall score
    expect(find.text('85%'), findsOneWidget); // Overall score percentage
    
    // Verify recommendations
    expect(find.text('Add more hiding spots for the shy fish.'), findsOneWidget);
    expect(find.text('Consider adding a bottom feeder like Corydoras.'), findsOneWidget);
    
    // Verify fish analysis
    expect(find.text('Angelfish'), findsOneWidget);
    expect(find.text('Neon Tetra'), findsOneWidget);
    expect(find.text('Provide adequate space for swimming.'), findsOneWidget);
    expect(find.text('Keep in schools of 6 or more.'), findsOneWidget);
    
    // Verify tank conditions
    expect(find.text('20 gallons'), findsOneWidget);
    expect(find.text('Freshwater'), findsOneWidget);
  });

  testWidgets('CompatibilityReport with issues', (WidgetTester tester) async {
    final reportWithIssues = CompatibilityReport(
      summary: 'Some compatibility concerns detected.',
      overallScore: 0.45,
      recommendations: [
        'Remove aggressive fish or provide separate tank.',
        'Increase tank size to reduce territorial behavior.',
      ],
      fishAnalysis: [
        FishCompatibilityAnalysis(
          fishName: 'Aggressive Cichlid',
          compatibilityStatus: 'Poor',
          issues: ['May harm smaller fish', 'Territorial behavior'],
          recommendations: ['Separate from community fish.'],
        ),
      ],
      tankConditions: TankConditions(
        size: '10 gallons',
        type: 'Freshwater',
        overcrowding: true,
        territorialIssues: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CompatibilityReport(report: reportWithIssues),
        ),
      ),
    );

    // Verify issues are displayed
    expect(find.text('Some compatibility concerns detected.'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget); // Lower score
    expect(find.text('May harm smaller fish'), findsOneWidget);
    expect(find.text('Territorial behavior'), findsOneWidget);
    expect(find.text('Remove aggressive fish or provide separate tank.'), findsOneWidget);
  });

  testWidgets('CompatibilityReport close functionality', (WidgetTester tester) async {
    final mockReport = createMockReport();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CompatibilityReport(report: mockReport),
          ),
        ),
      ),
    );

    // Find and tap close button
    final closeButton = find.byIcon(Icons.close);
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton.first);
      await tester.pump();
      
      // Should navigate back
    }
  });

  testWidgets('CompatibilityReport fish analysis expansion', (WidgetTester tester) async {
    final mockReport = createMockReport();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CompatibilityReport(report: mockReport),
        ),
      ),
    );

    // Find and tap on a fish to expand details
    await tester.tap(find.text('Angelfish'));
    await tester.pump();

    // Should show detailed analysis
    expect(find.text('Good'), findsOneWidget); // Compatibility status
    expect(find.text('Provide adequate space for swimming.'), findsOneWidget);
  });
}