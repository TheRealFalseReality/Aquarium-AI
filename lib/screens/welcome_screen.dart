// ignore_for_file: unused_element

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../main_layout.dart';
import '../widgets/gradient_text.dart';
import '../widgets/ad_component.dart';
import '../providers/model_provider.dart';
import '../providers/tank_provider.dart';
import '../providers/fish_compatibility_provider.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/app_promotion_dialog.dart';
import '../theme_provider.dart';
import '../services/analytics_service.dart';
import '../utils/tank_harmony_calculator.dart';
import '../models/tank.dart';

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

  // Static method to reset promotion dialog preference for testing and debugging
  static Future<void> resetPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_WelcomeScreenState._promotionDialogTimestampKey);
      debugPrint('Promotion dialog timestamp reset');
    } catch (e) {
      debugPrint('Error resetting promotion dialog preference: $e');
    }
  }

  // Static method to manually set timestamp for testing (useful for debugging)
  static Future<void> setPromotionDialogTimestamp(int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_WelcomeScreenState._promotionDialogTimestampKey, timestamp);
      debugPrint('Promotion dialog timestamp set to: $timestamp');
    } catch (e) {
      debugPrint('Error setting promotion dialog timestamp: $e');
    }
  }

  // Static method to check current timestamp for debugging
  static Future<void> checkPromotionDialogStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShownTimestamp = prefs.getInt(_WelcomeScreenState._promotionDialogTimestampKey) ?? 0;
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastShown = (currentTimestamp - lastShownTimestamp) / (1000 * 60 * 60);
      
      debugPrint('Promotion dialog status:');
      debugPrint('  Last shown timestamp: $lastShownTimestamp');
      debugPrint('  Current timestamp: $currentTimestamp');
      debugPrint('  Hours since last shown: ${hoursSinceLastShown.toStringAsFixed(1)}');
      debugPrint('  Will show dialog: ${hoursSinceLastShown >= _WelcomeScreenState._promotionDialogCooldownHours}');
    } catch (e) {
      debugPrint('Error checking promotion dialog status: $e');
    }
  }
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const String _promotionDialogTimestampKey = 'promotion_dialog_timestamp';
  static const int _promotionDialogCooldownHours = 48;
  
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
      // Check if user has chosen to never show the dialog again
      final shouldShow = await AppPromotionDialog.shouldShowDialog();
      if (!shouldShow) {
        debugPrint('Promotion dialog will not be shown (user selected never show again)');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastShownTimestamp = prefs.getInt(_promotionDialogTimestampKey) ?? 0;
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastShown = (currentTimestamp - lastShownTimestamp) / (1000 * 60 * 60);
      
      debugPrint('Promotion dialog check: Last shown timestamp: $lastShownTimestamp, Hours since: ${hoursSinceLastShown.toStringAsFixed(1)}, Cooldown: $_promotionDialogCooldownHours hours');
      
      // Show the dialog if it has never been shown or if 48 hours have passed
      if (hoursSinceLastShown >= _promotionDialogCooldownHours && mounted) {
        debugPrint('Promotion dialog will be shown (cooldown period elapsed)');
        // Show the popup after a short delay to allow the screen to load
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _showPromotionDialog();
          }
        });
      } else {
        debugPrint('Promotion dialog will not be shown (cooldown period not elapsed)');
      }
    } catch (e) {
      // If there's an error with SharedPreferences, silently continue
      debugPrint('Error checking promotion dialog preference: $e');
    }
  }

  Future<void> _showPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store the current timestamp when showing the dialog
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_promotionDialogTimestampKey, currentTimestamp);
      debugPrint('Promotion dialog shown, timestamp saved: $currentTimestamp');
      
      // Log app promotion dialog shown
      AnalyticsService.logAppPromotion(
        action: 'dialog_shown',
        source: 'welcome_screen_auto',
      );
      
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
  // Note: This is now also available as WelcomeScreen.resetPromotionDialog()
  static Future<void> resetPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_promotionDialogTimestampKey);
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
    ref.listen<ModelState>(modelProvider, (previous, next) async {
      // If the provider is no longer loading and the API key is empty, show the dialog.
      if (previous!.isLoading && !next.isLoading && next.geminiApiKey.isEmpty && next.openAIApiKey.isEmpty && next.groqApiKey.isEmpty) {
        // Check if user has chosen to never show the dialog again
        final shouldShow = await ApiKeyDialog.shouldShowDialog();
        if (shouldShow && mounted) {
          showDialog(
            context: context,
            builder: (context) => const ApiKeyDialog(),
          );
        }
      }
    });

    final modelState = ref.watch(modelProvider);
    final isLoading = ref.watch(modelProviderLoading);
    
    // Watch tank state for My Tanks section
    final tankState = ref.watch(tankProvider);
    final tankCount = tankState.tanks.length;
    
    // Get fish data for harmony calculation
    final fishCompatibilityState = ref.watch(fishCompatibilityProvider);
    final fishData = fishCompatibilityState.fishData.value;

    final List<FeatureInfo> features = [
      FeatureInfo(
        icon: '🐠',
        title: 'AI Compatibility Tool',
        description:
            'Get detailed compatibility reports with care guides and recommendations.',
        routeName: '/compat-ai',
        delay: const Duration(milliseconds: 650),
      ),
      FeatureInfo(
        icon: '🤖',
        title: 'AI Chatbot',
        description: 'Ask questions, analyze water parameters, and get expert advice.',
        routeName: '/chatbot',
        delay: const Duration(milliseconds: 700),
      ),
      FeatureInfo(
        icon: '📷',
        title: 'Photo Analyzer',
        description:
            'Identify fish species and assess tank health from photos.',
        routeName: '/chatbot',
        openPhotoAnalyzer: true,
        delay: const Duration(milliseconds: 750),
      ),
      FeatureInfo(
        icon: '🦐',
        title: 'AI Stocking Assistant',
        description: 'Get custom stocking plans to build a harmonious aquatic community.',
        routeName: '/stocking',
        delay: const Duration(milliseconds: 800),
      ),
      FeatureInfo(
        icon: '🧪',
        title: 'Aquarium Calculators',
        description:
            'Essential tools for salinity, CO₂, alkalinity and more.',
        routeName: '/calculators',
        delay: const Duration(milliseconds: 850),
      ),
      FeatureInfo(
        icon: '📏',
        title: 'Tank Volume Calculator',
        description:
            'Calculate volume and water weight for various tank shapes.',
        routeName: '/tank-volume',
        delay: const Duration(milliseconds: 900),
      ),
      FeatureInfo(
        icon: '🛒',
        title: 'AquaPi Store',
        description: 'Visit the official store for AquaPi products.',
        routeName: '',
        url: 'https://www.capitalcityaquatics.com/store/aquapi',
        delay: const Duration(milliseconds: 950),
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
                      const SizedBox(height: 32),
                      
                      // Prominent My Tanks Section
                      _buildMyTanksSection(context, tankState, tankCount, fishData),
                      
                      const SizedBox(height: 32),
                      
                      // Feature Cards in Staggered Grid
                      _buildFeatureGrid(context, features),
                      
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
  
  Widget _buildMyTanksSection(BuildContext context, TankState tankState, int tankCount, Map<String, List<dynamic>>? fishData) {
    final cs = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeProviderNotifierProvider);
    final isMaterialYou = themeState.useMaterialYou;
    
    // Select a random tank if available
    Tank? randomTank;
    if (tankCount > 0) {
      final randomIndex = Random().nextInt(tankCount);
      randomTank = tankState.tanks[randomIndex];
    }
    
    // Determine gradient colors based on tank type
    List<Color> gradientColors;
    if (randomTank != null && randomTank.type == 'freshwater') {
      // Freshwater: blue/cyan gradient
      gradientColors = [
        Colors.blue.shade300.withOpacity(0.3),
        Colors.cyan.shade300.withOpacity(0.3),
      ];
    } else if (randomTank != null) {
      // Saltwater/Marine: indigo/purple gradient
      gradientColors = [
        Colors.indigo.shade300.withOpacity(0.3),
        Colors.purple.shade300.withOpacity(0.3),
      ];
    } else {
      // No tank: default gradient
      gradientColors = [
        cs.secondary.withOpacity(0.3),
        cs.primaryContainer.withOpacity(0.3),
      ];
    }
    
    return AnimatedFeatureCard(
      delay: const Duration(milliseconds: 600),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: isMaterialYou ? 5 : 3,
        shadowColor: cs.shadow.withOpacity(0.3),
        color: isMaterialYou ? cs.surface : null,
        child: Container(
          decoration: isMaterialYou ? BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ) : null,
          child: InkWell(
            onTap: () {
              AnalyticsService.logFeatureUsed(
                featureName: 'my_tanks',
                parameters: {
                  'source': 'welcome_screen',
                  'route': '/tank-management',
                },
              );
              Navigator.pushNamed(context, '/tank-management');
            },
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🏠', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Tanks',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isMaterialYou ? cs.onSurface : cs.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tankCount == 0 
                                  ? 'No tanks yet' 
                                  : '$tankCount ${tankCount == 1 ? 'tank' : 'tanks'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isMaterialYou ? cs.onSurfaceVariant : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: isMaterialYou ? cs.onSurface : cs.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: cs.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  if (tankCount == 0) ...[
                    Text(
                      'Create and manage your custom aquariums with inhabitants. Track compatibility, get personalized stocking recommendations, and maintain optimal conditions for your aquatic community.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isMaterialYou ? cs.onSurfaceVariant : null,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/tank-management');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Your First Tank'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                      ),
                    ),
                  ] else if (randomTank != null) ...[
                    _buildTankPreview(context, randomTank, fishData, isMaterialYou, cs),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTankPreview(BuildContext context, Tank tank, Map<String, List<dynamic>>? fishData, bool isMaterialYou, ColorScheme cs) {
    // Calculate harmony score if possible
    double? harmonyScore;
    if (tank.inhabitants.isNotEmpty && fishData != null) {
      harmonyScore = TankHarmonyCalculator.calculateTankHarmonyScore(tank, fishData);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tank.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isMaterialYou ? cs.onSurface : cs.primary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tank.type == 'freshwater' ? 'Freshwater' : 'Saltwater',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isMaterialYou ? cs.onSurfaceVariant : null,
                    ),
                  ),
                ],
              ),
            ),
            if (tank.sizeGallons != null || tank.sizeLiters != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tank.sizeGallons != null 
                      ? '${tank.sizeGallons!.toStringAsFixed(0)} gal'
                      : '${tank.sizeLiters!.toStringAsFixed(0)} L',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMaterialYou ? cs.onSurface : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (tank.inhabitants.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.pets,
                size: 16,
                color: isMaterialYou ? cs.onSurfaceVariant : cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${tank.inhabitants.length} ${tank.inhabitants.length == 1 ? 'species' : 'species'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isMaterialYou ? cs.onSurfaceVariant : null,
                ),
              ),
              if (harmonyScore != null) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getHarmonyColor(harmonyScore).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getHarmonyColor(harmonyScore),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getHarmonyIcon(harmonyScore),
                        size: 14,
                        color: _getHarmonyColor(harmonyScore),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${TankHarmonyCalculator.getHarmonyLabel(harmonyScore)} ${(harmonyScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getHarmonyColor(harmonyScore),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ] else ...[
          Text(
            'No inhabitants yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isMaterialYou ? cs.onSurfaceVariant : null,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (tank.notes != null && tank.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            tank.notes!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isMaterialYou ? cs.onSurfaceVariant : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
  
  Color _getHarmonyColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.yellow.shade700;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getHarmonyIcon(double score) {
    if (score >= 0.8) return Icons.check_circle;
    if (score >= 0.6) return Icons.info;
    if (score >= 0.4) return Icons.warning;
    return Icons.error;
  }
  
  Widget _buildFeatureGrid(BuildContext context, List<FeatureInfo> features) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;
    
    // Determine column count based on screen size
    final crossAxisCount = isLargeScreen ? 3 : (isMediumScreen ? 2 : 1);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return AnimatedFeatureCard(
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
                    Navigator.pushNamed(context, feature.routeName);
                  }
                },
              ),
            );
          },
        );
      },
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
          splashColor: cs.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isMaterialYou ? cs.onSurface : cs.primary,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isMaterialYou ? cs.onSurfaceVariant : null,
                    height: 1.4,
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