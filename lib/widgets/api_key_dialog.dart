import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyDialog extends StatelessWidget {
  const ApiKeyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Your Google AI API Key'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To use the AI features of this app, you need to provide your own Google AI API key.',
            ),
            const SizedBox(height: 16),
            const Text(
              'How to get your API key:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Go to the Google AI Studio website.'),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
              child: const Text(
                'https://aistudio.google.com/app/apikey',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 8),
            const Text('2. Sign in with your Google account.'),
            const SizedBox(height: 8),
            const Text('3. Click on "Create API key in new project" or "Get API key" then follow the prompts.'),
            const SizedBox(height: 8),
            const Text('4. Click "Create API key" in the top right.'),
            const SizedBox(height: 8),
            const Text('5. Copy the generated API key and paste it in the settings screen.'),
          ],
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