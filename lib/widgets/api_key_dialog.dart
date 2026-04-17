import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import '../providers/purchase_provider.dart' show isFounderProvider;
import '../services/remote_config_service.dart';
import '../theme_colors.dart';

class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});

  static const String _neverShowAgainKey = 'api_key_dialog_never_show_again';
  static const String _lastShownTimestampKey =
      'api_key_dialog_last_shown_timestamp';
  static const int _cooldownDays = 7;

  static Future<void> setNeverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_neverShowAgainKey, true);
  }

  /// Records the current timestamp as the last time the dialog was shown.
  /// Call this immediately before [showDialog] so the 1-week cooldown starts.
  static Future<void> recordDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastShownTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    // Permanently suppressed by user choice.
    if (prefs.getBool(_neverShowAgainKey) ?? false) {
      return false;
    }
    // Enforce a 1-week cooldown so the dialog does not appear on every launch.
    final lastShown = prefs.getInt(_lastShownTimestampKey) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastShown;
    const cooldownMs = _cooldownDays * 24 * 60 * 60 * 1000;
    return elapsed >= cooldownMs;
  }

  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  // Breakpoint for responsive button layout: screens narrower than 600px use compact 2-row layout
  // This aligns with Material Design's compact width breakpoint for mobile devices
  static const double _smallScreenBreakpoint = 600;

  List<Widget> _buildDialogActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < _smallScreenBreakpoint;
    final l10n = AppLocalizations.of(context)!;

    if (isSmallScreen) {
      // For small screens, create a custom compact layout
      return [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.dismiss),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        await ApiKeyDialog.setNeverShowAgain();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(l10n.neverShowAgain),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/settings');
                  },
                  child: Text(l10n.goToSettings),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // For larger screens, use standard button layout
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.dismiss),
      ),
      TextButton(
        onPressed: () async {
          await ApiKeyDialog.setNeverShowAgain();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(l10n.neverShowAgain),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed('/settings');
        },
        child: Text(l10n.goToSettings),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);

    return AlertDialog(
      title: const Text('Unlock the Power of AI with Your Own API Key!'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aquarium AI is different from other AI-enabled aquarium apps. We empower you by allowing you to use your own AI API keys from Gemini, OpenAI, and Groq. This unique "Bring Your Own Key" model gives you:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Higher AI API Call Limits: Enjoy significantly more interactions with your AI, including the powerful Gemini 2.5 flash.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Unlimited Features: Get unrestricted access to all our features, including the ability to add and manage an unlimited number of tanks.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final isFounder = ref.watch(isFounderProvider);
                final maxPerMin = isFounder
                    ? RemoteConfigService.founderMaxRequestsPerMinute
                    : RemoteConfigService.maxRequestsPerMinute;
                final maxPerDay = isFounder
                    ? RemoteConfigService.founderMaxRequestsPerDay
                    : RemoteConfigService.maxRequestsPerDay;
                final maxPhotos = isFounder
                    ? RemoteConfigService.founderMaxPhotoAnalysesPerDay
                    : RemoteConfigService.maxPhotoAnalysesPerDay;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFounder
                        ? AquaThemeColors.founderColor(
                            context,
                          ).withOpacity(0.08)
                        : Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFounder
                          ? AquaThemeColors.founderColor(
                              context,
                            ).withOpacity(0.35)
                          : Theme.of(
                              context,
                            ).colorScheme.tertiary.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isFounder ? Icons.diamond : Icons.info_outline,
                        size: 16,
                        color: isFounder
                            ? AquaThemeColors.founderColor(context)
                            : Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFounder
                              ? 'As a Founder Aquarist, your built-in key is limited to $maxPerMin AI requests per minute, $maxPerDay AI requests per day, and $maxPhotos photo ${maxPhotos == 1 ? 'analysis' : 'analyses'} per day. Add your own API key in Settings to remove these limits entirely.'
                              : 'No API key? No problem! You can still use Aquarium AI\'s free service tier powered by our built-in key. The free tier is limited to $maxPerMin AI requests per minute, $maxPerDay AI requests per day, and $maxPhotos photo ${maxPhotos == 1 ? 'analysis' : 'analyses'} per day. Add your own API key in Settings to remove these limits.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isFounder
                                    ? AquaThemeColors.founderColor(context)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Disclaimer: The in-app free AI is provided as a courtesy for aquarium lovers and is funded by the developer. It may be removed or modified at any time, and limits are subject to change without notice.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Tank management (including harmony score) and all calculators (tank volume calculator, etc.) work without an AI key.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please go to the settings screen to add your API key and unlock these AI-powered benefits.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // AI enable/disable toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: SwitchListTile(
                title: Text(
                  'Enable AI Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Toggle AI features to use only calculators and tank management tools.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                value: appSettings.enableAI,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).setEnableAI(value);
                },
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: _buildDialogActions(context),
    );
  }
}
