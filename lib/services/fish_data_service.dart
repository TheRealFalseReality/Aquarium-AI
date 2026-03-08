import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fish.dart';
import 'fish_firestore_service.dart';

// ---------------------------------------------------------------------------
// Firestore data priority:
//   1. In-memory cache
//   2. Cloud Firestore (fish_compat collection) — persisted to SP on success
//   3. SharedPreferences (last successful Firestore fetch) — offline fallback
//   4. Bundled local asset (assets/data/fishcompat.json) — last resort
// ---------------------------------------------------------------------------

/// SharedPreferences key used to persist the last successful Firestore fetch
/// so that subsequent offline launches can use it instead of the bundled asset.
const String _prefKeyJson = 'fishcompat_cached_json';

/// SharedPreferences key storing the epoch-millisecond timestamp of the last
/// successful Firestore fetch.  Used to enforce the 12-hour refresh cooldown.
const String _prefKeyLastFetchMs = 'fishcompat_last_fetch_ms';

/// Minimum time between Firestore fetches.  If the SP cache is younger than
/// this, the app skips Firestore and uses the cached data immediately.
const Duration _fetchCooldown = Duration(hours: 12);

/// Centralised service for loading and caching fish data.
///
/// Data is sourced in priority order:
///   1. In-memory cache (fastest — cleared when [clearCache] is called).
///   2. Cloud Firestore [FishFirestoreService.fetchFishData] (real-time
///      updates).  On success the result is persisted to SharedPreferences.
///   3. SharedPreferences persistent cache (the data from the last successful
///      Firestore fetch).  Used when Firestore is unreachable / offline.
///   4. Bundled local asset `assets/data/fishcompat.json` (always available
///      offline, used as the last-resort fallback).
class FishDataService {
  Map<String, List<Fish>>? _cachedFishData;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Parse a `{category: [{...}, ...]}` map (from JSON or Firestore) into
  /// typed [Fish] lists sorted alphabetically by name.
  Map<String, List<Fish>> _parseFishMap(Map<String, dynamic> raw) {
    final fishData = <String, List<Fish>>{};
    for (final category in ['freshwater', 'marine']) {
      if (raw.containsKey(category)) {
        final list = (raw[category] as List)
            .map((f) => Fish.fromJson(f as Map<String, dynamic>))
            .toList();
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        fishData[category] = list;
      }
    }
    return fishData;
  }

  /// Persist [firestoreData] to SharedPreferences so it is available on the
  /// next offline launch.  Errors are swallowed — persistence is best-effort.
  Future<void> _persistToSpCache(
    Map<String, List<Map<String, dynamic>>> firestoreData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyJson, json.encode(firestoreData));
      // Record the current time so we can enforce the fetch cooldown.
      await prefs.setInt(
        _prefKeyLastFetchMs,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FishDataService: SP persist failed ($e)');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Load fish data, returning typed [Fish] objects grouped by category.
  ///
  /// Returns the in-memory cache when data is already loaded.  Otherwise tries
  /// each source in priority order until one succeeds.
  ///
  /// A 12-hour cooldown is enforced on Firestore fetches: if a fresh SP cache
  /// exists (younger than [_fetchCooldown]) the SP cache is returned directly
  /// without contacting Firestore.
  Future<Map<String, List<Fish>>> loadFishData() async {
    if (_cachedFishData != null) {
      return _cachedFishData!;
    }

    // Check whether a fresh SP cache exists.  If so, skip Firestore entirely
    // to avoid an unnecessary network round-trip on every app launch.
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchMs = prefs.getInt(_prefKeyLastFetchMs);
      if (lastFetchMs != null) {
        final age = Duration(
          milliseconds:
              DateTime.now().millisecondsSinceEpoch - lastFetchMs,
        );
        if (age < _fetchCooldown) {
          // Cache is fresh — load from SP without contacting Firestore.
          final cachedJson = prefs.getString(_prefKeyJson);
          if (cachedJson != null && cachedJson.isNotEmpty) {
            final raw = json.decode(cachedJson) as Map<String, dynamic>;
            final fishData = _parseFishMap(raw);
            if (fishData.isNotEmpty) {
              if (kDebugMode) {
                debugPrint(
                  'FishDataService: cache is ${age.inMinutes} min old '
                  '(< ${_fetchCooldown.inHours}h), skipping Firestore.',
                );
              }
              _cachedFishData = fishData;
              return fishData;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FishDataService: cooldown check failed ($e)');
      }
    }

    // 1. Try Firestore (real-time source). Use a short timeout so a slow or
    //    unavailable network doesn't block app startup.
    try {
      final firestoreData = await FishFirestoreService.fetchFishData()
          .timeout(const Duration(seconds: 5));
      if (firestoreData != null && firestoreData.isNotEmpty) {
        final fishData = _parseFishMap(
          // Map<String, List<Map<String,dynamic>>> → Map<String, dynamic>
          firestoreData.map((k, v) => MapEntry(k, v)),
        );
        if (fishData.isNotEmpty) {
          // Persist to SP so the next offline launch can use this data.
          await _persistToSpCache(firestoreData);
          _cachedFishData = fishData;
          return fishData;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'FishDataService: Firestore fetch failed ($e), trying SP cache.',
        );
      }
    }

    // 2. Try the SharedPreferences cache (data from the last successful
    //    Firestore fetch).  Useful when the device is offline.
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefKeyJson);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final raw = json.decode(cachedJson) as Map<String, dynamic>;
        final fishData = _parseFishMap(raw);
        if (fishData.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('FishDataService: using SP cache (offline).');
          }
          _cachedFishData = fishData;
          return fishData;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'FishDataService: SP cache failed ($e), using local asset.',
        );
      }
    }

    // 3. Fall back to the bundled local asset (always available offline).
    final jsonString = await rootBundle.loadString(
      'assets/data/fishcompat.json',
    );
    final fishData = _parseFishMap(
      json.decode(jsonString) as Map<String, dynamic>,
    );
    _cachedFishData = fishData;
    return fishData;
  }

  /// Load raw fish data JSON for tag initialisation.
  ///
  /// Always reads directly from the bundled local asset so the full
  /// common-name arrays are available without Firestore access.
  Future<Map<String, List<dynamic>>> loadRawFishData() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/fishcompat.json',
    );
    final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;

    final fishData = <String, List<dynamic>>{};
    for (final category in ['freshwater', 'marine']) {
      if (jsonResponse.containsKey(category)) {
        fishData[category] = jsonResponse[category] as List<dynamic>;
      }
    }
    return fishData;
  }

  /// Clear the in-memory cache.
  ///
  /// The next call to [loadFishData] will reload from Firestore, the SP cache,
  /// or the local asset.
  void clearCache() {
    _cachedFishData = null;
  }

  /// Clear both the in-memory cache and the SharedPreferences persistent cache.
  ///
  /// The next call to [loadFishData] will reload from Firestore or the local
  /// asset.  Useful for testing and manual refresh scenarios.
  Future<void> clearPersistentCache() async {
    clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyJson);
    await prefs.remove(_prefKeyLastFetchMs);
  }

  /// Get fish data for a specific category without triggering a load.
  /// Returns null if data has not been loaded yet.
  List<Fish>? getCachedFishByCategory(String category) {
    return _cachedFishData?[category];
  }
}

/// Provider for FishDataService singleton
final fishDataServiceProvider = Provider<FishDataService>((ref) {
  return FishDataService();
});

/// Provider that loads and provides fish data using AsyncValue
/// This automatically handles loading, error, and data states
final fishDataProvider = FutureProvider<Map<String, List<Fish>>>((ref) async {
  final service = ref.watch(fishDataServiceProvider);
  return service.loadFishData();
});
