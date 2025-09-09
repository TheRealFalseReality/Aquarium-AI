// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import '../main_layout.dart';
import '../widgets/gradient_text.dart'; // Import the new widget

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Welcome',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // UPDATED: New logo and gradient text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/AquaPi Logo.png', height: 100),
                    const SizedBox(width: 16),
                    GradientText(
                      'Fish.AI',
                      style: const TextStyle(
                        fontSize: 80, // Large font size
                        fontWeight: FontWeight.bold,
                      ),
                      gradient: LinearGradient(colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your intelligent assistant for aquatic compatibility.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // FeatureCard widgets remain the same
                FeatureCard(
                  icon: '🐠',
                  title: 'AI Compatibility Calculator',
                  description:
                      'Select your fish and get a detailed, AI-powered compatibility report with care guides and tank recommendations.',
                  onTap: () {
                    // Navigator.pushNamed(context, '/compat-ai');
                  },
                ),
                const SizedBox(height: 16),
                FeatureCard(
                  icon: '🤖',
                  title: 'AI Chatbot',
                  description:
                      'Ask questions, get water parameter analysis, and generate automation scripts with our intelligent chatbot.',
                  onTap: () {
                    // Navigator.pushNamed(context, '/chatbot');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FeatureCard class remains the same
class FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}