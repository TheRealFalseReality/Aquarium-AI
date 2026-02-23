import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fish.dart';
import 'remote_config_service.dart';

// SharedPreferences keys for the persistent fish-compat cache.
const String _prefKeyVersion = 'fishcompat_cached_version';
const String _prefKeyJson = 'fishcompat_cached_json';

/// Centralized service for loading and caching fish data.
///
/// Data is sourced in priority order:
///   1. In-memory cache (fastest — cleared when [clearCache] is called or
///      when the Remote Config version changes).
///   2. SharedPreferences persistent cache (survives app restarts; invalidated
///      automatically when the [RemoteConfigKeys.fishcompatVersion] token
///      changes).
///   3. Firebase Remote Config [RemoteConfigKeys.fishcompatJson] (allows
///      updating fish data without an app-store release).
///   4. Bundled local asset `assets/fishcompat.json` (always available offline).
class FishDataService {
  Map<String, List<Fish>>? _cachedFishData;

  /// The Remote Config version string that corresponds to [_cachedFishData].
  /// Used to detect when the server has published a new fish-compat dataset.
  String? _cachedVersion;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Returns the raw JSON string for the fish-compat dataset.
  ///
  /// Checks the SharedPreferences persistent cache first (keyed by the current
  /// [RemoteConfigService.fishcompatVersion]).  When the version has changed —
  /// or no cache exists — the data is fetched from Remote Config
  /// ([RemoteConfigService.fishcompatJson]) and the bundled local asset is used
  /// as the fallback.  The result is written back to SharedPreferences so that
  /// future launches (including offline ones) can use the latest data.
  Future<String> _getJsonString() async {
    final currentVersion = RemoteConfigService.fishcompatVersion;

    final prefs = await SharedPreferences.getInstance();
    final persistedVersion = prefs.getString(_prefKeyVersion);
    final persistedJson = prefs.getString(_prefKeyJson);

    if (persistedVersion == currentVersion &&
        persistedJson != null &&
        persistedJson.isNotEmpty) {
      return persistedJson;
    }

    // Cache miss or version mismatch: load from Remote Config or local asset.
    final rcJson = RemoteConfigService.fishcompatJson;
    final jsonString = rcJson.isNotEmpty
        ? rcJson
        : await rootBundle.loadString('assets/fishcompat.json');

    // Persist the freshly loaded data for subsequent launches.
    await prefs.setString(_prefKeyVersion, currentVersion);
    await prefs.setString(_prefKeyJson, jsonString);

    return jsonString;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Load fish data, returning typed [Fish] objects grouped by category.
  ///
  /// Returns the in-memory cache immediately when the data is already loaded
  /// and the Remote Config version has not changed.  Otherwise reloads from
  /// the persistent cache, Remote Config, or the bundled local asset (in that
  /// order).
  Future<Map<String, List<Fish>>> loadFishData() async {
    final currentVersion = RemoteConfigService.fishcompatVersion;

    if (_cachedFishData != null && _cachedVersion == currentVersion) {
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
    _cachedVersion = currentVersion;
    return fishData;
  }

  /// Load raw fish data JSON for tag initialization.
  ///
  /// Returns the raw JSON data with common names intact.  Uses the same
  /// version-aware JSON source as [loadFishData] (Remote Config → local asset).
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
  /// The next call to [loadFishData] will reload from the persistent cache
  /// (if the version still matches) or from Remote Config / local asset.
  /// Use [clearPersistentCache] as well when you need a full reset.
  void clearCache() {
    _cachedFishData = null;
    _cachedVersion = null;
  }

  /// Clear both the in-memory cache and the SharedPreferences persistent cache.
  ///
  /// The next call to [loadFishData] will always reload from Remote Config or
  /// the local asset.  Intended for testing and manual refresh scenarios.
  Future<void> clearPersistentCache() async {
    clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyVersion);
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

