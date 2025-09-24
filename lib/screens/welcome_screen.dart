import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_layout.dart';
import '../widgets/gradient_text.dart';
import '../widgets/ad_component.dart';
import '../providers/model_provider.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/app_promotion_dialog.dart';
import '../theme_provider.dart';
import '../services/analytics_service.dart';

class FeatureInfo {
  final String icon;
  final String title;
  final String description;
  final String routeName;
  final Duration delay;
  final bool openPhotoAnalyzer;
  final String? url;

  FeatureInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.routeName,
    required this.delay,
    this.openPhotoAnalyzer = false,
    this.url,
  });
}

// Converted to ConsumerStatefulWidget to use initState
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const String _promotionDialogShownKey = 'promotion_dialog_shown';
  
  @override
  void initState() {
    super.initState();
    // Check if we should show the app promotion dialog on web
    if (kIsWeb) {
      _checkShowPromotionDialog();
    }
  }

  Future<void> _checkShowPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownPromotion = prefs.getBool(_promotionDialogShownKey) ?? false;
      
      if (!hasShownPromotion && mounted) {
        // Show the popup after a short delay to allow the screen to load
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _showPromotionDialog();
          }
        });
      }
    } catch (e) {
      // If there's an error with SharedPreferences, silently continue
      debugPrint('Error checking promotion dialog preference: $e');
    }
  }

  Future<void> _showPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_promotionDialogShownKey, true);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const AppPromotionDialog(),
        );
      }
    } catch (e) {
      debugPrint('Error showing promotion dialog: $e');
    }
  }

  // Debug method to reset promotion dialog preference
  // This can be called from settings or debug menu if needed
  static Future<void> resetPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_promotionDialogShownKey);
    } catch (e) {
      debugPrint('Error resetting promotion dialog preference: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider for changes.
    ref.listen<ModelState>(modelProvider, (previous, next) {
      // If the provider is no longer loading and the API key is empty, show the dialog.
      if (previous!.isLoading && !next.isLoading && next.geminiApiKey.isEmpty && next.openAIApiKey.isEmpty && next.groqApiKey.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => const ApiKeyDialog(),
        );
      }
    });

    final modelState = ref.watch(modelProvider);
    final isLoading = ref.watch(modelProviderLoading);

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
        description: 'Ask questions, get water analysis, scripts & more.',
        routeName: '/chatbot',
        delay: const Duration(milliseconds: 700),
      ),
      FeatureInfo(
        icon: '📷',
        title: 'Photo Analyzer',
        description:
            'Identify fish & assess visible tank health from a photo.',
        routeName: '/chatbot',
        openPhotoAnalyzer: true,
        delay: const Duration(milliseconds: 750),
      ),
      FeatureInfo(
        icon: '🦐',
        title: 'AI Stocking Assistant',
        description: 'Receive custom, AI-powered stocking plans based on your tank\'s size and type to help you build a harmonious aquatic community.',
        routeName: '/stocking',
        delay: const Duration(milliseconds: 700),
      ),
      FeatureInfo(
        icon: '🏠',
        title: 'My Tanks',
        description: 'Create and manage your custom tanks with inhabitants. Get personalized stocking recommendations for your tanks.',
        routeName: '/tank-management',
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
        icon: '📏',
        title: 'Tank Volume Calculator',
        description:
            'Quickly calculate volume & water weight for many tank shapes.',
        routeName: '/tank-volume',
        delay: const Duration(milliseconds: 850),
      ),
      FeatureInfo(
        icon: '🛒',
        title: 'AquaPi Store',
        description: 'Visit the official store for AquaPi products.',
        routeName: '',
        url: 'https://www.capitalcityaquatics.com/store/aquapi',
        delay: const Duration(milliseconds: 900),
      ),
    ];

    return MainLayout(
      title: 'Welcome',
      bottomNavigationBar: const AdBanner(),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                  // Log feature usage
                                  AnalyticsService.logFeatureUsed(
                                    featureName: feature.title.toLowerCase().replaceAll(' ', '_'),
                                    parameters: {
                                      'source': 'welcome_screen',
                                      'route': feature.routeName,
                                    },
                                  );
                                  
                                  if (feature.url != null) {
                                    _launchURL(feature.url!);
                                  } else if (feature.openPhotoAnalyzer) {
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
                      ),
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          children: [
                            Text(
                              'Currently using the following models:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            if (modelState.activeProvider == AIProvider.gemini) ...[
                              Text(
                                '${modelState.geminiModel} (text)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${modelState.geminiImageModel} (image)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else if (modelState.activeProvider == AIProvider.groq) ...[
                              Text(
                                '${modelState.groqModel} (text)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${modelState.groqImageModel} (image)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else ...[
                              Text(
                                '${modelState.chatGPTModel} (text)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${modelState.chatGPTImageModel} (image)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ]
                          ],
                        ),
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
          Image.asset('assets/AquaPi Logo.png', height: 125),
          const SizedBox(width: 16),
          GradientText(
            'Aquarium\nAI',
            style: const TextStyle(
              fontSize: 40,
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

  const AnimatedFeatureCard(
      {super.key, required this.child, required this.delay});

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

class FeatureCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeProviderNotifierProvider);
    final isMaterialYou = themeState.useMaterialYou;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isMaterialYou ? 3 : 2,
      shadowColor: cs.shadow.withOpacity(0.2),
      color: isMaterialYou ? cs.surface : null,
      child: Container(
        decoration: isMaterialYou ? BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: [
              cs.secondary.withOpacity(0.3),
              cs.primaryContainer.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ) : null,
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
                        color: isMaterialYou ? cs.onSurface : cs.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMaterialYou ? cs.onSurfaceVariant : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}