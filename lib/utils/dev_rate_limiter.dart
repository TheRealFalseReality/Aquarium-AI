import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_id_service.dart';
import '../services/remote_config_service.dart';

/// Result of a rate-limit check.
enum DevRateLimitResult {
  /// The request is allowed and has been recorded.
  allowed,

  /// The per-minute limit has been reached. Call [DevRateLimiter.secondsUntilNextSlot]
  /// to find out how long the user must wait.
  minuteLimitReached,

  /// The per-day limit has been reached. The user must wait until tomorrow.
  dailyLimitReached,
}

/// Enforces in-app rate limits for users on the developer Groq key.
///
/// All methods are static. Call them only when
/// [ModelState.usingDeveloperGroqKeyForText] or
/// [ModelState.usingDeveloperGroqKeyForImage] is true.
///
/// Limits are fetched at runtime from [RemoteConfigService], with
/// the in-app fallback defaults used when Firebase is unreachable.
///
/// All [SharedPreferences] keys are prefixed with a per-device identifier
/// provided by [DeviceIdService] so that limits are scoped to the device
/// rather than to a global, easily-guessable key name.
class DevRateLimiter {
  static const String _requestTimestampsSuffix = 'dev_rate_request_timestamps';
  static const String _requestDailyCountSuffix = 'dev_rate_request_daily_count';
  static const String _requestDailyDateSuffix = 'dev_rate_request_daily_date';
  static const String _photoDailyCountSuffix = 'dev_rate_photo_daily_count';
  static const String _photoDailyDateSuffix = 'dev_rate_photo_daily_date';

  /// Returns a SharedPreferences key scoped to [deviceId].
  static String _key(String deviceId, String suffix) => '${deviceId}_$suffix';

  // ----------------------------------------------------------------
  // Per-minute + per-day request limit
  // ----------------------------------------------------------------

  /// Checks whether a new AI request is within both the per-minute and per-day
  /// limits.
  ///
  /// Checks are applied in this order:
  /// 1. Per-day limit — returns [DevRateLimitResult.dailyLimitReached] if exceeded.
  /// 2. Per-minute limit — returns [DevRateLimitResult.minuteLimitReached] if exceeded.
  ///
  /// On success, records the timestamp and increments the daily counter, then
  /// returns [DevRateLimitResult.allowed].
  static Future<DevRateLimitResult> checkAndRecordRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();
    final now = DateTime.now();
    final todayStr = _todayString();

    final requestTimestampsKey = _key(deviceId, _requestTimestampsSuffix);
    final requestDailyCountKey = _key(deviceId, _requestDailyCountSuffix);
    final requestDailyDateKey = _key(deviceId, _requestDailyDateSuffix);

    // --- per-day check ---
    final storedDate = prefs.getString(requestDailyDateKey) ?? '';
    final dailyCount = storedDate == todayStr
        ? (prefs.getInt(requestDailyCountKey) ?? 0)
        : 0;
    if (dailyCount >= RemoteConfigService.maxRequestsPerDay) {
      return DevRateLimitResult.dailyLimitReached;
    }

    // --- per-minute check ---
    final windowStart = now.subtract(const Duration(minutes: 1));
    final raw = prefs.getStringList(requestTimestampsKey) ?? [];
    final recent = raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((d) => d.isAfter(windowStart))
        .toList();

    if (recent.length >= RemoteConfigService.maxRequestsPerMinute) {
      return DevRateLimitResult.minuteLimitReached;
    }

    // --- record ---
    recent.add(now);
    await prefs.setStringList(
      requestTimestampsKey,
      recent.map((d) => d.toIso8601String()).toList(),
    );
    await prefs.setString(requestDailyDateKey, todayStr);
    await prefs.setInt(requestDailyCountKey, dailyCount + 1);

    return DevRateLimitResult.allowed;
  }

  /// Returns the number of seconds until the oldest in-window request
  /// expires (i.e. how long the user must wait before the next slot opens).
  ///
  /// Returns 0 if a slot is already available.
  static Future<int> secondsUntilNextSlot() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));

    final raw = prefs.getStringList(_key(deviceId, _requestTimestampsSuffix)) ?? [];
    final recent = raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((d) => d.isAfter(windowStart))
        .toList();

    if (recent.length < RemoteConfigService.maxRequestsPerMinute) return 0;

    recent.sort();
    final oldest = recent.first;
    final expiresAt = oldest.add(const Duration(minutes: 1));
    final remaining = expiresAt.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Returns the number of AI requests remaining today.
  static Future<int> remainingRequestsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();
    final todayStr = _todayString();

    final storedDate = prefs.getString(_key(deviceId, _requestDailyDateSuffix)) ?? '';
    final count = storedDate == todayStr
        ? (prefs.getInt(_key(deviceId, _requestDailyCountSuffix)) ?? 0)
        : 0;

    final remaining = RemoteConfigService.maxRequestsPerDay - count;
    return remaining > 0 ? remaining : 0;
  }

  // ----------------------------------------------------------------
  // Daily photo analysis limit
  // ----------------------------------------------------------------

  /// Checks whether a new photo analysis is within today's daily limit.
  ///
  /// Returns `true` and increments the counter if allowed.
  /// Returns `false` (without incrementing) if the limit is exceeded.
  static Future<bool> checkAndRecordPhotoAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();
    final todayStr = _todayString();

    final photoDailyCountKey = _key(deviceId, _photoDailyCountSuffix);
    final photoDailyDateKey = _key(deviceId, _photoDailyDateSuffix);

    final storedDate = prefs.getString(photoDailyDateKey) ?? '';
    int count = storedDate == todayStr
        ? (prefs.getInt(photoDailyCountKey) ?? 0)
        : 0;

    if (count >= RemoteConfigService.maxPhotoAnalysesPerDay) {
      return false;
    }

    await prefs.setString(photoDailyDateKey, todayStr);
    await prefs.setInt(photoDailyCountKey, count + 1);
    return true;
  }

  /// Returns the number of photo analyses remaining for today.
  static Future<int> remainingPhotoAnalysesToday() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();
    final todayStr = _todayString();

    final storedDate = prefs.getString(_key(deviceId, _photoDailyDateSuffix)) ?? '';
    final count = storedDate == todayStr
        ? (prefs.getInt(_key(deviceId, _photoDailyCountSuffix)) ?? 0)
        : 0;

    final remaining = RemoteConfigService.maxPhotoAnalysesPerDay - count;
    return remaining > 0 ? remaining : 0;
  }

  // ----------------------------------------------------------------
  // Rollback helpers (call when an AI request results in an error)
  // ----------------------------------------------------------------

  /// Removes the most recently recorded per-minute request timestamp and
  /// decrements the daily count so that a failed AI call does not count
  /// against the user's rate limits.
  static Future<void> undoLastRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));

    final requestTimestampsKey = _key(deviceId, _requestTimestampsSuffix);
    final requestDailyCountKey = _key(deviceId, _requestDailyCountSuffix);
    final requestDailyDateKey = _key(deviceId, _requestDailyDateSuffix);

    // Undo per-minute slot
    final raw = prefs.getStringList(requestTimestampsKey) ?? [];
    final recent = raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((d) => d.isAfter(windowStart))
        .toList();

    if (recent.isNotEmpty) {
      recent.sort();
      recent.removeLast();
      await prefs.setStringList(
        requestTimestampsKey,
        recent.map((d) => d.toIso8601String()).toList(),
      );
    }

    // Undo daily count
    final todayStr = _todayString();
    final storedDate = prefs.getString(requestDailyDateKey) ?? '';
    if (storedDate == todayStr) {
      final count = prefs.getInt(requestDailyCountKey) ?? 0;
      if (count > 0) {
        await prefs.setInt(requestDailyCountKey, count - 1);
      }
    }
  }

  /// Decrements today's photo analysis count by 1 so that a failed photo
  /// analysis call does not count against the daily limit.
  static Future<void> undoPhotoAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();
    final todayStr = _todayString();

    final photoDailyCountKey = _key(deviceId, _photoDailyCountSuffix);
    final photoDailyDateKey = _key(deviceId, _photoDailyDateSuffix);

    final storedDate = prefs.getString(photoDailyDateKey) ?? '';
    if (storedDate != todayStr) return;

    final count = prefs.getInt(photoDailyCountKey) ?? 0;
    if (count <= 0) return;

    await prefs.setInt(photoDailyCountKey, count - 1);
  }

  // ----------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------

  static String _todayString() {
    final d = DateTime.now().toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
