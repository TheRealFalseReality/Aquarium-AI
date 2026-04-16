import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dosing_preset.dart';

const String _dosingPresetsKey = 'dosingPresets';

/// State notifier that manages the list of dosing presets.
///
/// Presets are stored in SharedPreferences as a JSON array so they survive
/// app restarts and can be backed up / restored.
class DosingPresetsNotifier extends StateNotifier<List<DosingPreset>> {
  DosingPresetsNotifier() : super(DosingPreset.defaultPresets) {
    _load();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_dosingPresetsKey);
    if (stored != null) {
      try {
        final list = (json.decode(stored) as List)
            .map((e) => DosingPreset.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      } catch (_) {
        // Corrupt data – fall back to defaults
        state = DosingPreset.defaultPresets;
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(state.map((p) => p.toJson()).toList());
    await prefs.setString(_dosingPresetsKey, encoded);
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addPreset(DosingPreset preset) async {
    state = [...state, preset];
    await _save();
  }

  Future<void> updatePreset(DosingPreset updated) async {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
    await _save();
  }

  Future<void> removePreset(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    await _save();
  }

  /// Reset to built-in defaults.
  Future<void> resetToDefaults() async {
    state = DosingPreset.defaultPresets;
    await _save();
  }

  // ── Backup / Restore ──────────────────────────────────────────────────────

  /// Export presets as a JSON-ready list for backup.
  List<Map<String, dynamic>> exportPresets() {
    return state.map((p) => p.toJson()).toList();
  }

  /// Import presets from a backup, replacing the current list.
  Future<void> importPresets(List<dynamic> data) async {
    final presets = data
        .map((e) => DosingPreset.fromJson(e as Map<String, dynamic>))
        .toList();
    state = presets;
    await _save();
  }
}

final dosingPresetsProvider =
    StateNotifierProvider<DosingPresetsNotifier, List<DosingPreset>>(
      (ref) => DosingPresetsNotifier(),
    );
