import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tank.dart';

final tankProvider = StateNotifierProvider<TankNotifier, TankState>((ref) {
  return TankNotifier();
});

class TankState {
  final List<Tank> tanks;
  final bool isLoading;
  final String? error;

  TankState({
    this.tanks = const [],
    this.isLoading = false,
    this.error,
  });

  TankState copyWith({
    List<Tank>? tanks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TankState(
      tanks: tanks ?? this.tanks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class TankNotifier extends StateNotifier<TankState> {
  static const String _tanksKey = 'user_tanks';

  TankNotifier() : super(TankState(isLoading: true)) {
    _loadTanks();
  }

  Future<void> _loadTanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tanksJson = prefs.getString(_tanksKey);
      
      if (tanksJson != null) {
        final tanksList = json.decode(tanksJson) as List;
        final tanks = tanksList.map((tankData) => Tank.fromJson(tankData)).toList();
        state = state.copyWith(tanks: tanks, isLoading: false);
      } else {
        state = state.copyWith(tanks: [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tanks: $e',
      );
    }
  }

  Future<void> _saveTanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tanksJson = json.encode(state.tanks.map((tank) => tank.toJson()).toList());
      await prefs.setString(_tanksKey, tanksJson);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save tanks: $e');
    }
  }

  Future<void> addTank(Tank tank) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final updatedTanks = [...state.tanks, tank];
      state = state.copyWith(tanks: updatedTanks, isLoading: false);
      await _saveTanks();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add tank: $e',
      );
    }
  }

  Future<void> updateTank(Tank updatedTank) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final updatedTanks = state.tanks.map((tank) {
        return tank.id == updatedTank.id 
            ? updatedTank.copyWith(updatedAt: DateTime.now())
            : tank;
      }).toList();
      
      state = state.copyWith(tanks: updatedTanks, isLoading: false);
      await _saveTanks();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update tank: $e',
      );
    }
  }

  Future<void> deleteTank(String tankId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final updatedTanks = state.tanks.where((tank) => tank.id != tankId).toList();
      state = state.copyWith(tanks: updatedTanks, isLoading: false);
      await _saveTanks();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete tank: $e',
      );
    }
  }

  Tank? getTankById(String id) {
    try {
      return state.tanks.firstWhere((tank) => tank.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}