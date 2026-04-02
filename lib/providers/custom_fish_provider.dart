import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/fish.dart';
import '../services/custom_fish_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CustomFishState {
  final List<Fish> fish;
  final bool isLoading;
  final String? error;

  const CustomFishState({
    this.fish = const [],
    this.isLoading = false,
    this.error,
  });

  CustomFishState copyWith({
    List<Fish>? fish,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CustomFishState(
      fish: fish ?? this.fish,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CustomFishNotifier extends StateNotifier<CustomFishState> {
  final CustomFishService _service;

  CustomFishNotifier(this._service) : super(const CustomFishState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final fish = await _service.loadCustomFish();
      state = state.copyWith(fish: fish, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reload from storage (e.g. after a backup restore).
  Future<void> reload() => _load();

  /// Add a new custom fish.  A UUID is generated automatically if the fish
  /// does not already have one.
  Future<void> addFish(Fish fish) async {
    final withUuid = fish.uuid == null
        ? fish.copyWith(uuid: const Uuid().v4(), isCustom: true)
        : fish.copyWith(isCustom: true);
    await _service.saveOrUpdateFish(withUuid);
    final updated = [...state.fish, withUuid];
    state = state.copyWith(fish: updated);
  }

  /// Update an existing custom fish identified by its [Fish.uuid].
  Future<void> updateFish(Fish fish) async {
    final updated = fish.copyWith(isCustom: true);
    await _service.saveOrUpdateFish(updated);
    final newList = state.fish
        .map((f) => f.uuid == fish.uuid ? updated : f)
        .toList();
    state = state.copyWith(fish: newList);
  }

  /// Delete a custom fish by its [Fish.uuid].
  Future<void> deleteFish(String uuid) async {
    await _service.deleteFish(uuid);
    final newList = state.fish.where((f) => f.uuid != uuid).toList();
    state = state.copyWith(fish: newList);
  }

  /// Export all custom fish for backup (excludes local image paths).
  List<Map<String, dynamic>> exportForBackup() =>
      _service.exportCustomFish(state.fish);

  /// Replace all custom fish from backup data and reload provider state.
  Future<void> importFromBackup(List<dynamic> rawList) async {
    await _service.importCustomFish(rawList);
    await _load();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final customFishServiceProvider = Provider<CustomFishService>((ref) {
  return CustomFishService();
});

final customFishProvider =
    StateNotifierProvider<CustomFishNotifier, CustomFishState>((ref) {
  return CustomFishNotifier(ref.watch(customFishServiceProvider));
});
