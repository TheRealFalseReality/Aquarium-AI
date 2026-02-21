import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_settings_provider.dart';
import '../utils/dev_limits.dart';

class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});

  /// Stores the epoch-millisecond timestamp until which the dialog is snoozed.
  static const String _snoozedUntilKey = 'api_key_dialog_snoozed_until';

  /// Legacy key kept for migration only.
  static const String _legacyNeverShowKey = 'api_key_dialog_never_show_again';

  /// Snooze the dialog for one week from now.
  static Future<void> snoozeForWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final snoozedUntil =
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    await prefs.setInt(_snoozedUntilKey, snoozedUntil);
  }

  /// Clear any active snooze so the dialog will show again immediately.
  static Future<void> clearSnooze() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snoozedUntilKey);
    await prefs.remove(_legacyNeverShowKey);
  }

  static Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate legacy "never show again" flag → treat it as a permanent snooze
    // that was set in the past (i.e. don't change old behavior for existing users).
    if (prefs.getBool(_legacyNeverShowKey) ?? false) {
      return false;
    }

    final snoozedUntil = prefs.getInt(_snoozedUntilKey);
    if (snoozedUntil == null) return true;
    return DateTime.now().millisecondsSinceEpoch > snoozedUntil;
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

    if (isSmallScreen) {
      return [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss'),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/settings');
                  },
                  child: const Text('Go to Settings'),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
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
            // Free-tier disclaimer + Enable AI toggle (consolidated)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiaryContainer
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No API key? No problem! You can still use Aquarium AI\'s free service tier powered by our built-in key. The free tier is limited to $devMaxRequestsPerMinute AI requests per minute and $devMaxPhotoAnalysesPerDay photo ${devMaxPhotoAnalysesPerDay == 1 ? 'analysis' : 'analyses'} per day. Add your own key in Settings to remove these limits.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Inline compact "Try Free AI" toggle
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        size: 16,
                        color: appSettings.enableAI
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Try Free AI',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: appSettings.enableAI,
                          onChanged: (value) async {
                            ref
                                .read(appSettingsProvider.notifier)
                                .setEnableAI(value);
                            // Snooze the dialog for a week when the user
                            // enables the free AI tier, to give them time
                            // before being reminded to supply their own key.
                            if (value) {
                              try {
                                await ApiKeyDialog.snoozeForWeek();
                              } catch (_) {
                                // Snooze failure is non-fatal; ignore silently.
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: _buildDialogActions(context),
    );
  }
}

