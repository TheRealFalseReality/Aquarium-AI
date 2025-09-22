import 'package:fish_ai/models/automation_script.dart';
import 'package:fish_ai/screens/automation_script_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper to create a mock AutomationScript
  AutomationScript createMockScript() {
    return AutomationScript(
      title: 'Aquarium Light Control',
      description: 'Automatically control aquarium lights based on time',
      homeAssistantCode: '''
automation:
  - alias: "Aquarium Lights Morning"
    trigger:
      platform: time
      at: "08:00:00"
    action:
      service: switch.turn_on
      target:
        entity_id: switch.aquarium_lights
''',
      espHomeCode: '''
switch:
  - platform: gpio
    pin: GPIO2
    name: "Aquarium Lights"
    id: aquarium_lights

time:
  - platform: homeassistant
    id: homeassistant_time

automation:
  - then:
      - at: "08:00:00"
        then:
          - switch.turn_on: aquarium_lights
''',
      explanation: 'This script turns on aquarium lights at 8 AM daily.',
    );
  }

  testWidgets('AutomationScriptResultScreen UI Test', (WidgetTester tester) async {
    final mockScript = createMockScript();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AutomationScriptResultScreen(script: mockScript),
        ),
      ),
    );

    // Verify that the screen loads with script results
    expect(find.text('Automation Script'), findsOneWidget);
    expect(find.text('Aquarium Light Control'), findsOneWidget);
    expect(find.text('Automatically control aquarium lights based on time'), findsOneWidget);
    
    // Verify explanation section
    expect(find.text('This script turns on aquarium lights at 8 AM daily.'), findsOneWidget);
    
    // Verify platform tabs
    expect(find.text('Home Assistant'), findsOneWidget);
    expect(find.text('ESPHome'), findsOneWidget);
    
    // Verify close button
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('AutomationScriptResultScreen tab switching', (WidgetTester tester) async {
    final mockScript = createMockScript();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AutomationScriptResultScreen(script: mockScript),
        ),
      ),
    );

    // Should show Home Assistant code by default
    expect(find.textContaining('automation:'), findsOneWidget);
    expect(find.textContaining('alias: "Aquarium Lights Morning"'), findsOneWidget);

    // Tap on ESPHome tab
    await tester.tap(find.text('ESPHome'));
    await tester.pump();

    // Should now show ESPHome code
    expect(find.textContaining('switch:'), findsOneWidget);
    expect(find.textContaining('platform: gpio'), findsOneWidget);
  });

  testWidgets('AutomationScriptResultScreen copy functionality', (WidgetTester tester) async {
    final mockScript = createMockScript();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AutomationScriptResultScreen(script: mockScript),
        ),
      ),
    );

    // Find copy buttons
    final copyButtons = find.byIcon(Icons.copy);
    expect(copyButtons, findsAtLeastNWidgets(1));

    // Tap copy button
    await tester.tap(copyButtons.first);
    await tester.pump();

    // Should show snackbar or complete without error
  });

  testWidgets('AutomationScriptResultScreen close functionality', (WidgetTester tester) async {
    final mockScript = createMockScript();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AutomationScriptResultScreen(script: mockScript),
          ),
        ),
      ),
    );

    // Find and tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    
    // Should navigate back (in real app context)
  });
}