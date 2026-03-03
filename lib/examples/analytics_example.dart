// Example of how to use the AnalyticsMixin for screen time tracking
// This is for documentation purposes only

import 'package:flutter/material.dart';

import '../mixins/analytics_mixin.dart';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> with AnalyticsMixin {
  @override
  String get screenName => 'example_screen';

  void _onButtonPressed() {
    // Log feature usage with the mixin helper
    logFeatureUsed('example_button', parameters: {'button_type': 'primary'});

    // Log user engagement
    logEngagement('button_click', content: 'example_action');

    // Your button logic here...
  }

  @override
  Widget build(BuildContext context) {
    // Screen time tracking is handled automatically by the mixin
    // - initState() records entry time
    // - dispose() calculates and logs time spent

    return Scaffold(
      appBar: AppBar(title: const Text('Example Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: _onButtonPressed,
          child: const Text('Track This Action'),
        ),
      ),
    );
  }

  // The mixin automatically tracks screen time
  // When user leaves this screen, it will log:
  // - Event: 'time_spent'
  // - Parameters: {'screen': 'example_screen', 'duration_seconds': X}
}
