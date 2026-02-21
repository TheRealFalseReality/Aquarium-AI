import 'package:shared_preferences/shared_preferences.dart';
import 'dev_limits.dart';

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
/// Limits are configured in [dev_limits.dart].
class DevRateLimiter {
  static const String _requestTimestampsKey = 'dev_rate_request_timestamps';
  static const String _requestDailyCountKey = 'dev_rate_request_daily_count';
  static const String _requestDailyDateKey = 'dev_rate_request_daily_date';
  static const String _photoDailyCountKey = 'dev_rate_photo_daily_count';
  static const String _photoDailyDateKey = 'dev_rate_photo_daily_date';

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
    final now = DateTime.now();
    final todayStr = _todayString();

    // --- per-day check ---
    final storedDate = prefs.getString(_requestDailyDateKey) ?? '';
    final dailyCount = storedDate == todayStr
        ? (prefs.getInt(_requestDailyCountKey) ?? 0)
        : 0;
    if (dailyCount >= devMaxRequestsPerDay) {
      return DevRateLimitResult.dailyLimitReached;
    }

    // --- per-minute check ---
    final windowStart = now.subtract(const Duration(minutes: 1));
    final raw = prefs.getStringList(_requestTimestampsKey) ?? [];
    final recent = raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((d) => d.isAfter(windowStart))
        .toList();

    if (recent.length >= devMaxRequestsPerMinute) {
      return DevRateLimitResult.minuteLimitReached;
    }

    // --- record ---
    recent.add(now);
    await prefs.setStringList(
      _requestTimestampsKey,
      recent.map((d) => d.toIso8601String()).toList(),
    );
    await prefs.setString(_requestDailyDateKey, todayStr);
    await prefs.setInt(_requestDailyCountKey, dailyCount + 1);

    return DevRateLimitResult.allowed;
  }

  /// Returns the number of seconds until the oldest in-window request
  /// expires (i.e. how long the user must wait before the next slot opens).
  ///
  /// Returns 0 if a slot is already available.
  static Future<int> secondsUntilNextSlot() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));

    final raw = prefs.getStringList(_requestTimestampsKey) ?? [];
    final recent = raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((d) => d.isAfter(windowStart))
        .toList();

    if (recent.length < devMaxRequestsPerMinute) return 0;

    recent.sort();
    final oldest = recent.first;
    final expiresAt = oldest.add(const Duration(minutes: 1));
    final remaining = expiresAt.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Returns the number of AI requests remaining today.
  static Future<int> remainingRequestsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _todayString();

    final storedDate = prefs.getString(_requestDailyDateKey) ?? '';
    final count = storedDate == todayStr
        ? (prefs.getInt(_requestDailyCountKey) ?? 0)
        : 0;

    final remaining = devMaxRequestsPerDay - count;
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
    final todayStr = _todayString();

    final storedDate = prefs.getString(_photoDailyDateKey) ?? '';
    int count = storedDate == todayStr
        ? (prefs.getInt(_photoDailyCountKey) ?? 0)
        : 0;

    if (count >= devMaxPhotoAnalysesPerDay) {
      return false;
    }

    await prefs.setString(_photoDailyDateKey, todayStr);
    await prefs.setInt(_photoDailyCountKey, count + 1);
    return true;
  }

  /// Returns the number of photo analyses remaining for today.
  static Future<int> remainingPhotoAnalysesToday() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _todayString();

    final storedDate = prefs.getString(_photoDailyDateKey) ?? '';
    final count = storedDate == todayStr
        ? (prefs.getInt(_photoDailyCountKey) ?? 0)
        : 0;

    final remaining = devMaxPhotoAnalysesPerDay - count;
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
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));

    // Undo per-minute slot
    final raw = prefs.getStringList(_requestTimestampsKey) ?? [];
    final recent = raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((d) => d.isAfter(windowStart))
        .toList();

    if (recent.isNotEmpty) {
      recent.sort();
      recent.removeLast();
      await prefs.setStringList(
        _requestTimestampsKey,
        recent.map((d) => d.toIso8601String()).toList(),
      );
    }

    // Undo daily count
    final todayStr = _todayString();
    final storedDate = prefs.getString(_requestDailyDateKey) ?? '';
    if (storedDate == todayStr) {
      final count = prefs.getInt(_requestDailyCountKey) ?? 0;
      if (count > 0) {
        await prefs.setInt(_requestDailyCountKey, count - 1);
      }
    }
  }

  /// Decrements today's photo analysis count by 1 so that a failed photo
  /// analysis call does not count against the daily limit.
  static Future<void> undoPhotoAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _todayString();

    final storedDate = prefs.getString(_photoDailyDateKey) ?? '';
    if (storedDate != todayStr) return;

    final count = prefs.getInt(_photoDailyCountKey) ?? 0;
    if (count <= 0) return;

    await prefs.setInt(_photoDailyCountKey, count - 1);
  }

  // ----------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------

  static String _todayString() {
    final d = DateTime.now().toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
