import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_history_entry.dart';

final analysisHistoryProvider =
    StateNotifierProvider<AnalysisHistoryNotifier, List<AnalysisHistoryEntry>>(
  (ref) => AnalysisHistoryNotifier(),
);

class AnalysisHistoryNotifier
    extends StateNotifier<List<AnalysisHistoryEntry>> {
  static const String _storageKey = 'analysis_history';

  AnalysisHistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = json.decode(raw) as List<dynamic>;
        state = list
            .whereType<Map<String, dynamic>>()
            .map(AnalysisHistoryEntry.fromJson)
            .toList();
      }
    } catch (_) {
      // If loading fails, start with an empty history.
      state = [];
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          json.encode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Silently ignore save failures.
    }
  }

  /// Adds a new entry to the top of the list and persists it.
  Future<void> addEntry(AnalysisHistoryEntry entry) async {
    state = [entry, ...state];
    await _save();
  }

  /// Toggles the favorite status of the entry with [id].
  Future<void> toggleFavorite(String id) async {
    state = [
      for (final entry in state)
        if (entry.id == id) entry.copyWith(isFavorite: !entry.isFavorite)
        else entry,
    ];
    await _save();
  }

  /// Removes the entry with [id].
  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  /// Clears all history entries.
  Future<void> clearAll() async {
    state = [];
    await _save();
  }
}
