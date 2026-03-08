import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/fish.dart';
import '../providers/fish_compatibility_provider.dart';
import '../providers/species_tags_provider.dart';
import '../screens/fish_compat_browser_screen.dart';
import '../services/fish_data_service.dart';
import '../theme_provider.dart';
import 'fish_image.dart';

class FishCard extends ConsumerStatefulWidget {
  final Fish fish;
  final bool isSelected;
  final String category;
  final bool showSpeciesTags;
  final VoidCallback? onTap;

  const FishCard({
    super.key,
    required this.fish,
    required this.isSelected,
    required this.category,
    this.showSpeciesTags = false,
    this.onTap,
  });

  @override
  ConsumerState<FishCard> createState() => _FishCardState();
}

class _FishCardState extends ConsumerState<FishCard>
    with SingleTickerProviderStateMixin {
  bool _speedDialOpen = false;

  void _toggleSpeedDial() {
    setState(() => _speedDialOpen = !_speedDialOpen);
  }

  void _closeSpeedDial() {
    if (_speedDialOpen) setState(() => _speedDialOpen = false);
  }

  Future<void> _launchGoogleSearch() async {
    _closeSpeedDial();
    final categoryLabel =
        widget.category == 'marine' ? 'saltwater' : widget.category;
    final query = Uri.encodeComponent('${widget.fish.name} $categoryLabel');
    final uri = Uri.parse('https://www.google.com/search?q=$query');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  void _showFishInfo() {
    _closeSpeedDial();
    // Load all fish for the same category so the sheet can show compat info.
    final fishDataAsync = ref.read(fishDataProvider);
    final allFish = fishDataAsync.asData?.value[widget.category] ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FishInfoSheet(
        fish: widget.fish,
        category: widget.category,
        allFish: allFish,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeProviderNotifierProvider);
    final isMaterialYou = themeState.useMaterialYou;
    final notifier = ref.read(fishCompatibilityProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    Color? getCardColor() {
      if (widget.isSelected) return null;
      if (isMaterialYou) return cs.surfaceVariant;
      return Theme.of(context).cardColor;
    }

    BorderSide getBorder() {
      if (widget.isSelected) return BorderSide(color: cs.primary, width: 3);
      if (isMaterialYou) {
        return BorderSide(color: cs.outlineVariant.withOpacity(0.6), width: 1.5);
      }
      return BorderSide(color: cs.outlineVariant.withOpacity(0.25), width: 1.2);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: getBorder().color, width: getBorder().width),
        boxShadow: [
          if (widget.isSelected)
            BoxShadow(
              color: cs.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(isMaterialYou ? 0.08 : 0.05),
            blurRadius: isMaterialYou ? 8 : 6,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: widget.isSelected
            ? LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.18),
                  cs.secondary.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isMaterialYou && !widget.isSelected
                ? LinearGradient(
                    colors: [
                      cs.surfaceContainer,
                      cs.primaryContainer.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
        color: getCardColor(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (_speedDialOpen) {
              _closeSpeedDial();
              return;
            }
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              notifier.selectFish(widget.fish);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FishImage(fish: widget.fish, fit: BoxFit.cover),
                      // Speed-dial overlay at top-left
                      Positioned(
                        top: 4,
                        left: 4,
                        child: _buildSpeedDial(context, l10n, cs),
                      ),
                      // Reef-safe badge at top-right
                      if (widget.fish.reefSafe != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (widget.fish.reefSafe == 'Yes'
                                          ? Colors.green
                                          : widget.fish.reefSafe == 'Caution'
                                              ? Colors.orange
                                              : Colors.red)
                                      .withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.fish.reefSafe == 'Yes'
                                      ? '🪸 Safe'
                                      : widget.fish.reefSafe == 'Caution'
                                          ? '⚠️ Caution'
                                          : '✗ Unsafe',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Text(
                      widget.fish.name,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: widget.isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: widget.isSelected
                                    ? cs.primary
                                    : (isMaterialYou
                                        ? cs.onSurfaceVariant
                                        : null),
                              ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    if (widget.fish.commonNames.isNotEmpty ||
                        widget.showSpeciesTags)
                      Builder(
                        builder: (context) {
                          List<String> displayNames =
                              List.from(widget.fish.commonNames);
                          if (widget.showSpeciesTags) {
                            final speciesTags = ref
                                .read(speciesTagsProvider.notifier)
                                .getTagsForFishType(widget.fish.name);
                            final commonNamesLower = widget.fish.commonNames
                                .map((n) => n.toLowerCase())
                                .toSet();
                            for (final tag in speciesTags) {
                              if (!commonNamesLower
                                  .contains(tag.toLowerCase())) {
                                displayNames.add(tag);
                              }
                            }
                          }
                          if (displayNames.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            displayNames.join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isMaterialYou
                                      ? cs.onSurfaceVariant.withOpacity(0.8)
                                      : null,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDial(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Action buttons — visible only when dial is open
        if (_speedDialOpen) ...[
          _SpeedDialAction(
            icon: Icons.info_outline,
            tooltip: l10n.viewFishInfo,
            onTap: _showFishInfo,
          ),
          const SizedBox(height: 4),
          _SpeedDialAction(
            icon: Icons.search,
            tooltip: l10n.googleSearchFish,
            onTap: _launchGoogleSearch,
          ),
          const SizedBox(height: 4),
        ],
        // Toggle button
        _SpeedDialToggle(isOpen: _speedDialOpen, onTap: _toggleSpeedDial),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Speed-dial sub-widgets
// ---------------------------------------------------------------------------

class _SpeedDialToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _SpeedDialToggle({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedRotation(
                turns: isOpen ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isOpen ? Icons.close : Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedDialAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _SpeedDialAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Tooltip(
            message: tooltip,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fish info bottom sheet
// ---------------------------------------------------------------------------

/// Returns the compatibility status of [otherName] relative to [source].
CompatStatus _resolveCompat(Fish source, String otherName) {
  if (source.compatible.contains(otherName)) return CompatStatus.compatible;
  if (source.withCaution.contains(otherName)) return CompatStatus.withCaution;
  if (source.notRecommended.contains(otherName)) {
    return CompatStatus.notRecommended;
  }
  if (source.notCompatible.contains(otherName)) {
    return CompatStatus.notCompatible;
  }
  return CompatStatus.unknown;
}

/// Modal bottom sheet showing the full details of a fish type, including
/// compatibility categories with filter chips.
///
/// Uses most of the screen on mobile. Tapping a fish in the compat categories
/// does NOT navigate — this is informational only.
class _FishInfoSheet extends StatefulWidget {
  final Fish fish;
  final String category;
  final List<Fish> allFish;

  const _FishInfoSheet({
    required this.fish,
    required this.category,
    required this.allFish,
  });

  @override
  State<_FishInfoSheet> createState() => _FishInfoSheetState();
}

class _FishInfoSheetState extends State<_FishInfoSheet> {
  final Set<CompatStatus> _hiddenSections = {};

  void _openFullScreenImage(BuildContext context) {
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
                      errorBuilder: (_, __, ___) {
                        if (widget.fish.imageURL.isNotEmpty) {
                          return CachedNetworkImage(
                            imageUrl: widget.fish.imageURL,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const SizedBox.shrink(),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                          );
                        }
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                        );
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
    final l10n = AppLocalizations.of(context)!;

    // Build compatibility groups
    final Map<CompatStatus, List<Fish>> grouped = {
      CompatStatus.compatible: [],
      CompatStatus.withCaution: [],
      CompatStatus.notRecommended: [],
      CompatStatus.notCompatible: [],
    };
    for (final other in widget.allFish) {
      if (other.name == widget.fish.name) continue;
      final status = _resolveCompat(widget.fish, other.name);
      if (status != CompatStatus.unknown) {
        grouped[status]!.add(other);
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.fishTypeInfo,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.close,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // Fish image — tap to view full-screen
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _openFullScreenImage(context),
                            child: SizedBox(
                              width: double.infinity,
                              height: 200,
                              child: FishImage(
                                fish: widget.fish,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _openFullScreenImage(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      widget.fish.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    // Common names
                    if (widget.fish.commonNames.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.fish.commonNames.join(', '),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    // Reef safe badge
                    if (widget.fish.reefSafe != null) ...[
                      const SizedBox(height: 8),
                      _ReefSafeRow(
                        status: widget.fish.reefSafe!,
                        l10n: l10n,
                      ),
                    ],
                    // Category chip
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            widget.category == 'marine'
                                ? l10n.marine
                                : l10n.freshwater,
                          ),
                          avatar: Icon(
                            widget.category == 'marine'
                                ? Icons.waves
                                : Icons.water,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    // Description
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.fishDescription,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.fish.description?.isNotEmpty == true
                          ? widget.fish.description!
                          : l10n.noDescriptionAvailable,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                widget.fish.description?.isNotEmpty == true
                                    ? null
                                    : cs.onSurface.withOpacity(0.5),
                            fontStyle:
                                widget.fish.description?.isNotEmpty == true
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                          ),
                    ),
                    // Compatibility section
                    if (grouped.values.any((l) => l.isNotEmpty)) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Filter chips
                      _buildFilterChips(l10n, grouped),
                      const SizedBox(height: 8),
                      // Compat category sections
                      for (final status in CompatStatus.values)
                        if (status != CompatStatus.unknown &&
                            grouped[status]!.isNotEmpty &&
                            !_hiddenSections.contains(status)) ...[
                          _buildSectionHeader(
                            context,
                            l10n,
                            status,
                            grouped[status]!.length,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: grouped[status]!.map((other) {
                              return _MiniCompatChip(
                                fish: other,
                                status: status,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(
    AppLocalizations l10n,
    Map<CompatStatus, List<Fish>> grouped,
  ) {
    final available = CompatStatus.values
        .where(
            (s) => s != CompatStatus.unknown && grouped[s]!.isNotEmpty)
        .toList();
    if (available.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: available.map((status) {
        final isHidden = _hiddenSections.contains(status);
        final color = status.color(context);
        final bg = status.backgroundColor(context);
        return GestureDetector(
          onTap: () => setState(() {
            if (isHidden) {
              _hiddenSections.remove(status);
            } else {
              _hiddenSections.add(status);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isHidden
                  ? Theme.of(context).colorScheme.surfaceVariant
                  : bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHidden
                    ? Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.4)
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
    return Row(
      children: [
        Icon(status.icon, color: status.color(context), size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            status.label(l10n),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: status.color(context),
                ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: status.backgroundColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: status.color(context).withOpacity(0.4),
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: status.color(context),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small chip showing a fish name with a color-coded border.
/// Non-tappable (informational only in the info sheet).
class _MiniCompatChip extends StatelessWidget {
  final Fish fish;
  final CompatStatus status;
  const _MiniCompatChip({required this.fish, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    final bg = status.backgroundColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small round image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: FishImage(fish: fish, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              fish.name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReefSafeRow extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _ReefSafeRow({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (status == 'Yes') {
      color = Colors.green;
      label = l10n.reefSafeYesLabel;
    } else if (status == 'Caution') {
      color = Colors.orange;
      label = l10n.reefSafeCautionLabel;
    } else {
      color = Colors.red;
      label = l10n.reefSafeNoLabel;
    }
    return Row(
      children: [
        Icon(Icons.eco, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '${l10n.reefSafe}: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
