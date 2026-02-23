import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fish.dart';
import 'remote_config_service.dart';

// SharedPreferences key for the persistent fish-compat cache.
const String _prefKeyJson = 'fishcompat_cached_json';

/// Centralized service for loading and caching fish data.
///
/// Data is sourced in priority order:
///   1. In-memory cache (fastest — cleared when [clearCache] is called).
///   2. Firebase Remote Config [RemoteConfigKeys.fishcompatJson] (allows
///      updating fish data without an app-store release).  The loaded value is
///      persisted to SharedPreferences so offline re-launches can use it.
///   3. SharedPreferences persistent cache (the last value fetched from RC;
///      used when RC is unavailable on the current launch).
///   4. Bundled local asset `assets/fishcompat.json` (always available offline).
class FishDataService {
  Map<String, List<Fish>>? _cachedFishData;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Returns the raw JSON string for the fish-compat dataset.
  ///
  /// Tries [RemoteConfigService.fishcompatJson] first.  When RC has data the
  /// value is also written to SharedPreferences so future offline launches can
  /// use it.  Falls back to the SP cache and finally to the bundled local asset.
  Future<String> _getJsonString() async {
    // RC takes priority when set.
    final rcJson = RemoteConfigService.fishcompatJson;
    if (rcJson.isNotEmpty) {
      // Persist RC data for subsequent offline launches.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyJson, rcJson);
      return rcJson;
    }

    // No RC data: try the persistent cache (from a previous RC fetch).
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_prefKeyJson);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      return cachedJson;
    }

    // Final fallback: bundled local asset.
    return rootBundle.loadString('assets/fishcompat.json');
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Load fish data, returning typed [Fish] objects grouped by category.
  ///
  /// Returns the in-memory cache when data is already loaded.  Otherwise loads
  /// from Remote Config, the persistent SP cache, or the bundled local asset
  /// (in that order).
  Future<Map<String, List<Fish>>> loadFishData() async {
    if (_cachedFishData != null) {
      return _cachedFishData!;
    }

    final jsonString = await _getJsonString();
    final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;

    final fishData = <String, List<Fish>>{};
    for (final category in ['freshwater', 'marine']) {
      if (jsonResponse.containsKey(category)) {
        fishData[category] = (jsonResponse[category] as List)
            .map((f) => Fish.fromJson(f))
            .toList();
      }
    }

    _cachedFishData = fishData;
    return fishData;
  }

  /// Load raw fish data JSON for tag initialization.
  ///
  /// Returns the raw JSON data with common names intact.  Uses the same
  /// source priority as [loadFishData] (Remote Config → SP cache → local asset).
  Future<Map<String, List<dynamic>>> loadRawFishData() async {
    final jsonString = await _getJsonString();
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
  /// The next call to [loadFishData] will reload from Remote Config, the
  /// persistent SP cache, or the local asset.
  /// Use [clearPersistentCache] as well when you need a full reset.
  void clearCache() {
    _cachedFishData = null;
  }

  /// Clear both the in-memory cache and the SharedPreferences persistent cache.
  ///
  /// The next call to [loadFishData] will reload from Remote Config or the
  /// local asset.  Intended for testing and manual refresh scenarios.
  Future<void> clearPersistentCache() async {
    clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyJson);
  }

  /// Get fish data for a specific category without loading.
  /// Returns null if data hasn't been loaded yet.
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

