import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../utils/dev_limits.dart';

/// Key names used in Firebase Remote Config.
///
/// Set these keys in the Firebase Console → Remote Config to override the
/// in-app defaults without shipping an app update.
class RemoteConfigKeys {
  /// Boolean — when `false` the built-in developer Groq key is disabled and
  /// users must supply their own API key.  Defaults to `true`.
  static const String freeAiEnabled = 'free_ai_enabled';

  /// Integer — per-minute request cap for the free (developer-key) tier.
  static const String devMaxRequestsPerMinute = 'dev_max_requests_per_minute';

  /// Integer — per-day request cap for the free (developer-key) tier.
  static const String devMaxRequestsPerDay = 'dev_max_requests_per_day';

  /// Integer — per-day photo-analysis cap for the free (developer-key) tier.
  static const String devMaxPhotoAnalysesPerDay =
      'dev_max_photo_analyses_per_day';
}

/// Thin wrapper around [FirebaseRemoteConfig] that provides server-side
/// control over the in-app free AI (developer Groq key) feature.
///
/// Call [initialize] once during app startup (after Firebase.initializeApp).
/// All getters return safe local defaults if Remote Config is unavailable.
class RemoteConfigService {
  static FirebaseRemoteConfig? _instance;

  /// Initialise Remote Config, apply in-app defaults, then fetch & activate
  /// the latest values from the server.
  ///
  /// Errors are caught and logged; the service gracefully falls back to the
  /// in-app defaults defined in [dev_limits.dart].
  static Future<void> initialize() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set in-app defaults so the app works correctly even before the first
      // successful fetch or when offline.
      await remoteConfig.setDefaults({
        RemoteConfigKeys.freeAiEnabled: true,
        RemoteConfigKeys.devMaxRequestsPerMinute: devMaxRequestsPerMinute,
        RemoteConfigKeys.devMaxRequestsPerDay: devMaxRequestsPerDay,
        RemoteConfigKeys.devMaxPhotoAnalysesPerDay: devMaxPhotoAnalysesPerDay,
      });

      // Refresh at most once per hour in production; more frequently in debug.
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // Fetch and activate in one step; ignore errors (e.g. no network).
      await remoteConfig.fetchAndActivate();

      _instance = remoteConfig;

      if (kDebugMode) {
        debugPrint(
          '[RemoteConfigService] Loaded — '
          'freeAiEnabled=${freeAiEnabled}, '
          'maxReqPerMin=$maxRequestsPerMinute, '
          'maxReqPerDay=$maxRequestsPerDay, '
          'maxPhotosPerDay=$maxPhotoAnalysesPerDay',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RemoteConfigService] Initialization error: $e');
        debugPrint('[RemoteConfigService] Using in-app defaults.');
      }
      // _instance stays null → all getters return local defaults.
    }
  }

  // ---------------------------------------------------------------------------
  // Getters — return Remote Config value when available, else local default
  // ---------------------------------------------------------------------------

  /// Whether the built-in developer Groq key (free AI tier) is enabled.
  /// The developer can set this to `false` in Firebase Remote Config to
  /// disable the free tier for all users without shipping an app update.
  static bool get freeAiEnabled =>
      _instance?.getBool(RemoteConfigKeys.freeAiEnabled) ?? true;

  /// Per-minute request limit for the free (developer-key) tier.
  static int get maxRequestsPerMinute =>
      _instance?.getInt(RemoteConfigKeys.devMaxRequestsPerMinute) ??
      devMaxRequestsPerMinute;

  /// Per-day request limit for the free (developer-key) tier.
  static int get maxRequestsPerDay =>
      _instance?.getInt(RemoteConfigKeys.devMaxRequestsPerDay) ??
      devMaxRequestsPerDay;

  /// Per-day photo-analysis limit for the free (developer-key) tier.
  static int get maxPhotoAnalysesPerDay =>
      _instance?.getInt(RemoteConfigKeys.devMaxPhotoAnalysesPerDay) ??
      devMaxPhotoAnalysesPerDay;
}
