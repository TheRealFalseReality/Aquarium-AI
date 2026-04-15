import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dosing_chemical.dart';

class DosingChemicalsState {
  final List<DosingChemical> chemicals;
  final bool isLoading;

  const DosingChemicalsState({required this.chemicals, this.isLoading = true});

  DosingChemicalsState copyWith({
    List<DosingChemical>? chemicals,
    bool? isLoading,
  }) {
    return DosingChemicalsState(
      chemicals: chemicals ?? this.chemicals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DosingChemicalsNotifier extends StateNotifier<DosingChemicalsState> {
  DosingChemicalsNotifier() : super(const DosingChemicalsState(chemicals: [])) {
    _load();
  }

  static const String _storageKey = 'dosing_chemicals_v1';

  static final List<DosingChemical> _defaultChemicals = [
    DosingChemical.create(
      name: 'Prime (Seachem)',
      amountPerUnit: 0.1, // 0.1 mL/gal (1 mL per 10 gal)
      perUnit: 'gallon',
    ),
    DosingChemical.create(
      name: 'Stability (Seachem)',
      amountPerUnit: 0.5, // 0.5 mL/gal (5 mL per 10 gal)
      perUnit: 'gallon',
    ),
    DosingChemical.create(
      name: 'Excel (Seachem)',
      amountPerUnit: 0.2, // 0.2 mL/gal (5 mL per 25 gal)
      perUnit: 'gallon',
    ),
    DosingChemical.create(
      name: 'Stress Coat (API)',
      amountPerUnit: 0.5, // 0.5 mL/gal (5 mL per 10 gal)
      perUnit: 'gallon',
    ),
    DosingChemical.create(
      name: 'Quick Start (API)',
      amountPerUnit: 1.0, // 10 mL per 10 gal
      perUnit: 'gallon',
    ),
    DosingChemical.create(
      name: 'Paraguard (Seachem)',
      amountPerUnit: 0.2, // 0.2 mL/gal (5 mL per 25 gal)
      perUnit: 'gallon',
    ),
  ];

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.trim().isEmpty) {
        state = state.copyWith(
          chemicals: List<DosingChemical>.from(_defaultChemicals),
          isLoading: false,
        );
        await _save();
        return;
      }

      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final loaded = decoded
          .map((item) => DosingChemical.fromJson(item as Map<String, dynamic>))
          .toList();

      if (loaded.isEmpty) {
        state = state.copyWith(
          chemicals: List<DosingChemical>.from(_defaultChemicals),
          isLoading: false,
        );
        await _save();
        return;
      }

      state = state.copyWith(chemicals: loaded, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        chemicals: List<DosingChemical>.from(_defaultChemicals),
        isLoading: false,
      );
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode(state.chemicals.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, payload);
  }

  Future<void> addChemical(DosingChemical chemical) async {
    state = state.copyWith(chemicals: [...state.chemicals, chemical]);
    await _save();
  }

  Future<void> updateChemical(DosingChemical chemical) async {
    final updated = state.chemicals
        .map((entry) => entry.id == chemical.id ? chemical : entry)
        .toList();
    state = state.copyWith(chemicals: updated);
    await _save();
  }

  Future<void> removeChemical(String id) async {
    state = state.copyWith(
      chemicals: state.chemicals.where((entry) => entry.id != id).toList(),
    );
    await _save();
  }

  Future<void> reorderChemicals(int oldIndex, int newIndex) async {
    final items = [...state.chemicals];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(chemicals: items);
    await _save();
  }
}

final dosingChemicalsProvider =
    StateNotifierProvider<DosingChemicalsNotifier, DosingChemicalsState>(
      (ref) => DosingChemicalsNotifier(),
    );
