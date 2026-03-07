import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/fish.dart';
import '../models/tank.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import 'tank_creation_screen.dart' show InhabitantDialog;

/// Dedicated screen for viewing and editing details of a single tank inhabitant.
class TankInhabitantScreen extends ConsumerStatefulWidget {
  final Tank tank;
  final TankInhabitant inhabitant;

  /// Available fish list for the tank's type. Used to show the edit dialog.
  /// Sourced from [fishDataProvider] keyed on [tank.type].
  final List<Fish>? availableFish;

  const TankInhabitantScreen({
    super.key,
    required this.tank,
    required this.inhabitant,
    this.availableFish,
  });

  @override
  ConsumerState<TankInhabitantScreen> createState() =>
      _TankInhabitantScreenState();
}

class _TankInhabitantScreenState extends ConsumerState<TankInhabitantScreen> {
  late TextEditingController _notesController;
  bool _editingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.inhabitant.userNotes ?? '');
    AnalyticsService.logScreenView(screenName: 'tank_inhabitant_screen');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Always read the latest inhabitant state from the provider.
  TankInhabitant _getCurrentInhabitant() {
    final tanks = ref.watch(tankProvider).tanks;
    final tank = tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
    return tank.inhabitants.firstWhere(
      (i) => i.id == widget.inhabitant.id,
      orElse: () => widget.inhabitant,
    );
  }

  Tank _getCurrentTank() {
    final tanks = ref.watch(tankProvider).tanks;
    return tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
  }

  void _saveNotes(TankInhabitant inhabitant, Tank tank) {
    final notes = _notesController.text.trim();
    final updated = inhabitant.copyWith(
      userNotes: notes.isEmpty ? null : notes,
      clearUserNotes: notes.isEmpty,
    );
    final updatedTank = tank.copyWith(
      inhabitants: tank.inhabitants
          .map((i) => i.id == inhabitant.id ? updated : i)
          .toList(),
      updatedAt: DateTime.now(),
    );
    ref.read(tankProvider.notifier).updateTank(updatedTank);
    setState(() {
      _editingNotes = false;
    });
    AnalyticsService.logFeatureUsed(featureName: 'inhabitant_notes_saved');
  }

  /// Opens the edit dialog for the current inhabitant.
  void _showEditDialog(TankInhabitant inhabitant, Tank tank) {
    final fishDataAsync = ref.read(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );
    // Prefer the explicitly-passed list; fall back to loading from provider.
    final fishList =
        widget.availableFish ?? fishData?[tank.type] ?? const <Fish>[];
    showDialog<void>(
      context: context,
      builder: (_) => InhabitantDialog(
        availableFish: fishList,
        existingInhabitant: inhabitant,
        onAdd: (updated) {
          final updatedTank = tank.copyWith(
            inhabitants: tank.inhabitants
                .map((i) => i.id == updated.id ? updated : i)
                .toList(),
            updatedAt: DateTime.now(),
          );
          ref.read(tankProvider.notifier).updateTank(updatedTank);
          AnalyticsService.logFeatureUsed(
            featureName: 'inhabitant_edited_from_detail',
          );
        },
      ),
    );
  }

  Future<void> _pickCustomImage(TankInhabitant inhabitant, Tank tank) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.addPhoto),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.gallery),
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
            ),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(l10n.camera),
              onPressed: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        );
      },
    );
    if (source == null) return;

    try {
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final updated = inhabitant.copyWith(customImagePath: picked.path);
      final updatedTank = tank.copyWith(
        inhabitants: tank.inhabitants
            .map((i) => i.id == inhabitant.id ? updated : i)
            .toList(),
        updatedAt: DateTime.now(),
      );
      ref.read(tankProvider.notifier).updateTank(updatedTank);
      AnalyticsService.logFeatureUsed(
          featureName: 'inhabitant_custom_image_set');
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToPickImage)),
        );
      }
    }
  }

  String? _resolveImageUrl(
    TankInhabitant inhabitant,
    Tank tank,
    Map<String, List<Fish>>? fishData,
  ) {
    if (inhabitant.customImageUrl != null &&
        inhabitant.customImageUrl!.isNotEmpty) {
      return inhabitant.customImageUrl;
    }
    if (inhabitant.customImagePath != null &&
        inhabitant.customImagePath!.isNotEmpty) {
      return inhabitant.customImagePath;
    }
    if (fishData == null) return null;
    final categoryFish = fishData[tank.type] ?? [];
    final fish = categoryFish.firstWhere(
      (f) => f.name == inhabitant.fishUnit,
      orElse: () => Fish(
        name: '',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      ),
    );
    return fish.imageURL.isNotEmpty ? fish.imageURL : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final inhabitant = _getCurrentInhabitant();
    final tank = _getCurrentTank();

    final fishDataAsync = ref.watch(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );

    final imageUrl = _resolveImageUrl(inhabitant, tank, fishData);

    return Scaffold(
      appBar: AppBar(
        title: Text(inhabitant.customName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: l10n.addPhoto,
            onPressed: () => _pickCustomImage(inhabitant, tank),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'edit_inhabitant_fab',
        onPressed: () => _showEditDialog(inhabitant, tank),
        tooltip: l10n.editInhabitant,
        child: const Icon(Icons.edit_outlined),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero image
          _buildImageSection(context, imageUrl, inhabitant, tank, cs, l10n),
          const SizedBox(height: 20),
          // Info card
          _buildInfoCard(context, inhabitant, cs, l10n),
          const SizedBox(height: 16),
          // Species tags
          if (inhabitant.speciesTags.isNotEmpty) ...[
            _buildSpeciesTagsCard(context, inhabitant, cs, l10n),
            const SizedBox(height: 16),
          ],
          // User notes
          _buildNotesCard(context, inhabitant, tank, cs, l10n),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    String? imageUrl,
    TankInhabitant inhabitant,
    Tank tank,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () => _pickCustomImage(inhabitant, tank),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              imageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholderIcon(cs),
                    )
                  : Image.file(
                      File(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon(cs),
                    )
            else
              _placeholderIcon(cs),
            // Quantity badge
            if (inhabitant.quantity > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '×${inhabitant.quantity}',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Camera overlay hint
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      l10n.addPhoto,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon(ColorScheme cs) => Center(
        child: Icon(Icons.shape_line,
            size: 80, color: cs.onPrimaryContainer.withOpacity(0.4)),
      );

  Widget _buildInfoCard(
    BuildContext context,
    TankInhabitant inhabitant,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inhabitant.customName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow(
              context,
              Icons.set_meal_outlined,
              l10n.speciesType,
              inhabitant.fishUnit,
              cs,
            ),
            const Divider(height: 20),
            _infoRow(
              context,
              Icons.numbers,
              l10n.quantityLabel,
              '${inhabitant.quantity}',
              cs,
            ),
            if (inhabitant.dateAdded != null) ...[
              const Divider(height: 20),
              _infoRow(
                context,
                Icons.calendar_today_outlined,
                l10n.dateAdded,
                DateFormat.yMMMd().format(inhabitant.dateAdded!),
                cs,
              ),
              const Divider(height: 20),
              _infoRow(
                context,
                Icons.timelapse,
                l10n.inhabitantAge,
                _formatAge(context, inhabitant.dateAdded!),
                cs,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Returns a compact age string (e.g. "2y 5m") for a given start date.
  String _formatAge(BuildContext context, DateTime since) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    int years = now.year - since.year;
    int months = now.month - since.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years == 0 && months == 0) return '<1m';
    return l10n.ageYearsMonths(years, months);
  }

  Widget _buildSpeciesTagsCard(
    BuildContext context,
    TankInhabitant inhabitant,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label_outline, size: 18, color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  l10n.speciesTags,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: inhabitant.speciesTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor:
                          cs.secondaryContainer.withOpacity(0.6),
                      labelStyle: TextStyle(color: cs.onSecondaryContainer),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(
    BuildContext context,
    TankInhabitant inhabitant,
    Tank tank,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, size: 18, color: cs.tertiary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.notes,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!_editingNotes)
                  TextButton.icon(
                    icon: Icon(
                      inhabitant.userNotes == null || inhabitant.userNotes!.isEmpty
                          ? Icons.add
                          : Icons.edit_outlined,
                      size: 18,
                    ),
                    label: Text(
                      inhabitant.userNotes == null || inhabitant.userNotes!.isEmpty
                          ? l10n.addUserNotes
                          : l10n.editUserNotes,
                    ),
                    onPressed: () {
                      _notesController.text = inhabitant.userNotes ?? '';
                      setState(() {
                        _editingNotes = true;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_editingNotes) ...[
              TextField(
                controller: _notesController,
                maxLines: 5,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.userNotesHint,
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _editingNotes = false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _saveNotes(inhabitant, tank),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ] else if (inhabitant.userNotes != null &&
                inhabitant.userNotes!.isNotEmpty) ...[
              Text(
                inhabitant.userNotes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                l10n.userNotesHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.4),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
