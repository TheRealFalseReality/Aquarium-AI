import 'package:fish_ai/services/fish_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FishDataService Tests', () {
    late FishDataService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
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
      
      // Load again
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

    test('loadFishData persists JSON and version to SharedPreferences', () async {
      await service.loadFishData();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fishcompat_cached_version'), isNotNull);
      expect(prefs.getString('fishcompat_cached_json'), isNotNull);
      expect(prefs.getString('fishcompat_cached_json'), isNotEmpty);
    });

    test('clearPersistentCache removes SharedPreferences entries', () async {
      await service.loadFishData();

      await service.clearPersistentCache();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fishcompat_cached_version'), isNull);
      expect(prefs.getString('fishcompat_cached_json'), isNull);
      expect(service.getCachedFishByCategory('freshwater'), isNull);
    });

    test('loadFishData uses SharedPreferences cache on second service instance',
        () async {
      // Populate the persistent cache via the first service instance.
      await service.loadFishData();

      // A fresh service instance (simulating an app restart) should read from
      // SharedPreferences and return valid fish data.
      final service2 = FishDataService();
      final data = await service2.loadFishData();

      expect(data.containsKey('freshwater'), isTrue);
      expect(data['freshwater'], isNotEmpty);
    });
  });
}
