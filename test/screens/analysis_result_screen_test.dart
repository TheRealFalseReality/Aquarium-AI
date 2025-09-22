import 'package:fish_ai/models/analysis_result.dart';
import 'package:fish_ai/screens/analysis_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper to create a mock WaterAnalysisResult
  WaterAnalysisResult createMockAnalysisResult() {
    return WaterAnalysisResult(
      summary: AnalysisSummary(
        status: 'Good',
        title: 'Water Analysis Complete',
        message: 'Your water parameters are within acceptable ranges.',
      ),
      parameters: [
        ParameterAnalysis(
          name: 'pH',
          value: '7.2',
          idealRange: '6.5-7.5',
          status: 'Good',
          advice: 'pH is within the ideal range for most fish.',
        ),
        ParameterAnalysis(
          name: 'Ammonia',
          value: '0.0 ppm',
          idealRange: '0.0 ppm',
          status: 'Excellent',
          advice: 'Ammonia levels are perfect.',
        ),
      ],
      howAquaPiHelps: 'AquaPi can help monitor these parameters automatically.',
    );
  }

  testWidgets('AnalysisResultScreen UI Test', (WidgetTester tester) async {
    final mockResult = createMockAnalysisResult();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AnalysisResultScreen(result: mockResult),
        ),
      ),
    );

    // Verify that the screen loads with analysis results
    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Water Analysis Complete'), findsOneWidget);
    
    // Verify summary section
    expect(find.text('Your water parameters are within acceptable ranges.'), findsOneWidget);
    
    // Verify parameter analysis sections
    expect(find.text('pH'), findsOneWidget);
    expect(find.text('7.2'), findsOneWidget);
    expect(find.text('6.5-7.5'), findsOneWidget);
    expect(find.text('pH is within the ideal range for most fish.'), findsOneWidget);
    
    expect(find.text('Ammonia'), findsOneWidget);
    expect(find.text('0.0 ppm'), findsOneWidget);
    expect(find.text('Ammonia levels are perfect.'), findsOneWidget);
    
    // Verify AquaPi section
    expect(find.text('AquaPi can help monitor these parameters automatically.'), findsOneWidget);
    
    // Verify close button
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('AnalysisResultScreen close functionality', (WidgetTester tester) async {
    final mockResult = createMockAnalysisResult();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AnalysisResultScreen(result: mockResult),
          ),
        ),
      ),
    );

    // Find and tap close button
    await tester.tap(find.text('Close'));
    await tester.pump();
    
    // Should navigate back (in real app context)
  });

  testWidgets('AnalysisResultScreen with different status levels', (WidgetTester tester) async {
    final criticalResult = WaterAnalysisResult(
      summary: AnalysisSummary(
        status: 'Bad',
        title: 'Critical Water Issues',
        message: 'Immediate action required.',
      ),
      parameters: [
        ParameterAnalysis(
          name: 'Ammonia',
          value: '2.0 ppm',
          idealRange: '0.0 ppm',
          status: 'Bad',
          advice: 'High ammonia levels are toxic to fish. Change water immediately.',
        ),
      ],
      howAquaPiHelps: 'AquaPi would have alerted you to this issue.',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AnalysisResultScreen(result: criticalResult),
        ),
      ),
    );

    // Verify critical status is displayed
    expect(find.text('Critical Water Issues'), findsOneWidget);
    expect(find.text('Immediate action required.'), findsOneWidget);
    expect(find.text('High ammonia levels are toxic to fish. Change water immediately.'), findsOneWidget);
  });
}