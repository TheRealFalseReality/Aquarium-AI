import 'package:fish_ai/services/fish_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Minimal mock fish dataset used as the SP-cache seed in all tests that
// require loadFishData() to return data.  This mirrors the shape that
// FishFirestoreService.fetchFishData() / _persistToSpCache() produces.
// ---------------------------------------------------------------------------
const _mockJson = '{'
    '"freshwater":['
    '{"uuid":"test-fw-1","name":"Zebra Danio",'
    '"commonNames":["Danio","Zebrafish"],'
    '"imageURL":"https://raw.githubusercontent.com/TheRealFalseReality/Aquarium-AI'
    '/refs/heads/main/assets/images/fish/zebrafish.webp",'
    '"compatible":["Zebra Danio"],'
    '"notRecommended":[],"notCompatible":[],"withCaution":[]},'
    '{"uuid":"test-fw-2","name":"Guppy",'
    '"commonNames":["Million fish"],'
    '"imageURL":"https://raw.githubusercontent.com/TheRealFalseReality/Aquarium-AI'
    '/refs/heads/main/assets/images/fish/guppies.webp",'
    '"compatible":["Guppy"],'
    '"notRecommended":[],"notCompatible":[],"withCaution":[]}'
    '],'
    '"marine":['
    '{"uuid":"test-ma-1","name":"Clownfish",'
    '"commonNames":["Anemonefish"],'
    '"imageURL":"https://raw.githubusercontent.com/TheRealFalseReality/Aquarium-AI'
    '/refs/heads/main/assets/images/fish/clownfish_male.webp",'
    '"reefSafe":"Yes",'
    '"compatible":["Clownfish"],'
    '"notRecommended":[],"notCompatible":[],"withCaution":[]}'
    ']}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FishDataService Tests', () {
    late FishDataService service;

    setUp(() {
      // Seed the SP cache so loadFishData() can succeed without Firestore.
      SharedPreferences.setMockInitialValues({
        'fishcompat_cached_json': _mockJson,
      });
      service = FishDataService();
    });

    test('loadFishData returns both freshwater and marine categories', () async {
      final data = await service.loadFishData();

      expect(data, isNotEmpty);
      expect(data.containsKey('freshwater'), isTrue);
      expect(data.containsKey('marine'), isTrue);
      expect(data['freshwater'], isNotEmpty);
      expect(data['marine'], isNotEmpty);
    });

    test('loadFishData caches data on subsequent calls', () async {
      // First call loads data
      final data1 = await service.loadFishData();

      // Second call should return cached data (same instance)
      final data2 = await service.loadFishData();

      expect(identical(data1, data2), isTrue,
          reason: 'Second call should return cached instance');
    });

    test('getCachedFishByCategory returns null before loading', () {
      final freshwater = service.getCachedFishByCategory('freshwater');
      expect(freshwater, isNull);
    });

    test('getCachedFishByCategory returns data after loading', () async {
      await service.loadFishData();

      final freshwater = service.getCachedFishByCategory('freshwater');
      final marine = service.getCachedFishByCategory('marine');

      expect(freshwater, isNotNull);
      expect(marine, isNotNull);
      expect(freshwater, isNotEmpty);
      expect(marine, isNotEmpty);
    });

    test('clearCache removes in-memory cached data', () async {
      // Load data first
      await service.loadFishData();
      expect(service.getCachedFishByCategory('freshwater'), isNotNull);

      // Clear cache
      service.clearCache();

      // Should return null after clearing
      expect(service.getCachedFishByCategory('freshwater'), isNull);
    });

    test('loadFishData after clearCache reloads the data', () async {
      // Load data first
      final data1 = await service.loadFishData();

      // Clear cache
      service.clearCache();

      // Load again — should succeed via the still-valid SP cache
      final data2 = await service.loadFishData();

      // Should have fresh data (not identical instance)
      expect(identical(data1, data2), isFalse);
      expect(data2['freshwater'], isNotEmpty);
      expect(data2['marine'], isNotEmpty);
    });

    test('fish objects have required properties', () async {
      final data = await service.loadFishData();

      // Check freshwater fish
      final firstFreshwaterFish = data['freshwater']!.first;
      expect(firstFreshwaterFish.name, isNotEmpty);
      expect(firstFreshwaterFish.commonNames, isList);
      expect(firstFreshwaterFish.compatible, isList);

      // Check marine fish
      final firstMarineFish = data['marine']!.first;
      expect(firstMarineFish.name, isNotEmpty);
      expect(firstMarineFish.commonNames, isList);
      expect(firstMarineFish.compatible, isList);
    });

    test('loadFishData returns fish sorted alphabetically', () async {
      // Use a dataset where freshwater fish are intentionally out of order
      // to verify the service sorts them.
      const unsortedJson = '{"freshwater":['
          '{"uuid":"u1","name":"Zebra Danio","commonNames":[],'
          '"imageURL":"https://raw.githubusercontent.com/TheRealFalseReality/Aquarium-AI'
          '/refs/heads/main/assets/images/fish/zebrafish.webp",'
          '"compatible":[],"notRecommended":[],"notCompatible":[],"withCaution":[]},'
          '{"uuid":"u2","name":"Angelfish","commonNames":[],'
          '"imageURL":"https://raw.githubusercontent.com/TheRealFalseReality/Aquarium-AI'
          '/refs/heads/main/assets/images/fish/angelfish.webp",'
          '"compatible":[],"notRecommended":[],"notCompatible":[],"withCaution":[]}'
          '],"marine":[]}';
      SharedPreferences.setMockInitialValues({
        'fishcompat_cached_json': unsortedJson,
      });
      final svc = FishDataService();
      final data = await svc.loadFishData();

      final names =
          data['freshwater']!.map((f) => f.name.toLowerCase()).toList();
      final sortedNames = List<String>.from(names)..sort();
      expect(names, equals(sortedNames),
          reason: 'freshwater fish should be sorted alphabetically');
    });

    test('marine fish from SP cache retain reefSafe field', () async {
      final data = await service.loadFishData();

      final marineFish = data['marine']!;
      expect(marineFish, isNotEmpty);
      for (final fish in marineFish) {
        expect(fish.reefSafe, isNotNull,
            reason: 'Marine fish "${fish.name}" should have a reefSafe value');
        expect(['Yes', 'No', 'Caution'], contains(fish.reefSafe),
            reason:
                'reefSafe for "${fish.name}" should be Yes, No, or Caution');
      }
    });

    test('freshwater fish from SP cache have no reefSafe field', () async {
      final data = await service.loadFishData();

      final freshwaterFish = data['freshwater']!;
      expect(freshwaterFish, isNotEmpty);
      for (final fish in freshwaterFish) {
        expect(fish.reefSafe, isNull,
            reason:
                'Freshwater fish "${fish.name}" should not have a reefSafe value');
      }
    });

    test('clearPersistentCache clears both in-memory and SP cache', () async {
      final svc = FishDataService();
      await svc.loadFishData(); // loads from SP cache

      await svc.clearPersistentCache();

      expect(svc.getCachedFishByCategory('freshwater'), isNull,
          reason: 'In-memory cache should be cleared');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fishcompat_cached_json'), isNull,
          reason: 'SP cache key should be removed');
    });

    test('SP cache with empty fish lists is treated as invalid', () async {
      // Empty lists are not valid — the service must not cache them and should
      // fall through to further sources (or throw when all fail).
      SharedPreferences.setMockInitialValues({
        'fishcompat_cached_json': '{"freshwater":[],"marine":[]}',
      });
      final svc = FishDataService();

      // Firestore is unavailable in tests; SP has empty lists → StateError.
      expect(
        () async => svc.loadFishData(),
        throwsA(isA<StateError>()),
        reason:
            'loadFishData should throw when SP cache contains only empty lists'
            ' and Firestore is unavailable',
      );
    });

    test('loadFishData throws StateError when all sources are unavailable',
        () async {
      // No SP cache at all — Firestore also unavailable in tests.
      SharedPreferences.setMockInitialValues({});
      final svc = FishDataService();

      expect(
        () async => svc.loadFishData(),
        throwsA(isA<StateError>()),
        reason:
            'loadFishData should throw StateError when Firestore is down and '
            'there is no usable SP cache',
      );
    });

    test('loadFishData falls back to SP cache when Firestore is unavailable',
        () async {
      // Seed SP with a minimal valid dataset that contains a fish named
      // "GuppySPCacheTest" — a name that only exists in the SP seed.
      const uniqueName = 'GuppySPCacheTest';
      final mockJson = '{"freshwater":[{"uuid":"test-sp-1","name":"$uniqueName",'
          '"commonNames":["$uniqueName"],"imageURL":"https://raw.githubusercontent.com/'
          'TheRealFalseReality/Aquarium-AI/refs/heads/main/assets/images/fish/'
          'guppies.webp","compatible":[],"notRecommended":[],'
          '"notCompatible":[],"withCaution":[]}],'
          '"marine":[{"uuid":"test-sp-2","name":"TestClownfish",'
          '"commonNames":["TestClownfish"],"imageURL":"https://raw.githubusercontent.com/'
          'TheRealFalseReality/Aquarium-AI/refs/heads/main/assets/images/fish/'
          'clownfish_male.webp","reefSafe":"Yes","compatible":[],'
          '"notRecommended":[],"notCompatible":[],"withCaution":[]}]}';
      SharedPreferences.setMockInitialValues({
        'fishcompat_cached_json': mockJson,
      });

      // Firestore is not initialised in the test environment so it throws
      // immediately; the service catches that and falls through to SP.
      final svc = FishDataService();
      final data = await svc.loadFishData();

      // The unique sentinel name proves SP data was used.
      final freshwater = data['freshwater'] ?? [];
      expect(
        freshwater.any((f) => f.name == uniqueName),
        isTrue,
        reason: 'SP cache data should be returned when Firestore is unavailable',
      );
    });

    test('fish localImagePath extracts assets/ suffix from full URL', () async {
      final data = await service.loadFishData();

      for (final category in ['freshwater', 'marine']) {
        for (final fish in data[category]!) {
          expect(
            fish.localImagePath,
            startsWith('assets/images/fish/'),
            reason: '${fish.name} localImagePath should be a local asset path',
          );
          expect(
            fish.localImagePath,
            endsWith('.webp'),
            reason: '${fish.name} localImagePath should use .webp extension',
          );
        }
      }
    });
  });
}
