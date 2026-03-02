import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
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
    const url = 'https://play.google.com/store/apps/details?id=com.cca.fishai';
    final Uri uri = Uri.parse(url);
    
    // Log app promotion click
    AnalyticsService.logAppPromotion(
      action: 'play_store_click',
      source: 'promotion_dialog',
    );
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.phone_android,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.appPromoDialogTitle,
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
              l10n.appPromoDialogIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              context,
              Icons.offline_bolt,
              l10n.appPromoBenefitOfflineTitle,
              l10n.appPromoBenefitOfflineDesc,
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.camera_alt,
              l10n.appPromoBenefitCameraTitle,
              l10n.appPromoBenefitCameraDesc,
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.notifications,
              l10n.appPromoBenefitNotificationsTitle,
              l10n.appPromoBenefitNotificationsDesc,
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.dashboard,
              l10n.appPromoBenefitPerformanceTitle,
              l10n.appPromoBenefitPerformanceDesc,
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
            l10n.maybeLater,
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
            l10n.neverShowAgain,
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
          child: Text(l10n.getTheApp),
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
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
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
