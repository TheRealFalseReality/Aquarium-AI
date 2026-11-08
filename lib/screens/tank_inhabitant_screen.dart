import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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

  bool _isMemorialized(Tank tank, TankInhabitant inhabitant) =>
      tank.memorializedInhabitants.any((i) => i.id == inhabitant.id);

  Tank _replaceInhabitant(Tank tank, TankInhabitant updated) {
    final isMemorialized = _isMemorialized(tank, updated);
    return tank.copyWith(
      inhabitants: isMemorialized
          ? tank.inhabitants
          : tank.inhabitants
              .map((i) => i.id == updated.id ? updated : i)
              .toList(),
      memorializedInhabitants: isMemorialized
          ? tank.memorializedInhabitants
              .map((i) => i.id == updated.id ? updated : i)
              .toList()
          : tank.memorializedInhabitants,
      updatedAt: DateTime.now(),
    );
  }

  Tank _removeInhabitant(Tank tank, TankInhabitant inhabitant) {
    return tank.copyWith(
      inhabitants:
          tank.inhabitants.where((i) => i.id != inhabitant.id).toList(),
      memorializedInhabitants: tank.memorializedInhabitants
          .where((i) => i.id != inhabitant.id)
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  void _saveNotes(TankInhabitant inhabitant, Tank tank) {
    final notes = _notesController.text.trim();
    final updated = inhabitant.copyWith(
      userNotes: notes.isEmpty ? null : notes,
      clearUserNotes: notes.isEmpty,
    );
    final updatedTank = _replaceInhabitant(tank, updated);
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
          final updatedTank = _replaceInhabitant(tank, updated);
          ref.read(tankProvider.notifier).updateTank(updatedTank);
          AnalyticsService.logFeatureUsed(
            featureName: 'inhabitant_edited_from_detail',
          );
        },
        onDelete: () => _performDeleteInhabitant(inhabitant, tank),
      ),
    );
  }

  /// Shows a confirmation dialog and removes the inhabitant from the tank.
  Future<void> _deleteInhabitant(
      TankInhabitant inhabitant, Tank tank) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteInhabitant),
        content: Text(l10n.deleteInhabitantConfirm(inhabitant.customName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _performDeleteInhabitant(inhabitant, tank);
    }
  }

  /// Removes the inhabitant from the tank without showing a confirmation.
  /// Used when confirmation has already been obtained (e.g., from the edit dialog).
  void _performDeleteInhabitant(TankInhabitant inhabitant, Tank tank) {
    final updatedTank = _removeInhabitant(tank, inhabitant);
    ref.read(tankProvider.notifier).updateTank(updatedTank);
    AnalyticsService.logFeatureUsed(featureName: 'inhabitant_deleted');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _recordPassing(TankInhabitant inhabitant, Tank tank) async {
    final l10n = AppLocalizations.of(context)!;
    final noteController = TextEditingController();
    // deceasedCount is returned by the dialog; null means cancelled.
    final deceasedCount = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int selected = inhabitant.quantity;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(l10n.recordPassing),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.memorializeInhabitantConfirm(inhabitant.customName)),
                  if (inhabitant.quantity > 1) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.deceasedCountLabel,
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: selected > 1
                              ? () => setDialogState(() => selected--)
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            '$selected / ${inhabitant.quantity}',
                            textAlign: TextAlign.center,
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: selected < inhabitant.quantity
                              ? () => setDialogState(() => selected++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: l10n.memorialNoteLabel,
                      hintText: l10n.memorialNoteHint,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(l10n.cancel),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(selected),
                icon: const Icon(Icons.heart_broken_outlined),
                label: Text(l10n.chooseDatePassed),
              ),
            ],
          ),
        );
      },
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (deceasedCount == null || !mounted) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: inhabitant.dateDied ?? DateTime.now(),
      firstDate: inhabitant.dateAdded ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selectedDate == null || !mounted) return;

    final remainingCount = inhabitant.quantity - deceasedCount;
    // When only some of the group die, give the memorial record its own id to
    // avoid colliding with the surviving active entry that keeps the original id.
    final memorialId =
        remainingCount > 0 ? const Uuid().v4() : inhabitant.id;
    final memorialized = inhabitant.copyWith(
      id: memorialId,
      quantity: deceasedCount,
      dateDied: selectedDate,
      memorialNote: note.isEmpty ? null : note,
      clearMemorialNote: note.isEmpty,
    );

    // Rebuild inhabitants: remove the old entry; if some survive, keep them.
    final updatedInhabitants = [
      ...tank.inhabitants.where((i) => i.id != inhabitant.id),
      if (remainingCount > 0) inhabitant.copyWith(quantity: remainingCount),
    ];
    final updatedTank = tank.copyWith(
      inhabitants: updatedInhabitants,
      memorializedInhabitants: [
        ...tank.memorializedInhabitants.where((i) => i.id != inhabitant.id),
        memorialized,
      ],
      updatedAt: DateTime.now(),
    );
    ref.read(tankProvider.notifier).updateTank(updatedTank);
    AnalyticsService.logFeatureUsed(
      featureName: 'inhabitant_passing_recorded',
      parameters: {
        'fish_type': memorialized.fishUnit,
        'deceased_count': deceasedCount,
        'partial': remainingCount > 0,
      },
    );
  }

  Future<void> _restoreToActiveTank(TankInhabitant inhabitant, Tank tank) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreToActiveTank),
        content: Text(
          l10n.restoreMemorializedInhabitantConfirm(inhabitant.customName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final restored = inhabitant.copyWith(clearDateDied: true, clearMemorialNote: true);
    final updatedTank = tank.copyWith(
      inhabitants: [
        ...tank.inhabitants.where((i) => i.id != inhabitant.id),
        restored,
      ],
      memorializedInhabitants: tank.memorializedInhabitants
          .where((i) => i.id != inhabitant.id)
          .toList(),
      updatedAt: DateTime.now(),
    );
    ref.read(tankProvider.notifier).updateTank(updatedTank);
    AnalyticsService.logFeatureUsed(
      featureName: 'inhabitant_memorial_restored',
      parameters: {'fish_type': restored.fishUnit},
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
      final updatedTank = _replaceInhabitant(tank, updated);
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
    // Resolve the latest tank and inhabitant directly in build() so that
    // ref.watch() is only ever called from the build method itself.
    final tanks = ref.watch(tankProvider).tanks;
    final tank = tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
    final inhabitant = tank.inhabitants.firstWhere(
      (i) => i.id == widget.inhabitant.id,
      orElse: () => tank.memorializedInhabitants.firstWhere(
        (i) => i.id == widget.inhabitant.id,
        orElse: () => widget.inhabitant,
      ),
    );
    final isMemorialized = _isMemorialized(tank, inhabitant);

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
            icon: Icon(
              isMemorialized
                  ? Icons.restart_alt_outlined
                  : Icons.heart_broken_outlined,
            ),
            tooltip: isMemorialized
                ? l10n.restoreToActiveTank
                : l10n.recordPassing,
            onPressed: () => isMemorialized
                ? _restoreToActiveTank(inhabitant, tank)
                : _recordPassing(inhabitant, tank),
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: l10n.addPhoto,
            onPressed: () => _pickCustomImage(inhabitant, tank),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            tooltip: l10n.deleteInhabitant,
            onPressed: () => _deleteInhabitant(inhabitant, tank),
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
          if (isMemorialized) ...[
            _buildMemorialCard(context, inhabitant, cs, l10n),
            const SizedBox(height: 16),
          ],
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
                      errorWidget: (_, _, _) => _placeholderIcon(cs),
                    )
                  : Image.file(
                      File(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholderIcon(cs),
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
            if (inhabitant.dateDied != null) ...[
              const Divider(height: 20),
              _infoRow(
                context,
                Icons.heart_broken_outlined,
                l10n.datePassed,
                DateFormat.yMMMd().format(inhabitant.dateDied!),
                cs,
              ),
              if (inhabitant.dateAdded != null) ...[
                const Divider(height: 20),
                _infoRow(
                  context,
                  Icons.auto_awesome_outlined,
                  l10n.lifespan,
                  _formatDuration(
                    context,
                    inhabitant.dateAdded!,
                    inhabitant.dateDied!,
                  ),
                  cs,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemorialCard(
    BuildContext context,
    TankInhabitant inhabitant,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return Card(
      color: cs.secondaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.heart_broken_outlined, color: cs.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.inMemoryOf(inhabitant.customName),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            if (inhabitant.memorialNote != null &&
                inhabitant.memorialNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                inhabitant.memorialNote!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSecondaryContainer,
                      fontStyle: FontStyle.italic,
                    ),
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
    return _formatDuration(context, since, DateTime.now());
  }

  String _formatDuration(BuildContext context, DateTime since, DateTime until) {
    final l10n = AppLocalizations.of(context)!;
    int years = until.year - since.year;
    int months = until.month - since.month;
    if (until.day < since.day) {
      months--;
    }
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
