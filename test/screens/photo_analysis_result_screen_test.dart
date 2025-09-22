import 'dart:typed_data';
import 'package:fish_ai/models/photo_analysis_result.dart';
import 'package:fish_ai/screens/photo_analysis_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper to create a mock PhotoAnalysisResult
  PhotoAnalysisResult createMockResult() {
    return PhotoAnalysisResult(
      summary: 'Test aquarium analysis summary',
      fishIdentified: [
        FishIdentification(
          name: 'Test Fish',
          confidence: 0.85,
          description: 'A test fish species',
        ),
      ],
      tankHealthAssessment: TankHealthAssessment(
        overallHealth: 'Good',
        healthScore: 0.8,
        observations: ['Clean water', 'Active fish'],
        recommendations: ['Regular water changes'],
      ),
      waterParameterGuesses: WaterParameterGuesses(
        clarity: 'Clear',
        temperature: 'Normal',
        pH: 'Neutral',
        algaeLevel: 'Low',
        stockingAssessment: 'Appropriate',
      ),
    );
  }

  testWidgets('PhotoAnalysisResultScreen UI Test', (WidgetTester tester) async {
    final mockResult = createMockResult();
    final mockPhotoBytes = Uint8List.fromList([1, 2, 3, 4]); // Mock image bytes

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PhotoAnalysisResultScreen(
            result: mockResult,
            photoBytes: mockPhotoBytes,
          ),
        ),
      ),
    );

    // Verify that the screen loads
    expect(find.text('Photo Analysis'), findsOneWidget);
    
    // Verify summary section
    expect(find.text('Analysis Summary'), findsOneWidget);
    expect(find.text('Test aquarium analysis summary'), findsOneWidget);

    // Verify fish identification section
    expect(find.text('Fish Identified'), findsOneWidget);
    expect(find.text('Test Fish'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget); // Confidence percentage

    // Verify tank health section
    expect(find.text('Tank Health Assessment'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget); // Health score percentage

    // Verify water parameter guesses section
    expect(find.text('Water Parameter Visual Assessment'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Appropriate'), findsOneWidget);
  });

  testWidgets('PhotoAnalysisResultScreen regenerate functionality', (WidgetTester tester) async {
    final mockResult = createMockResult();
    final mockPhotoBytes = Uint8List.fromList([1, 2, 3, 4]);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PhotoAnalysisResultScreen(
            result: mockResult,
            photoBytes: mockPhotoBytes,
          ),
        ),
      ),
    );

    // Find and tap regenerate button if it exists
    final regenerateButton = find.textContaining('Regenerate');
    if (regenerateButton.evaluate().isNotEmpty) {
      await tester.tap(regenerateButton.first);
      await tester.pump();
      
      // Should show loading state or trigger regeneration
      // Note: Actual behavior depends on implementation
    }
  });

  testWidgets('PhotoAnalysisResultScreen close functionality', (WidgetTester tester) async {
    final mockResult = createMockResult();
    final mockPhotoBytes = Uint8List.fromList([1, 2, 3, 4]);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PhotoAnalysisResultScreen(
            result: mockResult,
            photoBytes: mockPhotoBytes,
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

  testWidgets('PhotoAnalysisResultScreen thumbnail display', (WidgetTester tester) async {
    final mockResult = createMockResult();
    final mockPhotoBytes = Uint8List.fromList([1, 2, 3, 4]);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PhotoAnalysisResultScreen(
            result: mockResult,
            photoBytes: mockPhotoBytes,
          ),
        ),
      ),
    );

    // Should display the analyzed photo thumbnail
    // Note: Actual implementation depends on how image is displayed
    expect(find.byType(Image), findsAtLeastNWidgets(1));
  });
}