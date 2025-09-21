import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fish.dart';

class FishDataService {
  static final FishDataService _instance = FishDataService._internal();
  factory FishDataService() => _instance;
  FishDataService._internal();

  static const String _fishDataKey = 'custom_fish_data';
  static const String _fishBackupKey = 'custom_fish_backup';

  // In-memory storage for current fish data
  Map<String, List<Fish>>? _currentFishData;
  Map<String, List<Fish>>? _originalFishData;

  /// Load fish data from assets or SharedPreferences
  Future<Map<String, List<Fish>>> loadFishData() async {
    if (_currentFishData != null) {
      return _currentFishData!;
    }

    // First try to load custom data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final customDataJson = prefs.getString(_fishDataKey);
    
    if (customDataJson != null) {
      try {
        final Map<String, dynamic> customData = json.decode(customDataJson);
        _currentFishData = _parseFishData(customData);
        return _currentFishData!;
      } catch (e) {
        // If custom data is corrupted, fall back to original
        print('Error loading custom fish data: $e');
      }
    }

    // Load original data from assets
    return await loadOriginalFishData();
  }

  /// Load original fish data from assets
  Future<Map<String, List<Fish>>> loadOriginalFishData() async {
    if (_originalFishData != null && _currentFishData == null) {
      _currentFishData = _deepCopyFishData(_originalFishData!);
      return _currentFishData!;
    }

    try {
      final String fishJson = await rootBundle.loadString('assets/fishcompat.json');
      final Map<String, dynamic> fishData = json.decode(fishJson);
      _originalFishData = _parseFishData(fishData);
      _currentFishData = _deepCopyFishData(_originalFishData!);
      return _currentFishData!;
    } catch (e) {
      throw Exception('Failed to load fish data: $e');
    }
  }

  /// Parse fish data from JSON
  Map<String, List<Fish>> _parseFishData(Map<String, dynamic> data) {
    final Map<String, List<Fish>> result = {};
    
    data.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((fishJson) => Fish.fromJson(fishJson)).toList();
      }
    });
    
    return result;
  }

  /// Create a deep copy of fish data
  Map<String, List<Fish>> _deepCopyFishData(Map<String, List<Fish>> original) {
    final Map<String, List<Fish>> copy = {};
    original.forEach((key, fishList) {
      copy[key] = fishList.map((fish) => Fish(
        name: fish.name,
        commonNames: List<String>.from(fish.commonNames),
        imageURL: fish.imageURL,
        compatible: List<String>.from(fish.compatible),
        notRecommended: List<String>.from(fish.notRecommended),
        notCompatible: List<String>.from(fish.notCompatible),
        withCaution: List<String>.from(fish.withCaution),
      )).toList();
    });
    return copy;
  }

  /// Get current fish data (in-memory)
  Map<String, List<Fish>>? getCurrentFishData() {
    return _currentFishData;
  }

  /// Update current fish data in memory
  void updateFishData(Map<String, List<Fish>> newData) {
    _currentFishData = newData;
  }

  /// Save current fish data to SharedPreferences
  Future<bool> saveFishData() async {
    if (_currentFishData == null) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create backup before saving
      await _createBackup();
      
      // Convert fish data to JSON
      final Map<String, dynamic> dataToSave = {};
      _currentFishData!.forEach((key, fishList) {
        dataToSave[key] = fishList.map((fish) => fish.toJson()).toList();
      });
      
      // Save to SharedPreferences
      final jsonString = json.encode(dataToSave);
      await prefs.setString(_fishDataKey, jsonString);
      
      return true;
    } catch (e) {
      print('Error saving fish data: $e');
      return false;
    }
  }

  /// Create backup of current data
  Future<void> _createBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDataJson = prefs.getString(_fishDataKey);
    
    if (currentDataJson != null) {
      await prefs.setString(_fishBackupKey, currentDataJson);
    }
  }

  /// Reset to original fish data
  Future<void> resetToOriginal() async {
    if (_originalFishData != null) {
      _currentFishData = _deepCopyFishData(_originalFishData!);
    } else {
      await loadOriginalFishData();
    }
    
    // Clear saved custom data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fishDataKey);
  }

  /// Check if custom data exists
  Future<bool> hasCustomData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_fishDataKey);
  }

  /// Get backup data if available
  Future<String?> getBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fishBackupKey);
  }
}