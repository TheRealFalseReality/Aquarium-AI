import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Export all tanks to a backup file with user-selected location
  Future<String?> exportTanksToFile() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Create backup data with metadata
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': state.tanks.length,
        'tanks': state.tanks.map((tank) => tank.toJson()).toList(),
      };

      // Convert to formatted JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Convert string to bytes for mobile platforms
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Create filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'aquarium_ai_backup_$timestamp.json';

      // Let user choose save location with bytes for mobile compatibility
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Tank Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes, // Required for Android & iOS
      );

      if (outputPath != null) {
        state = state.copyWith(isLoading: false);
        return outputPath;
      } else {
        // User cancelled
        state = state.copyWith(isLoading: false);
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export tanks: $e',
      );
      return null;
    }
  }

  /// Import tanks from a backup file
  Future<bool> importTanksFromFile() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Pick a file - use FileType.any for better compatibility
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        throw Exception('Could not access selected file');
      }

      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      if (!backupData.containsKey('tanks') || !backupData.containsKey('version')) {
        throw const FormatException('Invalid backup file format');
      }

      // Parse tanks
      final tanksList = backupData['tanks'] as List;
      final importedTanks = tanksList.map((tankData) => Tank.fromJson(tankData)).toList();

      // For now, replace all tanks (we could add merge options later)
      state = state.copyWith(tanks: importedTanks, isLoading: false);
      await _saveTanks();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import tanks: $e',
      );
      return false;
    }
  }

  /// Get backup file info for display purposes
  Map<String, dynamic> createBackupInfo() {
    return {
      'tankCount': state.tanks.length,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }
}