import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage.
const String _welcomeCardOrderKey = 'welcomeCardOrder';
const String _sidebarOrderKey = 'sidebarOrder';
const String _hiddenSidebarItemsKey = 'hiddenSidebarItems';

/// Default sidebar item IDs in their default display order.
///
/// Each ID corresponds to a route or logical section in the app drawer.
const List<String> defaultSidebarOrder = [
  'compat-ai',
  'chatbot',
  'stocking',
  'analysis-history',
  'calculators',
  'tank-volume',
  'substrate',
  'compat-browser',
  'community',
  'profile',
  'information',
];

/// Immutable state for premium customization options.
class CustomizationState {
  /// Ordered list of welcome-card IDs. `null` means use default order.
  final List<String>? welcomeCardOrder;

  /// Ordered list of sidebar item IDs. `null` means use default order.
  final List<String>? sidebarOrder;

  /// Set of sidebar item IDs that the user has hidden.
  final Set<String> hiddenSidebarItems;

  /// Whether the initial load from SharedPreferences has finished.
  final bool isLoaded;

  const CustomizationState({
    this.welcomeCardOrder,
    this.sidebarOrder,
    this.hiddenSidebarItems = const {},
    this.isLoaded = false,
  });

  CustomizationState copyWith({
    List<String>? welcomeCardOrder,
    List<String>? sidebarOrder,
    Set<String>? hiddenSidebarItems,
    bool? isLoaded,
    bool clearWelcomeCardOrder = false,
    bool clearSidebarOrder = false,
  }) {
    return CustomizationState(
      welcomeCardOrder:
          clearWelcomeCardOrder ? null : (welcomeCardOrder ?? this.welcomeCardOrder),
      sidebarOrder:
          clearSidebarOrder ? null : (sidebarOrder ?? this.sidebarOrder),
      hiddenSidebarItems: hiddenSidebarItems ?? this.hiddenSidebarItems,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Notifier that manages welcome-card ordering and sidebar ordering/visibility
/// for Founder Aquarist users.
class CustomizationNotifier extends StateNotifier<CustomizationState> {
  CustomizationNotifier() : super(const CustomizationState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final welcomeOrderStr = prefs.getString(_welcomeCardOrderKey);
      final sidebarOrderStr = prefs.getString(_sidebarOrderKey);
      final hiddenSidebarStr = prefs.getString(_hiddenSidebarItemsKey);

      state = CustomizationState(
        welcomeCardOrder: welcomeOrderStr != null && welcomeOrderStr.isNotEmpty
            ? welcomeOrderStr.split(',')
            : null,
        sidebarOrder: sidebarOrderStr != null && sidebarOrderStr.isNotEmpty
            ? sidebarOrderStr.split(',')
            : null,
        hiddenSidebarItems:
            hiddenSidebarStr != null && hiddenSidebarStr.isNotEmpty
                ? hiddenSidebarStr.split(',').where((s) => s.isNotEmpty).toSet()
                : {},
        isLoaded: true,
      );
    } catch (e) {
      debugPrint('Error loading customization state: $e');
      state = const CustomizationState(isLoaded: true);
    }
  }

  // ── Welcome Card Order ──────────────────────────────────────────────────

  /// Save a new order for welcome screen cards.
  Future<void> setWelcomeCardOrder(List<String> order) async {
    state = state.copyWith(welcomeCardOrder: order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_welcomeCardOrderKey, order.join(','));
  }

  /// Reset welcome card order to default.
  Future<void> resetWelcomeCardOrder() async {
    state = state.copyWith(clearWelcomeCardOrder: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeCardOrderKey);
  }

  // ── Sidebar Order ───────────────────────────────────────────────────────

  /// Save a new order for sidebar menu items.
  Future<void> setSidebarOrder(List<String> order) async {
    state = state.copyWith(sidebarOrder: order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sidebarOrderKey, order.join(','));
  }

  /// Reset sidebar order to default.
  Future<void> resetSidebarOrder() async {
    state = state.copyWith(clearSidebarOrder: true, hiddenSidebarItems: {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sidebarOrderKey);
    await prefs.remove(_hiddenSidebarItemsKey);
  }

  /// Toggle the visibility of a sidebar item.
  Future<void> toggleSidebarItem(String id) async {
    final hidden = {...state.hiddenSidebarItems};
    if (hidden.contains(id)) {
      hidden.remove(id);
    } else {
      hidden.add(id);
    }
    state = state.copyWith(hiddenSidebarItems: hidden);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hiddenSidebarItemsKey, hidden.join(','));
  }

  /// Set hidden sidebar items directly.
  Future<void> setHiddenSidebarItems(Set<String> hidden) async {
    state = state.copyWith(hiddenSidebarItems: hidden);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hiddenSidebarItemsKey, hidden.join(','));
  }
}

/// Provider for premium customization state.
final customizationProvider =
    StateNotifierProvider<CustomizationNotifier, CustomizationState>(
  (ref) => CustomizationNotifier(),
);

/// Applies a custom order to a list of default IDs.
///
/// Items in [customOrder] that exist in [defaultIds] are placed first
/// (in the custom order), followed by any remaining items from [defaultIds]
/// that were not in the custom order (preserving their default order).
///
/// Used by the welcome screen, drawer, and settings dialogs to apply
/// saved ordering.
List<String> applyCustomOrder(
  List<String> defaultIds,
  List<String>? customOrder,
) {
  if (customOrder == null || customOrder.isEmpty) return List.from(defaultIds);

  final idSet = defaultIds.toSet();
  final ordered = <String>[];
  for (final id in customOrder) {
    // remove returns true when the item existed, preventing duplicates
    if (idSet.remove(id)) ordered.add(id);
  }
  // Append any new items not in the saved order
  ordered.addAll(idSet);
  return ordered;
}
