import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart' show googlePlayStoreUrl;
import '../services/analytics_service.dart';

class AppPromotionDialog extends StatelessWidget {
  const AppPromotionDialog({super.key});

  static const String _neverShowAgainKey = 'app_promotion_never_show_again';

  static Future<void> setNeverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_neverShowAgainKey, true);
  }

  static Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_neverShowAgainKey) ?? false);
  }

  Future<void> _launchPlayStore() async {
    final Uri uri = Uri.parse(googlePlayStoreUrl);

    // Log app promotion click
    AnalyticsService.logAppPromotion(
      action: 'play_store_click',
      source: 'promotion_dialog',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $googlePlayStoreUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.phone_android, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Get Aquarium AI on Your Device!',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experience the full power of Aquarium AI with our mobile app:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              context,
              Icons.offline_bolt,
              'Offline Access',
              'Use key features even without internet connection',
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.camera_alt,
              'Enhanced Camera',
              'Better photo analysis with native camera integration',
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.notifications,
              'Smart Notifications',
              'Get reminders for water changes and tank maintenance',
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.dashboard,
              'Native Performance',
              'Faster, smoother experience optimized for mobile',
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _launchPlayStore,
                child: Image.asset(
                  'assets/images/system/google_play_badge.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Log dismissal
            AnalyticsService.logAppPromotion(
              action: 'dialog_dismissed',
              source: 'promotion_dialog',
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
            // Log never show again
            AnalyticsService.logAppPromotion(
              action: 'never_show_again',
              source: 'promotion_dialog',
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
            _launchPlayStore();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Get the App'),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
