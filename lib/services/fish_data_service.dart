import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fish.dart';
import 'fish_firestore_service.dart';

// ---------------------------------------------------------------------------
// Firestore data priority:
//   1. In-memory cache
//   2. Cloud Firestore (fish_compat collection)
//   3. Bundled local asset (assets/data/fishcompat.json)
// ---------------------------------------------------------------------------

/// Centralized service for loading and caching fish data.
///
/// Data is sourced in priority order:
///   1. In-memory cache (fastest — cleared when [clearCache] is called).
///   2. Cloud Firestore [FishFirestoreService.fetchFishData] (real-time
///      updates; used when the data has been uploaded to Firestore).
///   3. Bundled local asset `assets/data/fishcompat.json` (always available offline).
class FishDataService {
  Map<String, List<Fish>>? _cachedFishData;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Load fish data, returning typed [Fish] objects grouped by category.
  ///
  /// Returns the in-memory cache when data is already loaded.  Otherwise tries:
  ///   1. Cloud Firestore (when data has been uploaded via the debug uploader)
  ///   2. Bundled local asset `assets/data/fishcompat.json`
  Future<Map<String, List<Fish>>> loadFishData() async {
    if (_cachedFishData != null) {
      return _cachedFishData!;
    }

    // 1. Try Firestore first (real-time source). Use a short timeout so a slow
    //    or unavailable network doesn't block the app startup.
    try {
      final firestoreData = await FishFirestoreService.fetchFishData()
          .timeout(const Duration(seconds: 5));
      if (firestoreData != null && firestoreData.isNotEmpty) {
        final fishData = <String, List<Fish>>{};
        for (final category in ['freshwater', 'marine']) {
          final rawList = firestoreData[category];
          if (rawList != null && rawList.isNotEmpty) {
            final list = rawList.map((f) => Fish.fromJson(f)).toList();
            list.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
            fishData[category] = list;
          }
        }
        if (fishData.isNotEmpty) {
          _cachedFishData = fishData;
          return fishData;
        }
      }
    } catch (e) {
      // Firestore unavailable, timed out, or permission denied — fall through
      // to the next data source.
      if (kDebugMode) {
        debugPrint('FishDataService: Firestore fetch failed ($e), using fallback.');
      }
    }

    // 2. Fall back to the bundled local asset.
    final jsonString = await rootBundle.loadString('assets/data/fishcompat.json');
    final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;

    final fishData = <String, List<Fish>>{};
    for (final category in ['freshwater', 'marine']) {
      if (jsonResponse.containsKey(category)) {
        final list = (jsonResponse[category] as List)
            .map((f) => Fish.fromJson(f))
            .toList();
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        fishData[category] = list;
      }
    }

    _cachedFishData = fishData;
    return fishData;
  }

  /// Load raw fish data JSON for tag initialization.
  ///
  /// Always loads directly from the bundled local asset (used for tag
  /// initialization where the full fish list including raw common-name arrays
  /// is needed).
  Future<Map<String, List<dynamic>>> loadRawFishData() async {
    final jsonString = await rootBundle.loadString('assets/data/fishcompat.json');
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
  /// The next call to [loadFishData] will reload from Firestore or the local
  /// asset.
  void clearCache() {
    _cachedFishData = null;
  }

  /// Clear the in-memory cache.
  ///
  /// Kept for API compatibility; no persistent cache exists in this version.
  Future<void> clearPersistentCache() async {
    clearCache();
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
