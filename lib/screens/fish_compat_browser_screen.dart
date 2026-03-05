import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';

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
    switch (this) {
      case CompatStatus.compatible:
        return Colors.green.shade50;
      case CompatStatus.withCaution:
        return Colors.amber.shade50;
      case CompatStatus.notRecommended:
        return Colors.deepOrange.shade50;
      case CompatStatus.notCompatible:
        return Colors.red.shade50;
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

  static const List<String> _categories = ['freshwater', 'marine'];

  String get _currentCategory => _categories[_tabController.index];

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
      actions: [
        // Search toggle
        IconButton(
          icon: Icon(_isSearchVisible ? Icons.search_off : Icons.search),
          tooltip: l10n.searchFish,
          onPressed: () {
            setState(() {
              _isSearchVisible = !_isSearchVisible;
              if (!_isSearchVisible) {
                _searchQuery = '';
                _searchController.clear();
                _searchFocus.unfocus();
              } else {
                _searchFocus.requestFocus();
              }
            });
          },
        ),
        // Matrix view toggle (only when a fish is selected)
        if (_selectedFish != null)
          IconButton(
            icon: Icon(_showMatrixView ? Icons.view_list : Icons.grid_view),
            tooltip: _showMatrixView ? l10n.listView : l10n.matrixView,
            onPressed: () => setState(() => _showMatrixView = !_showMatrixView),
          ),
      ],
      child: Column(
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
          // Search bar (animated)
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: l10n.searchFish,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            crossFadeState: _isSearchVisible
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                return fishDataAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(l10n.fishDataNotAvailable),
                  ),
                  data: (fishMap) {
                    final allFish = fishMap[cat] ?? [];
                    final filtered = _filterFish(allFish);
                    return _buildCategoryView(context, l10n, filtered, allFish, cat);
                  },
                );
              }).toList(),
            ),
          ),
        ],
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
                    ? _buildMatrixView(context, l10n, all, _selectedFish!)
                    : _buildDetailView(context, l10n, all, _selectedFish!, category))
                : _buildSelectFishPlaceholder(context, l10n),
          ),
        ],
      );
    }

    // On narrow screens, show either list or detail
    if (_selectedFish != null) {
      return _showMatrixView
          ? _buildMatrixView(context, l10n, all, _selectedFish!)
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
      padding: const EdgeInsets.all(12),
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
          onTap: () => setState(() => _selectedFish = isSelected ? null : f),
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
    final cs = Theme.of(context).colorScheme;
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
              onPressed: () => setState(() => _selectedFish = null),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.backToList),
            ),
          ),
        // Fish header card
        SliverToBoxAdapter(
          child: _buildFishHeader(context, l10n, selected, cs, category),
        ),
        // Legend
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _buildLegend(context, l10n),
          ),
        ),
        // Compat sections
        for (final status in CompatStatus.values)
          if (status != CompatStatus.unknown && grouped[status]!.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, l10n, status, grouped[status]!.length),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                      onTap: () => setState(() => _selectedFish = other),
                    );
                  },
                  childCount: grouped[status]!.length,
                ),
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildFishHeader(
    BuildContext context,
    AppLocalizations l10n,
    Fish fish,
    ColorScheme cs,
    String category,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fish image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: CachedNetworkImage(
              imageUrl: fish.imageURL,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 120,
                height: 120,
                color: cs.surfaceVariant,
                child: Icon(Icons.set_meal, size: 40, color: cs.outline),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 120,
                height: 120,
                color: cs.surfaceVariant,
                child: Icon(Icons.set_meal, size: 40, color: cs.outline),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name + info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fish.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                  if (fish.commonNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      fish.commonNames.join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withOpacity(0.75),
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (fish.reefSafe != null) ...[
                    const SizedBox(height: 8),
                    _ReefSafeBadge(status: fish.reefSafe!, l10n: l10n),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: CompatStatus.values
          .where((s) => s != CompatStatus.unknown)
          .map((s) => _LegendChip(status: s, l10n: l10n))
          .toList(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    AppLocalizations l10n,
    CompatStatus status,
    int count,
  ) {
    return Padding(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status.backgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status.color(context).withOpacity(0.4)),
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
        ],
      ),
    );
  }

  /// Matrix view: scrollable grid of all fish vs. all fish.
  Widget _buildMatrixView(
    BuildContext context,
    AppLocalizations l10n,
    List<Fish> allFish,
    Fish selected,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final cs = Theme.of(context).colorScheme;

    // Filter out the selected fish; show ALL others in matrix rows
    final others = allFish.where((f) => f.name != selected.name).toList();
    const double rowH = 56.0;
    const double avatarW = 56.0;
    const double labelW = 140.0;

    return Column(
      children: [
        if (!isWide)
          TextButton.icon(
            onPressed: () => setState(() => _selectedFish = null),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.backToList),
          ),
        // Selected fish chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  '${l10n.matrixViewForFish(selected.name)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildLegend(context, l10n),
        ),
        // Matrix table
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: others.map((other) {
                final status = _getCompatStatus(selected, other.name);
                final bgColor = status == CompatStatus.unknown
                    ? cs.surfaceVariant.withOpacity(0.3)
                    : status.backgroundColor(context);
                final fgColor = status == CompatStatus.unknown
                    ? cs.outline
                    : status.color(context);

                return InkWell(
                  onTap: () => setState(() => _selectedFish = other),
                  child: Container(
                    height: rowH,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                          child: CachedNetworkImage(
                            imageUrl: other.imageURL,
                            width: avatarW,
                            height: rowH,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => SizedBox(
                              width: avatarW,
                              height: rowH,
                              child: Icon(Icons.set_meal, color: cs.outline),
                            ),
                            errorWidget: (_, __, ___) => SizedBox(
                              width: avatarW,
                              height: rowH,
                              child: Icon(Icons.set_meal, color: cs.outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Fish name
                        SizedBox(
                          width: labelW,
                          child: Text(
                            other.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

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
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: fish.imageURL,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: cs.surfaceVariant,
                    child: Center(
                      child: Icon(Icons.set_meal, size: 36, color: cs.outline),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: cs.surfaceVariant,
                    child: Center(
                      child: Icon(Icons.set_meal, size: 36, color: cs.outline),
                    ),
                  ),
                ),
              ),
            ),
            // Name
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
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
            // Reef-safe badge (marine)
            if (fish.reefSafe != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Center(
                  child: _ReefSafeDot(status: fish.reefSafe!),
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
                child: CachedNetworkImage(
                  imageUrl: fish.imageURL,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: cs.surfaceVariant,
                    child: Center(
                      child: Icon(Icons.set_meal, size: 28, color: fgColor.withOpacity(0.5)),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: cs.surfaceVariant,
                    child: Center(
                      child: Icon(Icons.set_meal, size: 28, color: fgColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ),
            // Status icon + name
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Column(
                children: [
                  Icon(status.icon, color: fgColor, size: 14),
                  const SizedBox(height: 2),
                  Text(
                    fish.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final CompatStatus status;
  final AppLocalizations l10n;

  const _LegendChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    final bg = status.backgroundColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            status.label(l10n),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReefSafeBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;

  const _ReefSafeBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;
    if (status == 'Yes') {
      color = Colors.green.shade700;
      icon = Icons.check_circle;
      label = l10n.reefSafeYesLabel;
    } else if (status == 'No') {
      color = Colors.red.shade700;
      icon = Icons.cancel;
      label = l10n.reefSafeNoLabel;
    } else {
      color = Colors.amber.shade700;
      icon = Icons.warning_amber_rounded;
      label = l10n.reefSafeCautionLabel;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ReefSafeDot extends StatelessWidget {
  final String status;

  const _ReefSafeDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == 'Yes') {
      color = Colors.green.shade600;
    } else if (status == 'No') {
      color = Colors.red.shade600;
    } else {
      color = Colors.amber.shade600;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
