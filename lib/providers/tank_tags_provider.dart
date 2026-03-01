import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tank.dart';

/// Notifier that maintains a global library of user-created [TankTag]
/// definitions (name + colour).
///
/// The registry mirrors the tags found across all tanks so that tag
/// definitions survive backup/restore independently of individual tank data.
/// Tag names are used as the unique key; if the same name appears in more
/// than one tank the first occurrence (by iteration order) wins.
class TankTagsNotifier extends StateNotifier<List<TankTag>> {
  static const String _storageKey = 'user_tank_tags';

  TankTagsNotifier() : super([]) {
    _loadTags();
  }

  /// Load the global tag library from SharedPreferences.
  Future<void> _loadTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList.map((e) => TankTag.fromJson(e)).toList();
      }
    } catch (_) {
      // Keep the empty default on error.
    }
  }

  /// Persist the current tag library to SharedPreferences.
  Future<void> _saveTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        json.encode(state.map((t) => t.toJson()).toList()),
      );
    } catch (_) {
      // Ignore save errors silently.
    }
  }

  /// Synchronise the global registry with the tags present across [tanks].
  ///
  /// Tags are merged into the existing registry so previously saved
  /// definitions are not lost when a tank is deleted.  The tag [name] is
  /// used as the unique key; for duplicates the registry entry takes
  /// precedence over the tank entry so that colour overrides are preserved.
  Future<void> syncFromTanks(List<Tank> tanks) async {
    final merged = <String, TankTag>{};
    // Preserve existing registry entries first.
    for (final tag in state) {
      merged.putIfAbsent(tag.name, () => tag);
    }
    // Merge tags from the current set of tanks.
    for (final tank in tanks) {
      for (final tag in tank.tags) {
        merged.putIfAbsent(tag.name, () => tag);
      }
    }
    state = merged.values.toList();
    await _saveTags();
  }

  /// Export the global tag library for inclusion in a backup file.
  List<Map<String, dynamic>> exportTags() {
    return state.map((t) => t.toJson()).toList();
  }

  /// Replace the global tag library with the data restored from a backup file.
  Future<void> importTags(List<TankTag> tags) async {
    state = List<TankTag>.from(tags);
    await _saveTags();
  }
}

/// Provider for the global TankTag library.
final tankTagsProvider =
    StateNotifierProvider<TankTagsNotifier, List<TankTag>>(
  (ref) => TankTagsNotifier(),
);

/// Returns a de-duplicated, alphabetically sorted list of [TankTag] definitions
/// by merging the [globalTags] registry with tags found across [tanks].
///
/// The registry entry takes precedence over per-tank entries when the same tag
/// name appears in both sources.  Use this whenever building the list of
/// tag suggestions for a tag-picker dialog.
List<TankTag> mergeTagSuggestions({
  required List<TankTag> globalTags,
  required List<Tank> tanks,
}) {
  final byName = <String, TankTag>{};
  for (final tag in globalTags) {
    byName.putIfAbsent(tag.name, () => tag);
  }
  for (final tank in tanks) {
    for (final tag in tank.tags) {
      byName.putIfAbsent(tag.name, () => tag);
    }
  }
  return byName.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
