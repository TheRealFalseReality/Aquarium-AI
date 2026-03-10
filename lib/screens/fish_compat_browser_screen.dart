import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import '../utils/markdown_style_utils.dart';
import '../utils/storage_image_utils.dart';
import '../widgets/fish_image.dart';

/// Compatibility status between two fish types.
enum CompatStatus { compatible, withCaution, notRecommended, notCompatible, unknown }

extension CompatStatusExt on CompatStatus {
  Color color(BuildContext context) {
    switch (this) {
      case CompatStatus.compatible:
        return Colors.green.shade600;
      case CompatStatus.withCaution:
        return Colors.amber.shade700;
      case CompatStatus.notRecommended:
        return Colors.deepOrange.shade600;
      case CompatStatus.notCompatible:
        return Colors.red.shade700;
      case CompatStatus.unknown:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Color backgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = isDark ? 0.22 : 0.10;
    switch (this) {
      case CompatStatus.compatible:
        return Colors.green.withOpacity(opacity);
      case CompatStatus.withCaution:
        return Colors.amber.withOpacity(opacity);
      case CompatStatus.notRecommended:
        return Colors.deepOrange.withOpacity(opacity);
      case CompatStatus.notCompatible:
        return Colors.red.withOpacity(opacity);
      case CompatStatus.unknown:
        return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  IconData get icon {
    switch (this) {
      case CompatStatus.compatible:
        return Icons.check_circle;
      case CompatStatus.withCaution:
        return Icons.warning_amber_rounded;
      case CompatStatus.notRecommended:
        return Icons.do_not_disturb_on_outlined;
      case CompatStatus.notCompatible:
        return Icons.cancel;
      case CompatStatus.unknown:
        return Icons.help_outline;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case CompatStatus.compatible:
        return l10n.compatible;
      case CompatStatus.withCaution:
        return l10n.withCaution;
      case CompatStatus.notRecommended:
        return l10n.notRecommended;
      case CompatStatus.notCompatible:
        return l10n.notCompatible;
      case CompatStatus.unknown:
        return l10n.unknownCompatibility;
    }
  }
}

/// Returns the [CompatStatus] of [other] relative to [source].
CompatStatus _getCompatStatus(Fish source, String otherName) {
  if (source.compatible.contains(otherName)) return CompatStatus.compatible;
  if (source.withCaution.contains(otherName)) return CompatStatus.withCaution;
  if (source.notRecommended.contains(otherName)) return CompatStatus.notRecommended;
  if (source.notCompatible.contains(otherName)) return CompatStatus.notCompatible;
  return CompatStatus.unknown;
}

class FishCompatBrowserScreen extends ConsumerStatefulWidget {
  const FishCompatBrowserScreen({super.key});

  @override
  FishCompatBrowserScreenState createState() => FishCompatBrowserScreenState();
}

class FishCompatBrowserScreenState extends ConsumerState<FishCompatBrowserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Fish? _selectedFish;
  String _searchQuery = '';
  bool _showMatrixView = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchVisible = false;

  /// Tracks which compat sections are collapsed in the detail view.
  final Set<CompatStatus> _collapsedSections = {};

  static const List<String> _categories = ['freshwater', 'marine'];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    AnalyticsService.logScreenView(screenName: 'fish_compat_browser_screen');
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedFish = null;
      _searchQuery = '';
      _searchController.clear();
      _showMatrixView = false;
      _collapsedSections.clear();
      _isSearchVisible = false;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Fish> _filterFish(List<Fish> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((f) {
      return f.name.toLowerCase().contains(q) ||
          f.commonNames.any((c) => c.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fishDataAsync = ref.watch(fishDataProvider);

    return MainLayout(
      title: l10n.fishCompatBrowser,
      child: Stack(
        children: [
          Column(
            children: [
              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.water),
                    text: l10n.freshwater,
                  ),
                  Tab(
                    icon: const Icon(Icons.waves),
                    text: l10n.marine,
                  ),
                ],
              ),
              // Main content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _categories.map((cat) {
                    return fishDataAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.fishDataNotAvailable,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () =>
                                    ref.refresh(fishDataProvider),
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (fishMap) {
                        final allFish = fishMap[cat] ?? [];
                        final filtered = _filterFish(allFish);
                        return _buildCategoryView(
                            context, l10n, filtered, allFish, cat);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          // Floating search bar (same style as the AI Compat tool)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildSearchWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchWidget() {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _isSearchVisible
          ? Material(
              key: const ValueKey('search_bar'),
              elevation: 6,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchFish,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _isSearchVisible = false;
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            )
          : Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton.extended(
                key: const ValueKey('search_fab'),
                heroTag: 'compat_browser_search_fab',
                icon: const Icon(Icons.search),
                label: Text(l10n.search),
                onPressed: () {
                  setState(() => _isSearchVisible = true);
                  _searchFocus.requestFocus();
                },
              ),
            ),
    );
  }

  Widget _buildCategoryView(
    BuildContext context,
    AppLocalizations l10n,
    List<Fish> filtered,
    List<Fish> all,
    String category,
  ) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noFishFound,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    // On wide screens, show split view
    final isWide = MediaQuery.of(context).size.width >= 720;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: fish list
          SizedBox(
            width: 280,
            child: _buildFishList(context, l10n, filtered, category),
          ),
          const VerticalDivider(width: 1),
          // Right: detail or placeholder
          Expanded(
            child: _selectedFish != null
                ? (_showMatrixView
                    ? _buildMatrixView(context, l10n, all, _selectedFish!, category)
                    : _buildDetailView(context, l10n, all, _selectedFish!, category))
                : _buildSelectFishPlaceholder(context, l10n),
          ),
        ],
      );
    }

    // On narrow screens, show either list or detail
    if (_selectedFish != null) {
      return _showMatrixView
          ? _buildMatrixView(context, l10n, all, _selectedFish!, category)
          : _buildDetailView(context, l10n, all, _selectedFish!, category);
    }
    return _buildFishList(context, l10n, filtered, category);
  }

  Widget _buildFishList(
    BuildContext context,
    AppLocalizations l10n,
    List<Fish> fish,
    String category,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: fish.length,
      itemBuilder: (context, i) {
        final f = fish[i];
        final isSelected = _selectedFish?.uuid != null
            ? _selectedFish?.uuid == f.uuid
            : _selectedFish?.name == f.name;
        return _FishTile(
          fish: f,
          isSelected: isSelected,
          category: category,
          onTap: () {
            if (!isSelected) {
              AnalyticsService.logFeatureUsed(
                featureName: 'compat_browser_fish_selected',
                parameters: {'fish_name': f.name, 'category': category},
              );
            }
            setState(() => _selectedFish = isSelected ? null : f);
          },
        );
      },
    );
  }

  Widget _buildSelectFishPlaceholder(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.tapAFishToViewCompatibility,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  /// Detail view: shows the selected fish header + four color-coded compat sections.
  Widget _buildDetailView(
    BuildContext context,
    AppLocalizations l10n,
    List<Fish> allFish,
    Fish selected,
    String category,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    // Build map: status → list of Fish objects
    final Map<CompatStatus, List<Fish>> grouped = {
      CompatStatus.compatible: [],
      CompatStatus.withCaution: [],
      CompatStatus.notRecommended: [],
      CompatStatus.notCompatible: [],
    };

    for (final other in allFish) {
      if (other.name == selected.name) continue;
      final status = _getCompatStatus(selected, other.name);
      if (status != CompatStatus.unknown) {
        grouped[status]!.add(other);
      }
    }

    return CustomScrollView(
      slivers: [
        // Back button on narrow screens
        if (!isWide)
          SliverToBoxAdapter(
            child: TextButton.icon(
              onPressed: () => setState(() {
                _selectedFish = null;
                _collapsedSections.clear();
                _showMatrixView = false;
              }),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.backToList),
            ),
          ),
        // Fish header card — full-width
        SliverToBoxAdapter(
          child: _FishHeaderCard(
            fish: selected,
            category: category,
          ),
        ),
        // Info sections card (collapsible sections)
        if (selected.originHabitat?.isNotEmpty == true ||
            selected.careFacts.isNotEmpty ||
            selected.generalInfo?.isNotEmpty == true ||
            selected.compatibilityHighlights.isNotEmpty ||
            selected.funFact?.isNotEmpty == true)
          SliverToBoxAdapter(
            child: Padding(
              key: ValueKey('info_card_${selected.uuid ?? selected.name}'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selected.originHabitat?.isNotEmpty == true)
                        _BrowserInfoSection(
                          title: l10n.fishOriginHabitat,
                          icon: Icons.public,
                          initiallyExpanded: true,
                          child: MarkdownBody(
                            data: selected.originHabitat!,
                            styleSheet: fishInfoMarkdownStyle(context),
                          ),
                        ),
                      if (selected.careFacts.isNotEmpty)
                        _BrowserInfoSection(
                          title: l10n.fishCareFacts,
                          icon: Icons.health_and_safety_outlined,
                          initiallyExpanded: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: selected.careFacts
                                .map((fact) => _BrowserBulletItem(text: fact))
                                .toList(),
                          ),
                        ),
                      if (selected.generalInfo?.isNotEmpty == true)
                        _BrowserInfoSection(
                          title: l10n.fishGeneralInfo,
                          icon: Icons.info_outline,
                          initiallyExpanded: false,
                          child: MarkdownBody(
                            data: selected.generalInfo!,
                            styleSheet: fishInfoMarkdownStyle(context),
                          ),
                        ),
                      if (selected.compatibilityHighlights.isNotEmpty)
                        _BrowserInfoSection(
                          title: l10n.fishCompatibilityHighlights,
                          icon: Icons.people_outline,
                          initiallyExpanded: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: selected.compatibilityHighlights
                                .map(
                                  (item) => _BrowserBulletItem(text: item),
                                )
                                .toList(),
                          ),
                        ),
                      if (selected.funFact?.isNotEmpty == true)
                        _BrowserInfoSection(
                          title: l10n.fishFunFact,
                          icon: Icons.lightbulb_outline,
                          initiallyExpanded: false,
                          child: MarkdownBody(
                            data: selected.funFact!,
                            styleSheet: fishInfoMarkdownStyle(context),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Detail / Matrix view toggle chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewToggleChip(
                  label: l10n.listView,
                  icon: Icons.view_list,
                  isSelected: !_showMatrixView,
                  onTap: () => setState(() => _showMatrixView = false),
                ),
                const SizedBox(width: 8),
                _ViewToggleChip(
                  label: l10n.matrixView,
                  icon: Icons.grid_view,
                  isSelected: _showMatrixView,
                  onTap: () => setState(() => _showMatrixView = true),
                ),
              ],
            ),
          ),
        ),
        // Filter chips (tap to show/hide a category)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _buildFilterChips(context, l10n, grouped),
          ),
        ),
        // Compat sections (collapsible)
        for (final status in CompatStatus.values)
          if (status != CompatStatus.unknown &&
              grouped[status]!.isNotEmpty &&
              !_collapsedSections.contains(status)) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                l10n,
                status,
                grouped[status]!.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final other = grouped[status]![idx];
                    return _CompatFishChip(
                      fish: other,
                      status: status,
                      onTap: () => setState(() {
                        _selectedFish = other;
                        // Preserve _collapsedSections so the user's filter
                        // preferences are kept when browsing fish.
                      }),
                    );
                  },
                  childCount: grouped[status]!.length,
                ),
              ),
            ),
          ],
        // Extra bottom padding so FAB doesn't cover content
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    AppLocalizations l10n,
    Map<CompatStatus, List<Fish>> grouped,
  ) {
    // Only show chips for categories that have fish
    final available = CompatStatus.values
        .where((s) => s != CompatStatus.unknown && grouped[s]!.isNotEmpty)
        .toList();
    if (available.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: available.map((status) {
        final isHidden = _collapsedSections.contains(status);
        final color = status.color(context);
        final bg = status.backgroundColor(context);
        return GestureDetector(
          onTap: () => setState(() {
            if (isHidden) {
              _collapsedSections.remove(status);
            } else {
              _collapsedSections.add(status);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isHidden ? Theme.of(context).colorScheme.surfaceVariant : bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHidden
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.4)
                    : color.withOpacity(0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.icon,
                    color: isHidden
                        ? Theme.of(context).colorScheme.outline
                        : color,
                    size: 14),
                const SizedBox(width: 4),
                Text(
                  '${status.label(l10n)} (${grouped[status]!.length})',
                  style: TextStyle(
                    color: isHidden
                        ? Theme.of(context).colorScheme.outline
                        : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  color: isHidden
                      ? Theme.of(context).colorScheme.outline
                      : color,
                  size: 12,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    AppLocalizations l10n,
    CompatStatus status,
    int count,
  ) {
    final isCollapsed = _collapsedSections.contains(status);
    return InkWell(
      onTap: () => setState(() {
        if (isCollapsed) {
          _collapsedSections.remove(status);
        } else {
          _collapsedSections.add(status);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Icon(status.icon, color: status.color(context), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                status.label(l10n),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: status.color(context),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status.backgroundColor(context),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: status.color(context).withOpacity(0.4)),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: status.color(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: isCollapsed ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: status.color(context),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Matrix view: scrollable list of all fish vs. selected fish.
  Widget _buildMatrixView(
    BuildContext context,
    AppLocalizations l10n,
    List<Fish> allFish,
    Fish selected,
    String category,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final cs = Theme.of(context).colorScheme;

    // All others (excluding the selected fish).
    final allOthers = allFish.where((f) => f.name != selected.name).toList();

    // Build grouped map for the filter chips (same structure as detail view).
    final Map<CompatStatus, List<Fish>> grouped = {
      CompatStatus.compatible: [],
      CompatStatus.withCaution: [],
      CompatStatus.notRecommended: [],
      CompatStatus.notCompatible: [],
    };
    for (final other in allOthers) {
      final status = _getCompatStatus(selected, other.name);
      if (status != CompatStatus.unknown) {
        grouped[status]!.add(other);
      }
    }

    // Only show rows whose status is not hidden by the filter chips.
    final others = allOthers.where((f) {
      final status = _getCompatStatus(selected, f.name);
      return !_collapsedSections.contains(status);
    }).toList();

    const double rowH = 56.0;
    const double avatarW = 56.0;
    const double labelW = 140.0;

    return CustomScrollView(
      slivers: [
        // Back button on narrow screens
        if (!isWide)
          SliverToBoxAdapter(
            child: TextButton.icon(
              onPressed: () => setState(() {
                _selectedFish = null;
                _collapsedSections.clear();
                _showMatrixView = false;
              }),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.backToList),
            ),
          ),
        // Fish header card — full-width, same as detail view
        SliverToBoxAdapter(
          child: _FishHeaderCard(fish: selected, category: category),
        ),
        // Detail / Matrix view toggle chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewToggleChip(
                  label: l10n.listView,
                  icon: Icons.view_list,
                  isSelected: !_showMatrixView,
                  onTap: () => setState(() => _showMatrixView = false),
                ),
                const SizedBox(width: 8),
                _ViewToggleChip(
                  label: l10n.matrixView,
                  icon: Icons.grid_view,
                  isSelected: _showMatrixView,
                  onTap: () => setState(() => _showMatrixView = true),
                ),
              ],
            ),
          ),
        ),
        // Filter chips — same as detail view; toggling hides/shows rows
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _buildFilterChips(context, l10n, grouped),
          ),
        ),
        // Matrix rows (filtered by _collapsedSections)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final other = others[index];
              final status = _getCompatStatus(selected, other.name);
              final bgColor = status == CompatStatus.unknown
                  ? cs.surfaceVariant.withOpacity(0.3)
                  : status.backgroundColor(context);
              final fgColor = status == CompatStatus.unknown
                  ? cs.outline
                  : status.color(context);

              return InkWell(
                onTap: () => setState(() {
                  _selectedFish = other;
                  // Preserve _collapsedSections while browsing fish in matrix.
                }),
                child: Container(
                  height: rowH,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: fgColor.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Fish thumbnail
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: FishImage(
                          fish: other,
                          width: avatarW,
                          height: rowH,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Fish name
                      SizedBox(
                        width: labelW,
                        child: Text(
                          other.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Status badge
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon, color: fgColor, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              status.label(l10n),
                              style: TextStyle(
                                color: fgColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: others.length,
          ),
        ),
        // Extra bottom padding so FAB doesn't cover last row
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Full-width header card for the selected fish. Tapping the species-names
/// area expands to show all common names.
class _FishHeaderCard extends StatefulWidget {
  final Fish fish;
  final String category;

  const _FishHeaderCard({required this.fish, required this.category});

  @override
  State<_FishHeaderCard> createState() => _FishHeaderCardState();
}

class _FishHeaderCardState extends State<_FishHeaderCard> {
  bool _namesExpanded = false;

  void _openFullScreenImage(BuildContext context) {
    AnalyticsService.logFeatureUsed(
      featureName: 'compat_browser_image_viewed',
      parameters: {'fish_name': widget.fish.name},
    );

    const brokenImage = Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 64,
        color: Colors.white54,
      ),
    );

    // For Firebase Storage images, resolve the resized version.
    if (widget.fish.isStorageUrl) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.92),
        builder: (_) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: FutureBuilder<String>(
                      future: resolveResizedStorageUrl(widget.fish.imageURL),
                      initialData:
                          getCachedResizedUrl(widget.fish.imageURL) ??
                          widget.fish.imageURL,
                      builder: (context, snapshot) {
                        final url = snapshot.data ?? widget.fish.imageURL;
                        return InteractiveViewer(
                          maxScale: 5,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const SizedBox.shrink(),
                            errorWidget: (_, _, _) => brokenImage,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Image.asset(
                      widget.fish.localImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        if (widget.fish.imageURL.isNotEmpty) {
                          return CachedNetworkImage(
                            imageUrl: widget.fish.imageURL,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const SizedBox.shrink(),
                            errorWidget: (_, _, _) => brokenImage,
                          );
                        }
                        return brokenImage;
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fish = widget.fish;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Full-width image — tap to open full-screen viewer
            GestureDetector(
              onTap: () => _openFullScreenImage(context),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: FishImage(fish: fish, fit: BoxFit.cover),
              ),
            ),
            // Fullscreen hint icon in the top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _openFullScreenImage(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Gradient overlay at the bottom (tapping expands common names)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Semantics(
                  button: fish.commonNames.isNotEmpty,
                  hint: fish.commonNames.isNotEmpty
                      ? (_namesExpanded
                          ? 'Collapse common names'
                          : 'Expand common names')
                      : null,
                  child: GestureDetector(
                    onTap: fish.commonNames.isNotEmpty
                        ? () => setState(() => _namesExpanded = !_namesExpanded)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fish name
                          Text(
                            fish.name,
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                          ),
                          // Common names (expandable)
                          if (fish.commonNames.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _namesExpanded
                                        ? fish.commonNames.join(', ')
                                        : fish.commonNames.first,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color:
                                              Colors.white.withOpacity(0.85),
                                          fontStyle: FontStyle.italic,
                                        ),
                                    maxLines: _namesExpanded ? null : 1,
                                    overflow: _namesExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                  ),
                                ),
                                if (fish.commonNames.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Semantics(
                                    label: _namesExpanded
                                        ? 'Collapse common names'
                                        : 'Expand common names',
                                    child: Icon(
                                      _namesExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: Colors.white.withOpacity(0.85),
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          // Reef-safe badge
                          if (fish.reefSafe != null) ...[
                            const SizedBox(height: 6),
                            _ReefSafeBadge(status: fish.reefSafe!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FishTile extends StatelessWidget {
  final Fish fish;
  final bool isSelected;
  final String category;
  final VoidCallback onTap;

  const _FishTile({
    required this.fish,
    required this.isSelected,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withOpacity(0.4),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
          color: isSelected
              ? cs.primaryContainer.withOpacity(0.5)
              : Theme.of(context).cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with reef-safe overlay badge
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FishImage(fish: fish, fit: BoxFit.cover),
                    // Reef-safe badge — same style as FishCard
                    if (fish.reefSafe != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Builder(
                          builder: (ctx) {
                            final l10n = AppLocalizations.of(ctx)!;
                            final Color badgeColor =
                                fish.reefSafe == 'Yes'
                                    ? Colors.green
                                    : fish.reefSafe == 'Caution'
                                        ? Colors.orange
                                        : Colors.red;
                            final String badgeText =
                                fish.reefSafe == 'Yes'
                                    ? l10n.reefSafeYesLabel
                                    : fish.reefSafe == 'Caution'
                                        ? l10n.reefSafeCautionLabel
                                        : l10n.reefSafeNoLabel;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 4, sigmaY: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Name
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Text(
                fish.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.primary : null,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompatFishChip extends StatelessWidget {
  final Fish fish;
  final CompatStatus status;
  final VoidCallback onTap;

  const _CompatFishChip({
    required this.fish,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fgColor = status.color(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: fgColor.withOpacity(0.5),
            width: 1.5,
          ),
          color: status.backgroundColor(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  fish.localImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    if (fish.imageURL.isNotEmpty) {
                      return CachedNetworkImage(
                        imageUrl: fish.imageURL,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: cs.surfaceVariant,
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: cs.surfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.set_meal,
                              size: 28,
                              color: fgColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    }
                    return Container(
                      color: cs.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.set_meal,
                          size: 28,
                          color: fgColor.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Name only (no redundant status icon)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Text(
                fish.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReefSafeBadge extends StatelessWidget {
  final String status;

  const _ReefSafeBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color bgColor;
    final String label;
    if (status == 'Yes') {
      bgColor = Colors.green;
      label = l10n.reefSafeYesLabel;
    } else if (status == 'Caution') {
      bgColor = Colors.orange;
      label = l10n.reefSafeCautionLabel;
    } else {
      bgColor = Colors.red;
      label = l10n.reefSafeNoLabel;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Small toggle chip used to switch between Detail and Matrix views.
class _ViewToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cs.primary.withOpacity(0.6)
                : cs.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fish info expansion widgets (used in the detail panel info card)
// ---------------------------------------------------------------------------

/// Collapsible section inside the info card in the browser detail panel.
class _BrowserInfoSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final Widget child;

  const _BrowserInfoSection({
    required this.title,
    required this.icon,
    required this.initiallyExpanded,
    required this.child,
  });

  @override
  State<_BrowserInfoSection> createState() => _BrowserInfoSectionState();
}

class _BrowserInfoSectionState extends State<_BrowserInfoSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(widget.icon, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          widget.child,
        ],
      ],
    );
  }
}

/// Single bullet-point list item used in the browser info card.
class _BrowserBulletItem extends StatelessWidget {
  final String text;
  const _BrowserBulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: MarkdownBody(
              data: text,
              styleSheet: fishInfoMarkdownStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
