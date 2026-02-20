import 'package:shared_preferences/shared_preferences.dart';
import 'dev_limits.dart';

/// Enforces in-app rate limits for users on the developer Groq key.
///
/// All methods are static. Call them only when
/// [ModelState.usingDeveloperGroqKey] is true.
///
/// Limits are configured in [dev_limits.dart].
class DevRateLimiter {
  static const String _requestTimestampsKey = 'dev_rate_request_timestamps';
  static const String _photoDailyCountKey = 'dev_rate_photo_daily_count';
  static const String _photoDailyDateKey = 'dev_rate_photo_daily_date';

  // ----------------------------------------------------------------
  // Per-minute request limit
  // ----------------------------------------------------------------

  /// Checks whether a new AI request is within the per-minute limit.
  ///
  /// Returns `true` and records the timestamp if allowed.
  /// Returns `false` (without recording) if the limit is exceeded.
  static Future<bool> checkAndRecordRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));

    final raw = prefs.getStringList(_requestTimestampsKey) ?? [];
    final recent = raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .where((d) => d.isAfter(windowStart))
        .toList();

    if (recent.length >= devMaxRequestsPerMinute) {
      return false;
    }

    recent.add(now);
    await prefs.setStringList(
      _requestTimestampsKey,
      recent.map((d) => d.toIso8601String()).toList(),
    );
    return true;
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
  // Helpers
  // ----------------------------------------------------------------

  static String _todayString() {
    final d = DateTime.now().toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
