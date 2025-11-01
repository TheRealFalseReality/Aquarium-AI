import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

class AquaPiPromotionDialog extends StatelessWidget {
  const AquaPiPromotionDialog({super.key});

  static const String _neverShowAgainKey = 'aquapi_promotion_never_show_again';

  static Future<void> setNeverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_neverShowAgainKey, true);
  }

  static Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_neverShowAgainKey) ?? false);
  }

  Future<void> _launchAquaPiStore() async {
    const url = 'https://www.capitalcityaquatics.com/store/p/aquapi-wmgdj';
    final Uri uri = Uri.parse(url);
    
    // Log AquaPi promotion click
    AnalyticsService.logAppPromotion(
      action: 'aquapi_store_click',
      source: 'aquapi_promotion_dialog',
    );
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        print('Could not launch $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings_input_component,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Meet AquaPi!',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: isSmallScreen
            ? _buildVerticalLayout(context, colorScheme)
            : _buildHorizontalLayout(context, colorScheme),
      ),
      actions: isSmallScreen
          ? _buildMobileActions(context, colorScheme)
          : _buildDesktopActions(context, colorScheme),
    );
  }

  Widget _buildVerticalLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marketing image at top for mobile
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/AquaPiMainSmaller.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Take your aquarium to the next level with AquaPi - the open-source smart monitoring and automation system!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          context,
          Icons.hub,
          'Smart Monitoring',
          'Real-time monitoring of temperature, pH, water level, and more',
        ),
        const SizedBox(height: 10),
        _buildFeatureItem(
          context,
          Icons.home_outlined,
          'Home Assistant Integration',
          'Seamlessly integrates with your smart home ecosystem',
        ),
        const SizedBox(height: 10),
        _buildFeatureItem(
          context,
          Icons.tune,
          'Fully Customizable',
          'Open-source design lets you add unlimited sensors and automations',
        ),
        const SizedBox(height: 10),
        _buildFeatureItem(
          context,
          Icons.notifications_active,
          'Automated Alerts',
          'Get notified instantly about critical changes in your aquarium',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.secondaryContainer.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Perfect for DIY enthusiasts and tech-savvy aquarists!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marketing image on the left
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/AquaPiMainSmaller.png',
            width: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(width: 16),
        // Content on the right
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Take your aquarium to the next level with AquaPi - the open-source smart monitoring and automation system!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                Icons.hub,
                'Smart Monitoring',
                'Real-time monitoring of temperature, pH, water level, and more',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                context,
                Icons.home_outlined,
                'Home Assistant Integration',
                'Seamlessly integrates with your smart home ecosystem',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                context,
                Icons.tune,
                'Fully Customizable',
                'Open-source design lets you add unlimited sensors and automations',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                context,
                Icons.notifications_active,
                'Automated Alerts',
                'Get notified instantly about critical changes in your aquarium',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.3),
                      colorScheme.secondaryContainer.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perfect for DIY enthusiasts and tech-savvy aquarists!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMobileActions(BuildContext context, ColorScheme colorScheme) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchAquaPiStore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Learn More'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  AnalyticsService.logAppPromotion(
                    action: 'dialog_dismissed',
                    source: 'aquapi_promotion_dialog',
                  );
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Maybe Later',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () async {
                  AnalyticsService.logAppPromotion(
                    action: 'never_show_again',
                    source: 'aquapi_promotion_dialog',
                  );
                  await setNeverShowAgain();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'Never Show',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context, ColorScheme colorScheme) {
    return [
      TextButton(
        onPressed: () {
          AnalyticsService.logAppPromotion(
            action: 'dialog_dismissed',
            source: 'aquapi_promotion_dialog',
          );
          Navigator.of(context).pop();
        },
        child: Text(
          'Maybe Later',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
      TextButton(
        onPressed: () async {
          AnalyticsService.logAppPromotion(
            action: 'never_show_again',
            source: 'aquapi_promotion_dialog',
          );
          await setNeverShowAgain();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Text(
          'Never Show Again',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          _launchAquaPiStore();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        child: const Text('Learn More'),
      ),
    ];
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: isSmallScreen ? 16 : 18,
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: isSmallScreen ? 13 : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: isSmallScreen ? 11 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
