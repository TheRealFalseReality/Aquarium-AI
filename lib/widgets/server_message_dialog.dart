import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

/// A dialog that surfaces a server-side message pushed via Firebase Remote Config.
///
/// The dialog shows once per unique [RemoteConfigService.serverMessageId]. The
/// user can either:
/// * **Dismiss forever** – the message is permanently hidden for this ID.
/// * **Remind me in 3 days** (or tap the barrier) – the dialog will reappear
///   after 72 hours, unless the message ID changes in the meantime.
///
/// ## SharedPreferences keys
/// * `server_message_dismissed_id` – stores the ID of the last permanently
///   dismissed message.
/// * `server_message_remind_after` – epoch-millisecond timestamp after which
///   the dialog may appear again (snooze).
class ServerMessageDialog extends StatelessWidget {
  const ServerMessageDialog({
    super.key,
    required this.messageId,
    required this.title,
    required this.message,
  });

  /// The unique identifier of this message (from Remote Config).
  final String messageId;

  /// The dialog title (from Remote Config).
  final String title;

  /// The dialog body text (from Remote Config).
  final String message;

  // ── SharedPreferences keys ──────────────────────────────────────────────────

  static const String _dismissedIdKey = 'server_message_dismissed_id';
  static const String _remindAfterKey = 'server_message_remind_after';
  static const String _remindAfterIdKey = 'server_message_remind_after_id';

  /// Duration to snooze when the user chooses "Remind me in 3 days".
  static const Duration _snoozeDuration = Duration(days: 3);

  // ── Static helpers ──────────────────────────────────────────────────────────

  /// Returns `true` when the dialog should be presented to the user.
  ///
  /// Returns `false` when:
  /// * No message is configured (empty [id] or empty [body]).
  /// * The user permanently dismissed this exact message ID.
  /// * The user snoozed and the snooze period has not yet elapsed.
  static Future<bool> shouldShow({
    required String id,
    required String body,
  }) async {
    if (id.isEmpty || body.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Permanently dismissed for this ID?
      final dismissedId = prefs.getString(_dismissedIdKey) ?? '';
      if (dismissedId == id) return false;

      // Within snooze window?
      final remindAfter = prefs.getInt(_remindAfterKey) ?? 0;
      final remindAfterId = prefs.getString(_remindAfterIdKey) ?? '';
      final now = DateTime.now().millisecondsSinceEpoch;
      if (remindAfter > now && remindAfterId == id) return false;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Permanently dismisses the dialog for [id].
  static Future<void> _dismiss(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedIdKey, id);
      // Clear any snooze so the dismissed state is clean.
      await prefs.remove(_remindAfterKey);
      await prefs.remove(_remindAfterIdKey);
    } catch (_) {}
  }

  /// Sets the snooze timestamp so the dialog reappears after [_snoozeDuration].
  static Future<void> _snooze(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindAfter =
          DateTime.now().add(_snoozeDuration).millisecondsSinceEpoch;
      await prefs.setInt(_remindAfterKey, remindAfter);
      await prefs.setString(_remindAfterIdKey, id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final displayTitle = title.isNotEmpty ? title : l10n.serverMessageDefaultTitle;

    return PopScope(
      // Barrier dismiss / back button → treated as "remind later".
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && result == null) await _snooze(messageId);
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.campaign_outlined, color: colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayTitle,
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
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              AnalyticsService.logFeatureUsed(
                featureName: 'server_message_dismissed',
                parameters: {'message_id': messageId},
              );
              await _dismiss(messageId);
              if (context.mounted) Navigator.of(context).pop('dismissed');
            },
            child: Text(
              l10n.serverMessageDismiss,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              AnalyticsService.logFeatureUsed(
                featureName: 'server_message_snoozed',
                parameters: {'message_id': messageId},
              );
              await _snooze(messageId);
              if (context.mounted) Navigator.of(context).pop('snoozed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: Text(l10n.serverMessageRemindLater),
          ),
        ],
      ),
    );
  }
}
