import 'package:fish_ai/providers/species_tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpeciesTagsProvider Tests', () {
    late ProviderContainer container;

    setUp(() async {
      // Initialize shared preferences with empty data
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has empty tags', () async {
      container.read(speciesTagsProvider.notifier);
      
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));
      
      final state = container.read(speciesTagsProvider);
      expect(state.tags, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('setTagsForFishType adds tags successfully', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Barbs', ['Tiger Barb', 'Cherry Barb']);
      
      final state = container.read(speciesTagsProvider);
      expect(state.tags['Barbs'], hasLength(2));
      expect(state.tags['Barbs'], contains('Tiger Barb'));
      expect(state.tags['Barbs'], contains('Cherry Barb'));
    });

    test('setTagsForFishType with empty list removes fish type', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Tetras', ['Neon Tetra']);
      expect(container.read(speciesTagsProvider).tags.containsKey('Tetras'), isTrue);
      
      await notifier.setTagsForFishType('Tetras', []);
      expect(container.read(speciesTagsProvider).tags.containsKey('Tetras'), isFalse);
    });

    test('addTag adds a new tag', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.addTag('Guppies', 'Fancy Guppy');
      await notifier.addTag('Guppies', 'Endler Guppy');
      
      final tags = notifier.getTagsForFishType('Guppies');
      expect(tags, hasLength(2));
      expect(tags, contains('Fancy Guppy'));
      expect(tags, contains('Endler Guppy'));
    });

    test('addTag does not add duplicate tags', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.addTag('Mollies', 'Black Molly');
      await notifier.addTag('Mollies', 'Black Molly'); // Duplicate
      
      final tags = notifier.getTagsForFishType('Mollies');
      expect(tags, hasLength(1));
      expect(tags, contains('Black Molly'));
    });

    test('removeTag removes a tag successfully', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Danios', ['Zebra Danio', 'Pearl Danio', 'Leopard Danio']);
      await notifier.removeTag('Danios', 'Pearl Danio');
      
      final tags = notifier.getTagsForFishType('Danios');
      expect(tags, hasLength(2));
      expect(tags, contains('Zebra Danio'));
      expect(tags, contains('Leopard Danio'));
      expect(tags, isNot(contains('Pearl Danio')));
    });

    test('getTagsForFishType returns empty list for non-existent fish type', () {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      final tags = notifier.getTagsForFishType('NonExistent');
      expect(tags, isEmpty);
    });

    test('hasTags returns correct values', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Cichlids', ['Oscar', 'Convict']);
      
      expect(notifier.hasTags('Cichlids'), isTrue);
      expect(notifier.hasTags('NonExistent'), isFalse);
    });

    test('getAllFishTypesWithTags returns sorted list', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Zebra', ['Zebra Danio']);
      await notifier.setTagsForFishType('Alpha', ['Alpha Fish']);
      await notifier.setTagsForFishType('Omega', ['Omega Fish']);
      
      final fishTypes = notifier.getAllFishTypesWithTags();
      expect(fishTypes, hasLength(3));
      expect(fishTypes[0], equals('Alpha'));
      expect(fishTypes[1], equals('Omega'));
      expect(fishTypes[2], equals('Zebra'));
    });

    test('searchByTag finds fish types with matching tags', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Barbs', ['Tiger Barb', 'Cherry Barb']);
      await notifier.setTagsForFishType('Tetras', ['Neon Tetra', 'Cardinal Tetra']);
      await notifier.setTagsForFishType('Guppies', ['Fancy Guppy']);
      
      final results = notifier.searchByTag('tetra');
      expect(results, hasLength(1));
      expect(results, contains('Tetras'));
    });

    test('searchByTag is case-insensitive', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Angelfish', ['Freshwater Angelfish']);
      
      final results = notifier.searchByTag('ANGELFISH');
      expect(results, contains('Angelfish'));
    });

    test('clearAllTags removes all tags', () async {
      final notifier = container.read(speciesTagsProvider.notifier);
      
      await notifier.setTagsForFishType('Fish1', ['Tag1']);
      await notifier.setTagsForFishType('Fish2', ['Tag2']);
      
      expect(container.read(speciesTagsProvider).tags, isNotEmpty);
      
      await notifier.clearAllTags();
      
      expect(container.read(speciesTagsProvider).tags, isEmpty);
    });

    test('tags persist across provider instances', () async {
      // First instance
      final container1 = ProviderContainer();
      final notifier1 = container1.read(speciesTagsProvider.notifier);
      
      await notifier1.setTagsForFishType('Persistent', ['Test Tag']);
      await Future.delayed(const Duration(milliseconds: 100));
      
      container1.dispose();
      
      // Second instance should load persisted data
      final container2 = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      
      final state2 = container2.read(speciesTagsProvider);
      expect(state2.tags['Persistent'], contains('Test Tag'));
      
      container2.dispose();
    });
  });
}
