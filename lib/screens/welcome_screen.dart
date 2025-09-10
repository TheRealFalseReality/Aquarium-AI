// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../main_layout.dart';
import '../widgets/gradient_text.dart';
import '../widgets/ad_component.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Welcome',
      bottomNavigationBar: const AdBanner(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AnimatedHeader(),
                const SizedBox(height: 16),
                AnimatedText(
                  'Your intelligent assistant for aquatic compatibility.',
                  style: Theme.of(context).textTheme.titleMedium,
                  delay: const Duration(milliseconds: 500),
                ),
                const SizedBox(height: 48),
                AnimatedFeatureCard(
                  delay: const Duration(milliseconds: 700),
                  child: FeatureCard(
                    icon: '🐠',
                    title: 'AI Compatibility Calculator',
                    description:
                        'Select your fish and get a detailed, AI-powered compatibility report with care guides and tank recommendations.',
                    onTap: () {
                      Navigator.pushNamed(context, '/compat-ai');
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedFeatureCard(
                  delay: const Duration(milliseconds: 900),
                  child: FeatureCard(
                    icon: '🤖',
                    title: 'AI Chatbot',
                    description:
                        'Ask questions, get water parameter analysis, and generate automation scripts with our intelligent chatbot.',
                    onTap: () {
                      Navigator.pushNamed(context, '/chatbot');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedHeader extends StatefulWidget {
  const AnimatedHeader({super.key});

  @override
  _AnimatedHeaderState createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<AnimatedHeader> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isAnimated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/AquaPi Logo.png', height: 100),
          const SizedBox(width: 16),
          GradientText(
            'Fish.AI',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
            ),
            gradient: LinearGradient(colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ]),
          ),
        ],
      ),
    );
  }
}

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration delay;

  const AnimatedText(this.text, {super.key, this.style, required this.delay});

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isAnimated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class AnimatedFeatureCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedFeatureCard({super.key, required this.child, required this.delay});

  @override
  _AnimatedFeatureCardState createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<AnimatedFeatureCard> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isAnimated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        transform: Matrix4.translationValues(0, _isAnimated ? 0 : 20, 0),
        child: widget.child,
      ),
    );
  }
}

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