// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main_layout.dart';
import '../providers/web_download_stub.dart'
    if (dart.library.html) '../providers/web_download_web.dart';

// ── model ────────────────────────────────────────────────────────────────────

class _FishEntry {
  String name;
  String imageURL;
  List<String> commonNames;
  List<String> compatible;
  List<String> notRecommended;
  List<String> notCompatible;
  List<String> withCaution;

  _FishEntry({
    required this.name,
    required this.imageURL,
    required this.commonNames,
    required this.compatible,
    required this.notRecommended,
    required this.notCompatible,
    required this.withCaution,
  });

  factory _FishEntry.fromJson(Map<String, dynamic> j) => _FishEntry(
        name: j['name'] as String? ?? '',
        imageURL: j['imageURL'] as String? ?? '',
        commonNames: List<String>.from(j['commonNames'] ?? []),
        compatible: List<String>.from(j['compatible'] ?? []),
        notRecommended: List<String>.from(j['notRecommended'] ?? []),
        notCompatible: List<String>.from(j['notCompatible'] ?? []),
        withCaution: List<String>.from(j['withCaution'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'commonNames': commonNames,
        'imageURL': imageURL,
        'compatible': compatible,
        'notRecommended': notRecommended,
        'notCompatible': notCompatible,
        'withCaution': withCaution,
      };
}

// ── validator ─────────────────────────────────────────────────────────────────

/// Returns a list of human-readable validation error strings.
/// An empty list means the data is valid.
List<String> _validateData(Map<String, List<_FishEntry>> data) {
  final errors = <String>[];

  for (final category in data.keys) {
    final fish = data[category]!;
    final allNames = fish.map((f) => f.name).toSet();

    for (final f in fish) {
      final prefix = '[$category] "${f.name}"';

      // Required fields
      if (f.name.trim().isEmpty) {
        errors.add('$prefix: name is required.');
      }
      if (f.imageURL.trim().isEmpty) {
        errors.add('$prefix: imageURL is required.');
      }
      if (f.commonNames.isEmpty) {
        errors.add('$prefix: at least 1 common name is required.');
      }

      // Each other fish in the same category must appear in exactly one
      // of the four compatibility sub-categories.
      final others = allNames.where((n) => n != f.name);
      for (final other in others) {
        int count = 0;
        if (f.compatible.contains(other)) count++;
        if (f.notRecommended.contains(other)) count++;
        if (f.notCompatible.contains(other)) count++;
        if (f.withCaution.contains(other)) count++;

        if (count == 0) {
          errors.add(
              '$prefix: "$other" is missing from all compatibility sub-categories.');
        } else if (count > 1) {
          errors.add(
              '$prefix: "$other" appears in $count sub-categories (must be exactly 1).');
        }
      }
    }
  }

  return errors;
}

// ── screen ────────────────────────────────────────────────────────────────────

class FishCompatEditorScreen extends StatefulWidget {
  const FishCompatEditorScreen({super.key});

  @override
  State<FishCompatEditorScreen> createState() => _FishCompatEditorScreenState();
}

class _FishCompatEditorScreenState extends State<FishCompatEditorScreen> {
  // Loaded data
  Map<String, List<_FishEntry>> _data = {};
  bool _isLoading = true;
  String? _loadError;

  // Validation
  List<String> _validationErrors = [];
  bool _validationRun = false;

  // Download state
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/fishcompat.json');
      final raw = json.decode(jsonString) as Map<String, dynamic>;
      final result = <String, List<_FishEntry>>{};
      for (final category in ['freshwater', 'marine']) {
        if (raw.containsKey(category)) {
          result[category] = (raw[category] as List)
              .map((e) => _FishEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _runValidation() {
    setState(() {
      _validationErrors = _validateData(_data);
      _validationRun = true;
    });

    if (_validationErrors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Validation passed – data looks good!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Validation Errors'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _validationErrors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _validationErrors[i],
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadJson() async {
    setState(() => _isDownloading = true);
    try {
      // Build output preserving category key order
      final output = <String, dynamic>{};
      for (final cat in ['freshwater', 'marine']) {
        if (_data.containsKey(cat)) {
          output[cat] = _data[cat]!.map((f) => f.toJson()).toList();
        }
      }
      final jsonString =
          const JsonEncoder.withIndent('  ').convert(output);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      const fileName = 'fishcompat.json';

      if (kIsWeb) {
        downloadFile(bytes, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started.')),
        );
      } else {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save fishcompat.json',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to $path')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  // ── edit helpers ─────────────────────────────────────────────────────────

  Future<void> _editFish(String category, int index) async {
    final fish = _data[category]![index];
    final oldName = fish.name;
    await showDialog<void>(
      context: context,
      builder: (_) => _FishEditDialog(
        fish: fish,
        onSave: (updated) {
          setState(() {
            _data[category]![index] = updated;
            // Propagate name change to all other fish in the same category
            if (oldName.isNotEmpty && oldName != updated.name) {
              final categoryFish = _data[category]!;
              for (int i = 0; i < categoryFish.length; i++) {
                if (i == index) continue;
                final f = categoryFish[i];
                // Only rebuild if any compatibility list actually references oldName
                final inCompatible = f.compatible.contains(oldName);
                final inNotRecommended = f.notRecommended.contains(oldName);
                final inNotCompatible = f.notCompatible.contains(oldName);
                final inWithCaution = f.withCaution.contains(oldName);
                if (!inCompatible &&
                    !inNotRecommended &&
                    !inNotCompatible &&
                    !inWithCaution) {
                  continue;
                }
                categoryFish[i] = _FishEntry(
                  name: f.name,
                  imageURL: f.imageURL,
                  commonNames: f.commonNames,
                  compatible: inCompatible
                      ? f.compatible
                          .map((n) => n == oldName ? updated.name : n)
                          .toList()
                      : f.compatible,
                  notRecommended: inNotRecommended
                      ? f.notRecommended
                          .map((n) => n == oldName ? updated.name : n)
                          .toList()
                      : f.notRecommended,
                  notCompatible: inNotCompatible
                      ? f.notCompatible
                          .map((n) => n == oldName ? updated.name : n)
                          .toList()
                      : f.notCompatible,
                  withCaution: inWithCaution
                      ? f.withCaution
                          .map((n) => n == oldName ? updated.name : n)
                          .toList()
                      : f.withCaution,
                );
              }
            }
            _validationRun = false; // reset validation badge
          });
        },
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading fishcompat.json:\n$_loadError',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      );
    } else {
      body = _buildEditor(colorScheme);
    }

    return MainLayout(
      title: 'Fish Compat Editor',
      floatingActionButton: _isLoading || _loadError != null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'validate',
                  onPressed: _runValidation,
                  icon: Icon(
                    _validationRun && _validationErrors.isEmpty
                        ? Icons.check_circle
                        : Icons.rule,
                  ),
                  label: const Text('Validate'),
                  backgroundColor: _validationRun
                      ? (_validationErrors.isEmpty
                          ? Colors.green
                          : colorScheme.error)
                      : colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'download',
                  onPressed: _isDownloading ? null : _downloadJson,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ],
            ),
      child: body,
    );
  }

  Widget _buildEditor(ColorScheme colorScheme) {
    return DefaultTabController(
      length: _data.length,
      child: Column(
        children: [
          // Debug banner
          Container(
            width: double.infinity,
            color: Colors.amber.shade700,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'DEBUG TOOL – not visible in release builds',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const Spacer(),
                if (_validationRun)
                  Icon(
                    _validationErrors.isEmpty
                        ? Icons.check_circle
                        : Icons.error,
                    color: _validationErrors.isEmpty
                        ? Colors.white
                        : Colors.red.shade200,
                    size: 16,
                  ),
              ],
            ),
          ),
          TabBar(
            tabs: _data.keys
                .map((cat) => Tab(
                      text: cat.isNotEmpty
                          ? '${cat[0].toUpperCase()}${cat.substring(1)} (${_data[cat]!.length})'
                          : '(${_data[cat]!.length})',
                    ))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: _data.keys
                  .map((cat) => _buildCategoryTab(cat, colorScheme))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, ColorScheme colorScheme) {
    final fish = _data[category]!;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
      itemCount: fish.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = fish[i];
        // Determine if this fish has validation errors
        final hasError = _validationRun &&
            _validationErrors
                .any((e) => e.startsWith('[$category] "${f.name}"'));
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasError
                ? BorderSide(color: colorScheme.error, width: 1.5)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                f.imageURL,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: colorScheme.surfaceVariant,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            title: Text(
              f.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              f.commonNames.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasError)
                  Icon(Icons.warning_amber, color: colorScheme.error, size: 18),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => _editFish(category, i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── edit dialog ───────────────────────────────────────────────────────────────

class _FishEditDialog extends StatefulWidget {
  final _FishEntry fish;
  final void Function(_FishEntry) onSave;

  const _FishEditDialog({required this.fish, required this.onSave});

  @override
  State<_FishEditDialog> createState() => _FishEditDialogState();
}

class _FishEditDialogState extends State<_FishEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late List<TextEditingController> _commonNameCtrls;
  final TextEditingController _newCommonNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.fish.name);
    _urlCtrl = TextEditingController(text: widget.fish.imageURL);
    _commonNameCtrls = widget.fish.commonNames
        .map((n) => TextEditingController(text: n))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _newCommonNameCtrl.dispose();
    for (final ctrl in _commonNameCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _addCommonName() {
    final value = _newCommonNameCtrl.text.trim();
    if (value.isEmpty) return;
    final existing = _commonNameCtrls.map((c) => c.text.trim()).toList();
    if (existing.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That common name already exists.')),
      );
      return;
    }
    setState(() {
      _commonNameCtrls.add(TextEditingController(text: value));
      _newCommonNameCtrl.clear();
    });
  }

  void _save() {
    final commonNames = _commonNameCtrls
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    final updated = _FishEntry(
      name: _nameCtrl.text.trim(),
      imageURL: _urlCtrl.text.trim(),
      commonNames: commonNames,
      compatible: widget.fish.compatible,
      notRecommended: widget.fish.notRecommended,
      notCompatible: widget.fish.notCompatible,
      withCaution: widget.fish.withCaution,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit: ${widget.fish.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Image URL
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              // Common Names
              Text('Common Names *',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              if (_commonNameCtrls.isEmpty)
                Text(
                  'No common names – at least 1 required.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12),
                ),
              ..._commonNameCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: e.value,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20),
                          tooltip: 'Remove',
                          onPressed: () {
                            final ctrl = e.value;
                            setState(() => _commonNameCtrls.removeAt(e.key));
                            ctrl.dispose();
                          },
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCommonNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add common name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCommonName(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add',
                    onPressed: _addCommonName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
