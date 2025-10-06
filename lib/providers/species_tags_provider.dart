import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/species_tag.dart';
import '../services/fish_data_service.dart';

/// State class for species tags
class SpeciesTagsState {
  final Map<String, List<String>> tags; // fishType -> list of tags
  final bool isLoading;

  SpeciesTagsState({
    required this.tags,
    this.isLoading = true,
  });

  SpeciesTagsState copyWith({
    Map<String, List<String>>? tags,
    bool? isLoading,
  }) {
    return SpeciesTagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for managing species tags
class SpeciesTagsNotifier extends StateNotifier<SpeciesTagsState> {
  SpeciesTagsNotifier()
      : super(SpeciesTagsState(
          tags: {},
        )) {
    _loadTags();
  }

  static const String _storageKey = 'species_tags';

  /// Load tags from shared preferences
  Future<void> _loadTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        final Map<String, List<String>> loadedTags = {};

        jsonData.forEach((key, value) {
          loadedTags[key] = List<String>.from(value);
        });

        state = SpeciesTagsState(
          tags: loadedTags,
          isLoading: false,
        );
      } else {
        state = SpeciesTagsState(
          tags: {},
          isLoading: false,
        );
      }
    } catch (e) {
      state = SpeciesTagsState(
        tags: {},
        isLoading: false,
      );
    }
  }

  /// Save tags to shared preferences
  Future<void> _saveTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.tags);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Handle error silently or log
    }
  }

  /// Add or update tags for a fish type
  Future<void> setTagsForFishType(String fishType, List<String> tags) async {
    final newTags = Map<String, List<String>>.from(state.tags);
    if (tags.isEmpty) {
      newTags.remove(fishType);
    } else {
      newTags[fishType] = tags;
    }

    state = state.copyWith(tags: newTags, isLoading: false);
    await _saveTags();
  }

  /// Add a single tag to a fish type
  Future<void> addTag(String fishType, String tag) async {
    final currentTags = state.tags[fishType] ?? [];
    if (!currentTags.contains(tag)) {
      final newTags = List<String>.from(currentTags)..add(tag);
      await setTagsForFishType(fishType, newTags);
    }
  }

  /// Remove a tag from a fish type
  Future<void> removeTag(String fishType, String tag) async {
    final currentTags = state.tags[fishType] ?? [];
    final newTags = List<String>.from(currentTags)..remove(tag);
    await setTagsForFishType(fishType, newTags);
  }

  /// Get tags for a specific fish type
  List<String> getTagsForFishType(String fishType) {
    return state.tags[fishType] ?? [];
  }

  /// Check if a fish type has any tags
  bool hasTags(String fishType) {
    final tags = state.tags[fishType];
    return tags != null && tags.isNotEmpty;
  }

  /// Get all fish types that have tags
  List<String> getAllFishTypesWithTags() {
    return state.tags.keys.toList()..sort();
  }

  /// Search fish types by tag
  List<String> searchByTag(String tag) {
    final lowerTag = tag.toLowerCase();
    return state.tags.entries
        .where((entry) =>
            entry.value.any((t) => t.toLowerCase().contains(lowerTag)))
        .map((entry) => entry.key)
        .toList();
  }

  /// Clear all tags
  Future<void> clearAllTags() async {
    state = SpeciesTagsState(
      tags: {},
      isLoading: false,
    );
    await _saveTags();
  }

  /// Initialize default tags from fish data common names
  /// Only adds tags for fish types that don't already have tags
  Future<void> initializeDefaultTags(Map<String, List<dynamic>> fishData) async {
    final newTags = Map<String, List<String>>.from(state.tags);
    bool hasChanges = false;

    // Process both freshwater and marine categories
    for (final category in ['freshwater', 'marine']) {
      final fishList = fishData[category] as List<dynamic>?;
      if (fishList == null) continue;

      for (final fishJson in fishList) {
        final fishName = fishJson['name'] as String;
        final commonNames = fishJson['commonNames'] as List<dynamic>?;

        // Only add default tags if this fish type has no tags yet
        if (!newTags.containsKey(fishName) || newTags[fishName]!.isEmpty) {
          if (commonNames != null && commonNames.isNotEmpty) {
            newTags[fishName] = commonNames.map((name) => name.toString()).toList();
            hasChanges = true;
          }
        }
      }
    }

    // Only update state and save if there were changes
    if (hasChanges) {
      state = state.copyWith(tags: newTags, isLoading: false);
      await _saveTags();
    }
  }
}

/// Provider for species tags
final speciesTagsProvider =
    StateNotifierProvider<SpeciesTagsNotifier, SpeciesTagsState>(
  (ref) {
    final notifier = SpeciesTagsNotifier();
    // Initialize default tags when provider is created
    _initializeDefaultTagsAsync(ref as ProviderRef, notifier);
    return notifier;
  },
);

/// Helper function to initialize default tags asynchronously
Future<void> _initializeDefaultTagsAsync(
    ProviderRef ref, SpeciesTagsNotifier notifier) async {
  try {
    // Wait a bit for the notifier to load existing tags first
    await Future.delayed(const Duration(milliseconds: 500));
    
    final fishDataService = ref.read(fishDataServiceProvider);
    final rawFishData = await fishDataService.loadRawFishData();
    await notifier.initializeDefaultTags(rawFishData);
  } catch (e) {
    // Silently fail - default tags are optional
  }
}
