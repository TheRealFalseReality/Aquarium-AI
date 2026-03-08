import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/fish.dart';
import '../providers/fish_compatibility_provider.dart';
import '../providers/species_tags_provider.dart';
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FishInfoSheet(
        fish: widget.fish,
        category: widget.category,
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
              padding: const EdgeInsets.all(6),
              child: AnimatedRotation(
                turns: isOpen ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isOpen ? Icons.close : Icons.more_vert,
                  color: Colors.white,
                  size: 20,
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Tooltip(
            message: tooltip,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(icon, color: Colors.white, size: 18),
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

/// Modal bottom sheet showing the full details of a fish type.
/// Accessible via the speed-dial info button on the fish card.
class _FishInfoSheet extends StatelessWidget {
  final Fish fish;
  final String category;
  const _FishInfoSheet({required this.fish, required this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        child: FishImage(fish: fish, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fish.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (fish.commonNames.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        fish.commonNames.join(', '),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    if (fish.reefSafe != null) ...[
                      const SizedBox(height: 8),
                      _ReefSafeRow(status: fish.reefSafe!, l10n: l10n),
                    ],
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
                      fish.description?.isNotEmpty == true
                          ? fish.description!
                          : l10n.noDescriptionAvailable,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: fish.description?.isNotEmpty == true
                                ? null
                                : cs.onSurface.withOpacity(0.5),
                            fontStyle: fish.description?.isNotEmpty == true
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            category == 'marine'
                                ? l10n.marine
                                : l10n.freshwater,
                          ),
                          avatar: Icon(
                            category == 'marine'
                                ? Icons.waves
                                : Icons.water,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
