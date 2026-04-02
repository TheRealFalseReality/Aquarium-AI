import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../providers/custom_fish_provider.dart';
import '../services/analytics_service.dart';

/// Screen for creating or editing a user-defined custom fish.
///
/// Pass a [Fish] via the route argument `fish` to edit an existing fish.
/// Omit it (or pass `null`) to create a new one.
class CustomFishEditorScreen extends ConsumerStatefulWidget {
  final Fish? fish;

  const CustomFishEditorScreen({super.key, this.fish});

  @override
  ConsumerState<CustomFishEditorScreen> createState() =>
      _CustomFishEditorScreenState();
}

class _CustomFishEditorScreenState
    extends ConsumerState<CustomFishEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Core fields
  late TextEditingController _nameCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _originHabitatCtrl;
  late TextEditingController _generalInfoCtrl;
  late TextEditingController _funFactCtrl;
  late TextEditingController _reefSafeCtrl;

  // Category
  String _category = 'freshwater';

  // Local image path (uploaded from device)
  String? _localImagePath;

  // List fields
  late List<String> _commonNames;
  late List<String> _careFacts;
  late List<String> _compatibilityHighlights;
  late List<String> _compatible;
  late List<String> _notCompatible;
  late List<String> _withCaution;
  late List<String> _notRecommended;

  bool get _isEditing => widget.fish != null;

  @override
  void initState() {
    super.initState();
    final f = widget.fish;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _imageUrlCtrl = TextEditingController(text: f?.imageURL ?? '');
    _originHabitatCtrl = TextEditingController(text: f?.originHabitat ?? '');
    _generalInfoCtrl = TextEditingController(text: f?.generalInfo ?? '');
    _funFactCtrl = TextEditingController(text: f?.funFact ?? '');
    _reefSafeCtrl = TextEditingController(text: f?.reefSafe ?? '');
    _category = f?.category ?? 'freshwater';
    _localImagePath = f?.customLocalImagePath;
    _commonNames = List<String>.from(f?.commonNames ?? []);
    _careFacts = List<String>.from(f?.careFacts ?? []);
    _compatibilityHighlights =
        List<String>.from(f?.compatibilityHighlights ?? []);
    _compatible = List<String>.from(f?.compatible ?? []);
    _notCompatible = List<String>.from(f?.notCompatible ?? []);
    _withCaution = List<String>.from(f?.withCaution ?? []);
    _notRecommended = List<String>.from(f?.notRecommended ?? []);

    AnalyticsService.logScreenView(screenName: 'custom_fish_editor_screen');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageUrlCtrl.dispose();
    _originHabitatCtrl.dispose();
    _generalInfoCtrl.dispose();
    _funFactCtrl.dispose();
    _reefSafeCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image helpers
  // ---------------------------------------------------------------------------

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // On web, only URL input is supported for custom fish images.
      return;
    }
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.customFishUploadImage),
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
      final picked =
          await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      setState(() {
        _localImagePath = picked.path;
        // Clear URL when a local file is selected so FishImage uses the file.
        _imageUrlCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToPickImage),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _localImagePath = null;
      _imageUrlCtrl.clear();
    });
  }

  Widget _buildImagePreview(AppLocalizations l10n) {
    final hasLocal = !kIsWeb && _localImagePath != null;
    final hasUrl = _imageUrlCtrl.text.trim().isNotEmpty;

    if (!hasLocal && !hasUrl) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.set_meal,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.customFishImageUrl,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: hasLocal
            ? Image.file(
                File(_localImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            : CachedNetworkImage(
                imageUrl: _imageUrlCtrl.text.trim(),
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // List editing helpers
  // ---------------------------------------------------------------------------

  /// Shows a dialog to add a new text item to [list], then calls [onUpdate].
  Future<void> _addListItem(
    BuildContext context,
    List<String> list,
    void Function(List<String>) onUpdate,
    String hintText,
  ) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hintText),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      onUpdate([...list, result]);
    }
  }

  Widget _buildEditableList({
    required String label,
    required List<String> items,
    required void Function(List<String>) onUpdate,
    required AppLocalizations l10n,
    Color? chipColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.customFishAddItem),
              onPressed: () =>
                  _addListItem(context, items, onUpdate, label),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '—',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: chipColor?.withOpacity(0.12),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      final updated = List<String>.from(items)..remove(item);
                      onUpdate(updated);
                    },
                  ),
                )
                .toList(),
          ),
        const Divider(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final imageUrl = _imageUrlCtrl.text.trim();
    final existing = widget.fish;

    final fish = Fish(
      uuid: existing?.uuid ?? const Uuid().v4(),
      name: name,
      originHabitat: _originHabitatCtrl.text.trim().isEmpty
          ? null
          : _originHabitatCtrl.text.trim(),
      careFacts: _careFacts,
      generalInfo: _generalInfoCtrl.text.trim().isEmpty
          ? null
          : _generalInfoCtrl.text.trim(),
      compatibilityHighlights: _compatibilityHighlights,
      funFact:
          _funFactCtrl.text.trim().isEmpty ? null : _funFactCtrl.text.trim(),
      commonNames: _commonNames,
      imageURL: imageUrl,
      reefSafe: _category == 'marine' && _reefSafeCtrl.text.trim().isNotEmpty
          ? _reefSafeCtrl.text.trim()
          : null,
      compatible: _compatible,
      notRecommended: _notRecommended,
      notCompatible: _notCompatible,
      withCaution: _withCaution,
      isCustom: true,
      category: _category,
      customLocalImagePath: _localImagePath,
    );

    final notifier = ref.read(customFishProvider.notifier);
    if (_isEditing) {
      await notifier.updateFish(fish);
    } else {
      await notifier.addFish(fish);
    }

    AnalyticsService.logFeatureUsed(
      featureName: _isEditing ? 'custom_fish_updated' : 'custom_fish_created',
      parameters: {
        'category': _category,
        'image_type': _localImagePath != null
            ? 'local'
            : (imageUrl.isNotEmpty ? 'url' : 'none'),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.customFishSaved),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isMarine = _category == 'marine';

    return MainLayout(
      title: _isEditing ? l10n.editCustomFish : l10n.addCustomFish,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Name ──────────────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.customFishName,
                prefixIcon: const Icon(Icons.label_outline),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.customFishNameRequired
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Category ──────────────────────────────────────────────────
            Text(l10n.customFishCategory,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'freshwater',
                  label: Text(l10n.freshwater),
                  icon: const Icon(Icons.water),
                ),
                ButtonSegment(
                  value: 'marine',
                  label: Text(l10n.marine),
                  icon: const Icon(Icons.waves),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (s) =>
                  setState(() => _category = s.first),
            ),
            const SizedBox(height: 20),

            // ── Image section ─────────────────────────────────────────────
            _buildImagePreview(l10n),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _imageUrlCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.customFishImageUrl,
                      prefixIcon: const Icon(Icons.link_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.customFishUploadImage,
                    icon: const Icon(Icons.upload_rounded),
                    onPressed: _pickImage,
                  ),
                ],
                if (_localImagePath != null ||
                    _imageUrlCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: l10n.customFishRemoveImage,
                    icon: const Icon(Icons.clear),
                    onPressed: _removeImage,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),

            // ── Common names ───────────────────────────────────────────────
            _buildEditableList(
              label: l10n.customFishCommonNames,
              items: _commonNames,
              onUpdate: (v) => setState(() => _commonNames = v),
              l10n: l10n,
            ),

            // ── Origin & Habitat ───────────────────────────────────────────
            TextFormField(
              controller: _originHabitatCtrl,
              decoration: InputDecoration(
                labelText: l10n.customFishOriginHabitat,
                prefixIcon: const Icon(Icons.place_outlined),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── General Info ───────────────────────────────────────────────
            TextFormField(
              controller: _generalInfoCtrl,
              decoration: InputDecoration(
                labelText: l10n.customFishGeneralInfo,
                prefixIcon: const Icon(Icons.info_outline),
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── Fun Fact ───────────────────────────────────────────────────
            TextFormField(
              controller: _funFactCtrl,
              decoration: InputDecoration(
                labelText: l10n.customFishFunFact,
                prefixIcon: const Icon(Icons.lightbulb_outline),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── Reef Safe (marine only) ────────────────────────────────────
            if (isMarine) ...[
              TextFormField(
                controller: _reefSafeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.customFishReefSafe,
                  prefixIcon: const Icon(Icons.verified_outlined),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 8),

            // ── Care Facts ─────────────────────────────────────────────────
            _buildEditableList(
              label: l10n.customFishCareFacts,
              items: _careFacts,
              onUpdate: (v) => setState(() => _careFacts = v),
              l10n: l10n,
            ),

            // ── Compatibility Highlights ───────────────────────────────────
            _buildEditableList(
              label: l10n.customFishCompatibilityHighlights,
              items: _compatibilityHighlights,
              onUpdate: (v) =>
                  setState(() => _compatibilityHighlights = v),
              l10n: l10n,
            ),

            const Divider(),
            const SizedBox(height: 8),
            Text(
              l10n.customFishCompatibilitySection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // ── Compatible ─────────────────────────────────────────────────
            _buildEditableList(
              label: l10n.customFishCompatibleWith,
              items: _compatible,
              onUpdate: (v) => setState(() => _compatible = v),
              l10n: l10n,
              chipColor: Colors.green,
            ),

            // ── With Caution ───────────────────────────────────────────────
            _buildEditableList(
              label: l10n.customFishWithCaution,
              items: _withCaution,
              onUpdate: (v) => setState(() => _withCaution = v),
              l10n: l10n,
              chipColor: Colors.amber,
            ),

            // ── Not Recommended ────────────────────────────────────────────
            _buildEditableList(
              label: l10n.customFishNotRecommended,
              items: _notRecommended,
              onUpdate: (v) => setState(() => _notRecommended = v),
              l10n: l10n,
              chipColor: Colors.deepOrange,
            ),

            // ── Not Compatible ─────────────────────────────────────────────
            _buildEditableList(
              label: l10n.customFishNotCompatibleWith,
              items: _notCompatible,
              onUpdate: (v) => setState(() => _notCompatible = v),
              l10n: l10n,
              chipColor: cs.error,
            ),

            const SizedBox(height: 24),

            // ── Save button ────────────────────────────────────────────────
            FilledButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.save),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
