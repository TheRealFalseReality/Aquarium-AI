import 'package:flutter/material.dart';
import 'dart:async';
import '../main_layout.dart';
import '../widgets/gradient_text.dart';
import '../widgets/ad_component.dart';

class FeatureInfo {
  final String icon;
  final String title;
  final String description;
  final String routeName;
  final Duration delay;
  final bool openPhotoAnalyzer; // NEW flag to auto-open analyzer in chatbot

  FeatureInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.routeName,
    required this.delay,
    this.openPhotoAnalyzer = false,
  });
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FeatureInfo> features = [
      FeatureInfo(
        icon: '🐠',
        title: 'AI Compatibility Tool',
        description:
            'Get a detailed, AI-powered compatibility report with care guides and tank recommendations.',
        routeName: '/compat-ai',
        delay: const Duration(milliseconds: 650),
      ),
      FeatureInfo(
        icon: '🤖',
        title: 'AI Chatbot',
        description:
            'Ask questions, get water analysis, scripts & more.',
        routeName: '/chatbot',
        delay: const Duration(milliseconds: 700),
      ),
      FeatureInfo(
        icon: '📷',
        title: 'Photo Analyzer',
        description:
            'Identify fish & assess visible tank health from a photo (auto-opens inside Chatbot).',
        routeName: '/chatbot',
        openPhotoAnalyzer: true,
        delay: const Duration(milliseconds: 750),
      ),
      FeatureInfo(
        icon: '🧪',
        title: 'Aquarium Calculators',
        description:
            'Essential tools: Salinity, CO₂, Alkalinity conversions & more.',
        routeName: '/calculators',
        delay: const Duration(milliseconds: 800),
      ),
      FeatureInfo(
        icon: '🧊',
        title: 'Tank Volume Calculator',
        description:
            'Quickly calculate volume & water weight for many tank shapes.',
        routeName: '/tank-volume',
        delay: const Duration(milliseconds: 850),
      ),
    ];

    return MainLayout(
      title: 'Welcome',
      bottomNavigationBar: const AdBanner(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: <Widget>[
                const AnimatedHeader(),
                const SizedBox(height: 16),
                AnimatedText(
                  'Your intelligent assistant for all things aquatic.',
                  style: Theme.of(context).textTheme.titleMedium,
                  delay: const Duration(milliseconds: 520),
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  alignment: WrapAlignment.center,
                  children: features.map((feature) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: AnimatedFeatureCard(
                        delay: feature.delay,
                        child: FeatureCard(
                          icon: feature.icon,
                          title: feature.title,
                          description: feature.description,
                          onTap: () {
                            if (feature.openPhotoAnalyzer) {
                              Navigator.pushNamed(
                                context,
                                feature.routeName,
                                arguments: {'openPhotoAnalyzer': true},
                              );
                            } else {
                              Navigator.pushNamed(
                                  context, feature.routeName);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                )
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
  AnimatedHeaderState createState() => AnimatedHeaderState();
}

class AnimatedHeaderState extends State<AnimatedHeader> {
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
  AnimatedTextState createState() => AnimatedTextState();
}

class AnimatedTextState extends State<AnimatedText> {
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
  AnimatedFeatureCardState createState() => AnimatedFeatureCardState();
}

class AnimatedFeatureCardState extends State<AnimatedFeatureCard> {
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
      duration: const Duration(milliseconds: 480),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 480),
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        splashColor: cs.primary.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
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