import 'package:fish_ai/providers/customization_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyCustomOrder', () {
    test('returns default order when customOrder is null', () {
      final defaults = ['a', 'b', 'c'];
      final result = applyCustomOrder(defaults, null);
      expect(result, ['a', 'b', 'c']);
    });

    test('returns default order when customOrder is empty', () {
      final defaults = ['a', 'b', 'c'];
      final result = applyCustomOrder(defaults, []);
      expect(result, ['a', 'b', 'c']);
    });

    test('reorders items according to customOrder', () {
      final defaults = ['a', 'b', 'c', 'd'];
      final result = applyCustomOrder(defaults, ['c', 'a', 'b', 'd']);
      expect(result, ['c', 'a', 'b', 'd']);
    });

    test('partial customOrder places known items first, rest in default order',
        () {
      final defaults = ['a', 'b', 'c', 'd'];
      final result = applyCustomOrder(defaults, ['c', 'a']);
      expect(result, ['c', 'a', 'b', 'd']);
    });

    test('ignores unknown IDs in customOrder', () {
      final defaults = ['a', 'b', 'c'];
      final result = applyCustomOrder(defaults, ['x', 'b', 'z', 'a']);
      expect(result, ['b', 'a', 'c']);
    });

    test('does not produce duplicates when customOrder has repeats', () {
      final defaults = ['a', 'b', 'c'];
      final result = applyCustomOrder(defaults, ['b', 'b', 'a']);
      expect(result, ['b', 'a', 'c']);
    });

    test('returns copy, not the same list instance', () {
      final defaults = ['a', 'b'];
      final result = applyCustomOrder(defaults, null);
      expect(identical(result, defaults), isFalse);
    });
  });

  group('CustomizationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state loads with defaults', () async {
      container.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(customizationProvider);
      expect(state.isLoaded, isTrue);
      expect(state.welcomeCardOrder, isNull);
      expect(state.sidebarOrder, isNull);
      expect(state.hiddenSidebarItems, isEmpty);
    });

    test('setWelcomeCardOrder persists and updates state', () async {
      final notifier = container.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.setWelcomeCardOrder(['c', 'b', 'a']);

      final state = container.read(customizationProvider);
      expect(state.welcomeCardOrder, ['c', 'b', 'a']);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('welcomeCardOrder'), 'c,b,a');
    });

    test('resetWelcomeCardOrder clears order', () async {
      final notifier = container.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.setWelcomeCardOrder(['c', 'b', 'a']);
      await notifier.resetWelcomeCardOrder();

      final state = container.read(customizationProvider);
      expect(state.welcomeCardOrder, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('welcomeCardOrder'), isNull);
    });

    test('setSidebarOrder persists and updates state', () async {
      final notifier = container.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.setSidebarOrder(['info', 'chat', 'calc']);

      final state = container.read(customizationProvider);
      expect(state.sidebarOrder, ['info', 'chat', 'calc']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sidebarOrder'), 'info,chat,calc');
    });

    test('resetSidebarOrder clears order and hidden items', () async {
      final notifier = container.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.setSidebarOrder(['info', 'chat']);
      await notifier.setHiddenSidebarItems({'chat'});
      await notifier.resetSidebarOrder();

      final state = container.read(customizationProvider);
      expect(state.sidebarOrder, isNull);
      expect(state.hiddenSidebarItems, isEmpty);
    });

    test('toggleSidebarItem hides then shows', () async {
      final notifier = container.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.toggleSidebarItem('chatbot');
      expect(
        container.read(customizationProvider).hiddenSidebarItems,
        contains('chatbot'),
      );

      await notifier.toggleSidebarItem('chatbot');
      expect(
        container.read(customizationProvider).hiddenSidebarItems,
        isNot(contains('chatbot')),
      );
    });

    test('setHiddenSidebarItems persists correctly', () async {
      final notifier = container.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.setHiddenSidebarItems({'a', 'b'});

      final state = container.read(customizationProvider);
      expect(state.hiddenSidebarItems, containsAll(['a', 'b']));

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('hiddenSidebarItems')!.split(',').toSet();
      expect(stored, containsAll(['a', 'b']));
    });

    test('loads previously saved state from SharedPreferences', () async {
      // Pre-populate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'welcomeCardOrder': 'x,y,z',
        'sidebarOrder': 'p,q',
        'hiddenSidebarItems': 'q',
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      container2.read(customizationProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container2.read(customizationProvider);
      expect(state.isLoaded, isTrue);
      expect(state.welcomeCardOrder, ['x', 'y', 'z']);
      expect(state.sidebarOrder, ['p', 'q']);
      expect(state.hiddenSidebarItems, {'q'});
    });
  });
}
