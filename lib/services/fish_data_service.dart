import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fish.dart';

/// Centralized service for loading and caching fish data
/// This prevents multiple redundant loads of the fishcompat.json file
class FishDataService {
  Map<String, List<Fish>>? _cachedFishData;
  
  /// Load fish data from assets
  /// Returns cached data if available, otherwise loads and caches it
  Future<Map<String, List<Fish>>> loadFishData() async {
    if (_cachedFishData != null) {
      return _cachedFishData!;
    }
    
    final jsonString = await rootBundle.loadString('assets/fishcompat.json');
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

  /// Load raw fish data JSON for tag initialization
  /// Returns the raw JSON data with common names intact
  Future<Map<String, List<dynamic>>> loadRawFishData() async {
    final jsonString = await rootBundle.loadString('assets/fishcompat.json');
    final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
    
    final fishData = <String, List<dynamic>>{};
    for (final category in ['freshwater', 'marine']) {
      if (jsonResponse.containsKey(category)) {
        fishData[category] = jsonResponse[category] as List<dynamic>;
      }
    }
    
    return fishData;
  }
  
  /// Clear cached data (useful for testing or when data needs to be refreshed)
  void clearCache() {
    _cachedFishData = null;
  }
  
  /// Get fish data for a specific category without loading
  /// Returns null if data hasn't been loaded yet
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

