import 'package:fish_ai/main.dart' as app;
import 'package:fish_ai/screens/welcome_screen.dart';
import 'package:fish_ai/screens/chatbot_screen.dart';
import 'package:fish_ai/screens/fish_compatibility_screen.dart';
import 'package:fish_ai/screens/calculators_screen.dart';
import 'package:fish_ai/screens/tank_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Aquarium AI App Integration Tests', () {
    testWidgets('Navigate through main app flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Should start on welcome screen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Aquarium AI'), findsOneWidget);

      // Tap on AI Chatbot card
      await tester.tap(find.text('AI Chatbot'));
      await tester.pumpAndSettle();

      // Should navigate to chatbot screen
      expect(find.byType(ChatbotScreen), findsOneWidget);
      expect(find.textContaining('Welcome to Aquarium AI!'), findsOneWidget);

      // Go back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on welcome screen
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Navigate to fish compatibility screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap on Fish Compatibility card
      await tester.tap(find.text('AI Compatibility Calculator'));
      await tester.pumpAndSettle();

      // Should navigate to fish compatibility screen
      expect(find.byType(FishCompatibilityScreen), findsOneWidget);
      expect(find.text('AI Fish Compatibility'), findsOneWidget);
    });

    testWidgets('Navigate to calculators screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap on Calculators card
      await tester.tap(find.text('Aquarium Calculators'));
      await tester.pumpAndSettle();

      // Should navigate to calculators screen
      expect(find.byType(CalculatorsScreen), findsOneWidget);
      
      // Should show salinity converter by default
      expect(find.byType(SalinityConverter), findsOneWidget);
    });
  });
}