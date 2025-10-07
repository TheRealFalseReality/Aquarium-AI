import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/tank.dart';
import '../services/analytics_service.dart';
import 'species_tags_provider.dart';
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';

final tankProvider = StateNotifierProvider<TankNotifier, TankState>((ref) {
  return TankNotifier(ref);
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
  final Ref _ref;

  TankNotifier(this._ref) : super(TankState(isLoading: true)) {
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
      
      // Log tank creation
      AnalyticsService.logTankAction(
        action: 'tank_created',
        tankType: tank.type,
        tankSize: tank.sizeGallons?.round(),
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add tank: $e',
      );
      
      AnalyticsService.logError(
        errorType: 'tank_creation_error',
        errorMessage: e.toString(),
        screen: 'tank_management',
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
      final tankToDelete = state.tanks.firstWhere((tank) => tank.id == tankId);
      final updatedTanks = state.tanks.where((tank) => tank.id != tankId).toList();
      state = state.copyWith(tanks: updatedTanks, isLoading: false);
      await _saveTanks();
      
      // Log tank deletion
      AnalyticsService.logTankAction(
        action: 'tank_deleted',
        tankType: tankToDelete.type,
        tankSize: tankToDelete.sizeGallons?.round(),
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete tank: $e',
      );
      
      AnalyticsService.logError(
        errorType: 'tank_deletion_error',
        errorMessage: e.toString(),
        screen: 'tank_management',
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

      // Log backup attempt
      AnalyticsService.logTankAction(
        action: 'backup_start',
        tankSize: state.tanks.length,
      );

      // Get species tags for backup
      final speciesTagsNotifier = _ref.read(speciesTagsProvider.notifier);
      final speciesTags = speciesTagsNotifier.exportTags();

      // Create backup data with metadata
      // Exclude local image paths to prevent restore errors on different devices
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': state.tanks.length,
        'tanks': state.tanks.map((tank) => tank.toJson(includeLocalPaths: false)).toList(),
        'speciesTags': speciesTags,
      };

      // Convert to formatted JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Convert string to bytes for mobile platforms
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Create filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'aquarium_ai_backup_$timestamp.json';

      String? outputPath;
      
      if (kIsWeb) {
        // On web, trigger direct browser download
        downloadFile(bytes, fileName);
        
        // For web, we return the filename since there's no file path
        outputPath = fileName;
      } else {
        // On mobile/desktop, use saveFile with all parameters
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Tank Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes, // Required for Android & iOS
        );
      }

      if (outputPath != null) {
        state = state.copyWith(isLoading: false);
        
        // Log successful backup
        AnalyticsService.logTankAction(
          action: 'backup_success',
          tankSize: state.tanks.length,
        );
        
        // Log feature usage
        AnalyticsService.logFeatureUsed(
          featureName: 'tank_backup',
          parameters: {
            'platform': kIsWeb ? 'web' : 'mobile',
            'tank_count': state.tanks.length,
            'file_size_kb': (bytes.length / 1024).round(),
          },
        );
        
        return outputPath;
      } else {
        // User cancelled
        state = state.copyWith(isLoading: false);
        
        // Log backup cancellation
        AnalyticsService.logTankAction(
          action: 'backup_cancelled',
          tankSize: state.tanks.length,
        );
        
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export tanks: $e',
      );
      
      // Log backup failure
      AnalyticsService.logTankAction(
        action: 'backup_failed',
        tankSize: state.tanks.length,
      );
      
      AnalyticsService.logError(
        errorType: 'backup_error',
        errorMessage: e.toString(),
        screen: 'tank_management',
      );
      
      return null;
    }
  }

  /// Import tanks from a backup file
  Future<bool> importTanksFromFile() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Log restore attempt
      AnalyticsService.logTankAction(
        action: 'restore_start',
        tankSize: state.tanks.length, // Current tank count before restore
      );

      // Pick a file - use FileType.any for better compatibility
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isLoading: false);
        
        // Log restore cancellation
        AnalyticsService.logTankAction(
          action: 'restore_cancelled',
          tankSize: state.tanks.length,
        );
        
        return false;
      }

      final platformFile = result.files.single;
      String jsonString;

      if (kIsWeb) {
        // On web, use bytes property
        final bytes = platformFile.bytes;
        if (bytes == null) {
          throw Exception('Could not read file content on web platform');
        }
        jsonString = utf8.decode(bytes);
      } else {
        // On mobile/desktop, use path property
        final filePath = platformFile.path;
        if (filePath == null) {
          throw Exception('Could not access selected file');
        }
        final file = File(filePath);
        jsonString = await file.readAsString();
      }

      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      if (!backupData.containsKey('tanks') || !backupData.containsKey('version')) {
        throw const FormatException('Invalid backup file format');
      }

      // Parse tanks
      final tanksList = backupData['tanks'] as List;
      final importedTanks = tanksList.map((tankData) => Tank.fromJson(tankData)).toList();

      // Restore species tags if present in backup
      if (backupData.containsKey('speciesTags')) {
        final speciesTagsData = backupData['speciesTags'] as Map<String, dynamic>;
        final speciesTagsMap = speciesTagsData.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        );
        final speciesTagsNotifier = _ref.read(speciesTagsProvider.notifier);
        await speciesTagsNotifier.importTags(speciesTagsMap);
      }

      final previousTankCount = state.tanks.length;
      
      // For now, replace all tanks (we could add merge options later)
      state = state.copyWith(tanks: importedTanks, isLoading: false);
      await _saveTanks();

      // Log successful restore
      AnalyticsService.logTankAction(
        action: 'restore_success',
        tankSize: importedTanks.length,
      );
      
      // Log feature usage with detailed metrics
      AnalyticsService.logFeatureUsed(
        featureName: 'tank_restore',
        parameters: {
          'platform': kIsWeb ? 'web' : 'mobile',
          'previous_tank_count': previousTankCount,
          'restored_tank_count': importedTanks.length,
          'backup_version': backupData['version'] ?? 'unknown',
          'file_size_kb': (jsonString.length / 1024).round(),
        },
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import tanks: $e',
      );
      
      // Log restore failure
      AnalyticsService.logTankAction(
        action: 'restore_failed',
        tankSize: state.tanks.length,
      );
      
      AnalyticsService.logError(
        errorType: 'restore_error',
        errorMessage: e.toString(),
        screen: 'tank_management',
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