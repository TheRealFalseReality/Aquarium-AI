import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fish.dart';

/// SharedPreferences key used to persist the user's custom fish library.
const String _prefKeyCustomFish = 'custom_fish_data';

/// Service for creating, reading, updating, and deleting user-defined custom
/// fish types.  All data is persisted locally in [SharedPreferences] and is
/// included in the full backup/restore flow.
class CustomFishService {
  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<List<Fish>> _readFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyCustomFish);
      if (raw == null || raw.isEmpty) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => Fish.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CustomFishService: read failed ($e)');
      }
      return [];
    }
  }

  Future<void> _writeToPrefs(List<Fish> fish) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      fish.map((f) => f.toJson()).toList(),
    );
    await prefs.setString(_prefKeyCustomFish, encoded);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Load all custom fish from local storage.
  Future<List<Fish>> loadCustomFish() => _readFromPrefs();

  /// Persist [fish] to local storage, replacing any existing entry with the
  /// same [Fish.uuid].  If no matching UUID is found the fish is appended.
  Future<void> saveOrUpdateFish(Fish fish) async {
    final all = await _readFromPrefs();
    final idx = all.indexWhere((f) => f.uuid == fish.uuid);
    if (idx >= 0) {
      all[idx] = fish;
    } else {
      all.add(fish);
    }
    await _writeToPrefs(all);
  }

  /// Remove the custom fish with the given [uuid].  Does nothing if no match
  /// is found.
  Future<void> deleteFish(String uuid) async {
    final all = await _readFromPrefs();
    all.removeWhere((f) => f.uuid == uuid);
    await _writeToPrefs(all);
  }

  /// Export all custom fish as raw JSON-serialisable maps for inclusion in a
  /// backup file.  Local image paths are excluded so restores work across
  /// devices.
  List<Map<String, dynamic>> exportCustomFish(List<Fish> fish) {
    return fish.map((f) => f.toJson(includeLocalPaths: false)).toList();
  }

  /// Import custom fish from a backup file, replacing the entire local list.
  Future<void> importCustomFish(List<dynamic> rawList) async {
    final fish = rawList
        .map((e) => Fish.fromJson(e as Map<String, dynamic>))
        .toList();
    await _writeToPrefs(fish);
  }

  /// Clear all custom fish from local storage.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyCustomFish);
  }
}
