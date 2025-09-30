import 'package:flutter/material.dart';

class ApiKeyDialog extends StatelessWidget {
  const ApiKeyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI API Key Required'),
      content: const SingleChildScrollView(
        child: Text(
          'To use the AI features of this app, you need to provide your own AI API key from Google, OpenAI (soon), or Groq.\n\nPlease go to the settings screen to add your key.',
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