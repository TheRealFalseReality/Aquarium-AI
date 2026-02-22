import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provides a stable, per-device identifier used to namespace rate-limit data.
///
/// **iOS** — uses [IosDeviceInfo.identifierForVendor], which is managed by the
/// OS, survives app reinstalls, and is not stored in SharedPreferences.
///
/// **All other platforms** — generates a UUID on the first launch and persists
/// it in [SharedPreferences] under [_deviceIdKey].  The key is intentionally
/// separate from the rate-limit storage keys so it is not accidentally cleared
/// alongside rate-limit data when only rate-limit preferences are reset.
///
/// The result is cached in memory after the first successful resolution so that
/// subsequent calls within the same process are effectively synchronous.
class DeviceIdService {
  /// The SharedPreferences key used to store the generated UUID.
  /// This is NOT the same key namespace used for rate-limit data.
  static const String _deviceIdKey = 'app_device_id';

  static String? _cachedId;

  /// Returns a stable device identifier, generating one when necessary.
  ///
  /// Safe to call multiple times — the result is cached after the first
  /// successful resolution.
  static Future<String> getDeviceId() async {
    _cachedId ??= await _resolveId();
    return _cachedId!;
  }

  static Future<String> _resolveId() async {
    // iOS: delegate to the OS-managed identifierForVendor.
    if (!kIsWeb && Platform.isIOS) {
      try {
        final info = await DeviceInfoPlugin().iosInfo;
        final vendorId = info.identifierForVendor;
        if (vendorId != null && vendorId.isNotEmpty) return vendorId;
      } catch (_) {
        // Fall through to UUID fallback if the plugin call fails.
      }
    }

    // Android and all other platforms: use a UUID persisted in SharedPreferences.
    return _persistedUuid();
  }

  /// Loads the existing UUID from [SharedPreferences], generating and storing
  /// a new one if none is found.
  static Future<String> _persistedUuid() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final newId = const Uuid().v4();
    await prefs.setString(_deviceIdKey, newId);
    return newId;
  }

  // ---------------------------------------------------------------------------
  // Test helpers — not intended for production use
  // ---------------------------------------------------------------------------

  /// Overrides the cached device ID.  Call this in tests to control the device
  /// ID used by [DevRateLimiter] without touching [SharedPreferences].
  @visibleForTesting
  static void setDeviceIdForTesting(String id) => _cachedId = id;

  /// Clears the in-memory cache so [getDeviceId] performs a fresh resolution
  /// on the next call.  Useful for unit tests that need to test the full
  /// resolution path.
  @visibleForTesting
  static void resetForTesting() => _cachedId = null;
}
