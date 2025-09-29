import 'package:flutter/material.dart';

class ApiKeyDialog extends StatelessWidget {
  const ApiKeyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unlock the Power of AI with Your Own API Key!'),
      content: const SingleChildScrollView(
        child: Text(
          'Aquarium AI is different from other AI-enabled aquarium apps. We empower you by allowing you to use your own AI API keys from Gemini, OpenAI, and Groq. This unique "Bring Your Own Key" model gives you:\n\n'
          '• Higher AI API Call Limits: Enjoy significantly more interactions with our AI, including the powerful Gemini 2.5 flash.\n\n'
          '• Unlimited Features: Get unrestricted access to all our features, including the ability to add and manage an unlimited number of tanks.\n\n'
          'Please go to the settings screen to add your API key and unlock these benefits.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/settings');
          },
          child: const Text('Go to Settings'),
        ),
      ],
    );
  }
}