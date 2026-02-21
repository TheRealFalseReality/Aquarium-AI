import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for customizing Firebase Crashlytics crash reports.
///
/// Provides helpers for setting custom keys, logging messages, identifying
/// users, and recording non-fatal errors so that crash reports in the
/// Firebase console contain rich context for debugging.
///
/// All public methods are safe to call even when Firebase has not been
/// initialized – any failure is silently swallowed so that Crashlytics
/// instrumentation never causes the app itself to crash.
///
/// Reference: https://firebase.google.com/docs/crashlytics/customize-crash-reports
class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // ---------------------------------------------------------------------------
  // Core primitives
  // ---------------------------------------------------------------------------

  /// Sets a [key]/[value] pair that will appear in crash reports.
  ///
  /// Supported value types: [String], [bool], [int], [double].
  static Future<void> setCustomKey(String key, Object value) async {
    try {
      if (value is bool) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is int) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is double) {
        await _crashlytics.setCustomKey(key, value);
      } else {
        await _crashlytics.setCustomKey(key, value.toString());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashlyticsService.setCustomKey error [$key]: $e');
      }
    }
  }

  /// Appends [message] to the Crashlytics log that is uploaded with crash
  /// reports. Messages are visible under the "Logs" tab in the Firebase
  /// console.
  static Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
      if (kDebugMode) {
        debugPrint('Crashlytics log: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashlyticsService.log error: $e');
      }
    }
  }

  /// Associates [identifier] with future crash reports so you can look up all
  /// crashes for a particular user. Pass an empty string to clear the
  /// identifier.
  static Future<void> setUserIdentifier(String identifier) async {
    try {
      await _crashlytics.setUserIdentifier(identifier);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashlyticsService.setUserIdentifier error: $e');
      }
    }
  }

  /// Records a non-fatal [exception] with optional [stack] trace, a human-
  /// readable [reason], and optional [information] lines.
  ///
  /// Set [fatal] to `true` only for errors that should be treated as fatal
  /// in the Firebase console.
  static Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          'Crashlytics recordError [fatal=$fatal, reason=$reason]: $exception',
        );
      }
      await _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
        information: information,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashlyticsService.recordError failed: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Convenience – app context keys
  // ---------------------------------------------------------------------------

  /// Logs app version info (version name + build number) as custom keys.
  /// Should be called once during app startup.
  static Future<void> setAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      await Future.wait([
        setCustomKey('app_version', info.version),
        setCustomKey('app_build_number', info.buildNumber),
        log('App started: ${info.version}+${info.buildNumber}'),
      ]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CrashlyticsService.setAppInfo error: $e');
      }
    }
  }

  /// Updates the `current_screen` custom key whenever the user navigates.
  static Future<void> setCurrentScreen(String screenName) async {
    await Future.wait([
      setCustomKey('current_screen', screenName),
      log('Screen: $screenName'),
    ]);
  }

  /// Updates the `ai_text_provider` custom key when the user changes the
  /// active AI text/chat provider (e.g. "gemini", "openAI", "groq").
  static Future<void> setAITextProvider(String providerName) async {
    await Future.wait([
      setCustomKey('ai_text_provider', providerName),
      log('AI text provider changed: $providerName'),
    ]);
  }

  /// Updates the `ai_image_provider` custom key when the user changes the
  /// active AI image-analysis provider.
  static Future<void> setAIImageProvider(String providerName) async {
    await Future.wait([
      setCustomKey('ai_image_provider', providerName),
      log('AI image provider changed: $providerName'),
    ]);
  }

  /// Updates the `ai_text_model` custom key when the text/chat model changes.
  static Future<void> setAITextModel(String modelName) async {
    await setCustomKey('ai_text_model', modelName);
  }

  /// Updates the `ai_image_model` custom key when the image model changes.
  static Future<void> setAIImageModel(String modelName) async {
    await setCustomKey('ai_image_model', modelName);
  }

  /// Updates the `ai_enabled` custom key when the user toggles AI features.
  static Future<void> setAIEnabled(bool enabled) async {
    await Future.wait([
      setCustomKey('ai_enabled', enabled),
      log('AI features enabled: $enabled'),
    ]);
  }

  /// Updates the `app_locale` custom key when the app locale changes.
  static Future<void> setLocale(String? localeCode) async {
    await setCustomKey('app_locale', localeCode ?? 'system');
  }

  /// Logs a user action message (e.g. "Sent chat message", "Opened photo
  /// analyzer") without associating it with a specific error.
  static Future<void> logAction(String action) async {
    await log('Action: $action');
  }
}
