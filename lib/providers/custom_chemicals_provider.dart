import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dosing_preset.dart';

/// State for the user-managed chemicals list.
class CustomChemicalsState {
  final List<DosingPreset> chemicals;
  final bool isLoading;

  const CustomChemicalsState({
    required this.chemicals,
    this.isLoading = true,
  });

  CustomChemicalsState copyWith({
    List<DosingPreset>? chemicals,
    bool? isLoading,
  }) {
    return CustomChemicalsState(
      chemicals: chemicals ?? this.chemicals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages a user-editable list of aquarium chemicals, persisted to
/// SharedPreferences. Defaults to [kDefaultDosingPresets] on first launch.
class CustomChemicalsNotifier extends StateNotifier<CustomChemicalsState> {
  CustomChemicalsNotifier()
    : super(const CustomChemicalsState(chemicals: [])) {
    _load();
  }

  static const String _key = 'custom_chemicals_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = (json.decode(raw) as List)
            .map((e) => DosingPreset.fromJson(e as Map<String, dynamic>))
            .toList();
        state = CustomChemicalsState(chemicals: list, isLoading: false);
      } else {
        // First launch — seed from built-in defaults.
        state = CustomChemicalsState(
          chemicals: List<DosingPreset>.from(kDefaultDosingPresets),
          isLoading: false,
        );
        await _save();
      }
    } catch (_) {
      state = CustomChemicalsState(
        chemicals: List<DosingPreset>.from(kDefaultDosingPresets),
        isLoading: false,
      );
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(
        state.chemicals.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(_key, encoded);
    } catch (_) {}
  }

  /// Adds a new chemical to the end of the list.
  Future<void> addChemical(DosingPreset preset) async {
    state = state.copyWith(
      chemicals: [...state.chemicals, preset],
    );
    await _save();
  }

  /// Replaces the chemical at [index].
  Future<void> updateChemical(int index, DosingPreset preset) async {
    final updated = List<DosingPreset>.from(state.chemicals);
    updated[index] = preset;
    state = state.copyWith(chemicals: updated);
    await _save();
  }

  /// Removes the chemical at [index].
  Future<void> removeChemical(int index) async {
    final updated = List<DosingPreset>.from(state.chemicals)..removeAt(index);
    state = state.copyWith(chemicals: updated);
    await _save();
  }

  /// Moves a chemical from [oldIndex] to [newIndex] (ReorderableListView semantics).
  Future<void> reorderChemical(int oldIndex, int newIndex) async {
    final updated = List<DosingPreset>.from(state.chemicals);
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(chemicals: updated);
    await _save();
  }

  /// Resets to the built-in defaults, clearing any user customisations.
  Future<void> resetToDefaults() async {
    state = state.copyWith(
      chemicals: List<DosingPreset>.from(kDefaultDosingPresets),
    );
    await _save();
  }

  /// Export for backup — returns the list as JSON-safe maps.
  List<Map<String, dynamic>> exportChemicals() =>
      state.chemicals.map((c) => c.toJson()).toList();

  /// Import from backup — replaces the entire list.
  Future<void> importChemicals(List<Map<String, dynamic>> data) async {
    final list = data.map((e) => DosingPreset.fromJson(e)).toList();
    state = state.copyWith(chemicals: list);
    await _save();
  }
}

final customChemicalsProvider =
    StateNotifierProvider<CustomChemicalsNotifier, CustomChemicalsState>((ref) {
      return CustomChemicalsNotifier();
    });
