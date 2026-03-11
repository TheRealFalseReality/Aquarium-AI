// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../main_layout.dart';
import '../providers/web_download_stub.dart'
    if (dart.library.html) '../providers/web_download_web.dart';
import '../services/analytics_service.dart';
import '../services/fish_firestore_service.dart';
import '../utils/storage_image_utils.dart';

// ── authorised editor ─────────────────────────────────────────────────────────

/// The Firebase Auth UID that is permitted to write fish data to Firestore.
const String _authorizedEditorUid = String.fromEnvironment('AUTHORIZED_USER');

// ── model ────────────────────────────────────────────────────────────────────

/// Sentinel value used by [_FishEntry.copyWith] to distinguish an explicit
/// `null` from "not provided" for the nullable [_FishEntry.reefSafe] field.
const Object _sentinel = Object();

class _FishEntry {
  String uuid;
  String name;
  String imageURL;
  String? originHabitat; // Where the fish originates / its natural habitat
  List<String> careFacts; // Bullet-point care information
  String? generalInfo; // General aquarium information (short paragraph)
  List<String> compatibilityHighlights; // Compatibility highlight bullets
  String? funFact; // Short fun fact about the species
  List<String> commonNames;
  String? reefSafe;
  List<String> compatible;
  List<String> notRecommended;
  List<String> notCompatible;
  List<String> withCaution;

  _FishEntry({
    String? uuid,
    required this.name,
    required this.imageURL,
    this.originHabitat,
    List<String>? careFacts,
    this.generalInfo,
    List<String>? compatibilityHighlights,
    this.funFact,
    required this.commonNames,
    this.reefSafe,
    required this.compatible,
    required this.notRecommended,
    required this.notCompatible,
    required this.withCaution,
  })  : uuid = uuid ?? const Uuid().v4(),
        careFacts = careFacts ?? [],
        compatibilityHighlights = compatibilityHighlights ?? [];

  factory _FishEntry.fromJson(Map<String, dynamic> j) => _FishEntry(
    uuid: j['uuid'] as String?,
    name: j['name'] as String? ?? '',
    imageURL: j['imageURL'] as String? ?? '',
    originHabitat: j['originHabitat'] as String?,
    careFacts: List<String>.from(j['careFacts'] ?? []),
    generalInfo: j['generalInfo'] as String?,
    compatibilityHighlights: List<String>.from(
      j['compatibilityHighlights'] ?? [],
    ),
    funFact: j['funFact'] as String?,
    commonNames: List<String>.from(j['commonNames'] ?? []),
    reefSafe: j['reefSafe'] as String?,
    compatible: List<String>.from(j['compatible'] ?? []),
    notRecommended: List<String>.from(j['notRecommended'] ?? []),
    notCompatible: List<String>.from(j['notCompatible'] ?? []),
    withCaution: List<String>.from(j['withCaution'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'commonNames': commonNames,
    'imageURL': imageURL,
    if (originHabitat != null && originHabitat!.isNotEmpty)
      'originHabitat': originHabitat,
    if (careFacts.isNotEmpty) 'careFacts': careFacts,
    if (generalInfo != null && generalInfo!.isNotEmpty)
      'generalInfo': generalInfo,
    if (compatibilityHighlights.isNotEmpty)
      'compatibilityHighlights': compatibilityHighlights,
    if (funFact != null && funFact!.isNotEmpty) 'funFact': funFact,
    if (reefSafe != null) 'reefSafe': reefSafe,
    'compatible': compatible,
    'notRecommended': notRecommended,
    'notCompatible': notCompatible,
    'withCaution': withCaution,
  };

  _FishEntry copy() => _FishEntry.fromJson(toJson());

  _FishEntry copyWith({
    String? uuid,
    String? name,
    String? imageURL,
    Object? originHabitat = _sentinel,
    List<String>? careFacts,
    Object? generalInfo = _sentinel,
    List<String>? compatibilityHighlights,
    Object? funFact = _sentinel,
    List<String>? commonNames,
    Object? reefSafe = _sentinel,
    List<String>? compatible,
    List<String>? notRecommended,
    List<String>? notCompatible,
    List<String>? withCaution,
  }) => _FishEntry(
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    imageURL: imageURL ?? this.imageURL,
    originHabitat: originHabitat == _sentinel
        ? this.originHabitat
        : originHabitat as String?,
    careFacts: careFacts ?? List<String>.from(this.careFacts),
    generalInfo:
        generalInfo == _sentinel ? this.generalInfo : generalInfo as String?,
    compatibilityHighlights: compatibilityHighlights ??
        List<String>.from(this.compatibilityHighlights),
    funFact: funFact == _sentinel ? this.funFact : funFact as String?,
    commonNames: commonNames ?? List<String>.from(this.commonNames),
    reefSafe: reefSafe == _sentinel ? this.reefSafe : reefSafe as String?,
    compatible: compatible ?? List<String>.from(this.compatible),
    notRecommended: notRecommended ?? List<String>.from(this.notRecommended),
    notCompatible: notCompatible ?? List<String>.from(this.notCompatible),
    withCaution: withCaution ?? List<String>.from(this.withCaution),
  );

  /// Local asset path derived from [imageURL].
  ///
  /// Returns an empty string for Firebase Storage URLs since those images have
  /// no corresponding local asset.
  String get localImagePath {
    if (_isFirebaseStorageUrl(imageURL)) return '';
    const assetsMarker = 'assets/';
    final idx = imageURL.indexOf(assetsMarker);
    if (idx != -1) return imageURL.substring(idx);
    // Fallback for bare filenames without a URL prefix.
    final filename = imageURL.contains('/') ? imageURL.split('/').last : imageURL;
    final base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return 'assets/images/fish/$base.webp';
  }
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

      // The fish must reference itself in exactly one sub-category.
      int selfCount = 0;
      if (f.compatible.contains(f.name)) selfCount++;
      if (f.notRecommended.contains(f.name)) selfCount++;
      if (f.notCompatible.contains(f.name)) selfCount++;
      if (f.withCaution.contains(f.name)) selfCount++;
      if (selfCount == 0) {
        errors.add(
          '$prefix: missing self-reference (the fish must appear in one of its own compatibility sub-categories).',
        );
      } else if (selfCount > 1) {
        errors.add(
          '$prefix: appears in $selfCount of its own sub-categories (must be exactly 1).',
        );
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
            '$prefix: "$other" is missing from all compatibility sub-categories.',
          );
        } else if (count > 1) {
          errors.add(
            '$prefix: "$other" appears in $count sub-categories (must be exactly 1).',
          );
        }
      }
    }
  }

  return errors;
}

// ── storage helpers ───────────────────────────────────────────────────────────

/// Firebase Storage path prefix for uploaded fish images.
const _kFishImagesPath = 'fish_images';

/// Returns `true` when [url] is a Firebase Storage download URL.
bool _isFirebaseStorageUrl(String url) =>
    url.contains('firebasestorage.googleapis.com');

/// Uploads [bytes] to Firebase Storage under [_kFishImagesPath] and returns
/// the public download URL, or `null` on failure.
Future<String?> _uploadFishImage(Uint8List bytes, String fileName) async {
  try {
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : 'jpg';
    final uploadName =
        '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = FirebaseStorage.instance
        .ref()
        .child('$_kFishImagesPath/$uploadName');
    final metadata = SettableMetadata(
      contentType: switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      },
    );
    final task = await ref.putData(bytes, metadata);
    return await task.ref.getDownloadURL();
  } catch (e) {
    if (kDebugMode) debugPrint('_uploadFishImage error: $e');
    return null;
  }
}

/// Deletes a Firebase Storage object by its download [url].
/// Does nothing if [url] is not a Firebase Storage URL.
Future<void> _deleteStorageImageByUrl(String url) async {
  if (!_isFirebaseStorageUrl(url)) return;
  try {
    await FirebaseStorage.instance.refFromURL(url).delete();
  } catch (e) {
    if (kDebugMode) debugPrint('_deleteStorageImageByUrl error: $e');
  }
}

// ── screen ────────────────────────────────────────────────────────────────────

/// Capitalises the first character of [s]; safe for empty and single-char strings.
String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class FishCompatEditorScreen extends StatefulWidget {
  const FishCompatEditorScreen({super.key});

  @override
  State<FishCompatEditorScreen> createState() => _FishCompatEditorScreenState();
}

class _FishCompatEditorScreenState extends State<FishCompatEditorScreen> {
  // Working copy of loaded data
  Map<String, List<_FishEntry>> _data = {};

  // Last explicitly-saved snapshot (used for dirty tracking and undo)
  Map<String, List<_FishEntry>> _savedData = {};
  bool _isLoading = true;
  String? _loadError;
  bool _isSavingToFirestore = false;
  bool _isRefreshing = false;

  // Validation
  List<String> _validationErrors = [];
  bool _validationRun = false;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Download state
  bool _isDownloading = false;

  // Grid column count (1–4)
  int _columnCount = 2;

  /// Whether the currently signed-in user is the authorised Firestore editor.
  bool get _isAuthorizedEditor =>
      FirebaseAuth.instance.currentUser?.uid == _authorizedEditorUid;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'fish_compat_editor_screen');
    _loadData();
    _searchCtrl.addListener(
      () =>
          setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── deep copy / change tracking ───────────────────────────────────────────

  Map<String, List<_FishEntry>> _deepCopy(Map<String, List<_FishEntry>> src) =>
      src.map((cat, list) => MapEntry(cat, list.map((f) => f.copy()).toList()));

  /// Computes dirty state in a single pass.
  /// Returns the count of modified fish and a map of modified indices per category.
  ({int count, Map<String, Set<int>> modifiedIndices}) _computeDirtyInfo() {
    int count = 0;
    final modifiedIndices = <String, Set<int>>{};
    for (final cat in _data.keys) {
      final current = _data[cat]!;
      final saved = _savedData[cat];
      if (saved == null) continue;
      for (int i = 0; i < current.length; i++) {
        if (i >= saved.length) {
          // Newly added fish — no saved baseline yet
          count++;
          modifiedIndices.putIfAbsent(cat, () => {}).add(i);
          continue;
        }
        if (json.encode(current[i].toJson()) !=
            json.encode(saved[i].toJson())) {
          count++;
          modifiedIndices.putIfAbsent(cat, () => {}).add(i);
        }
      }
    }
    return (count: count, modifiedIndices: modifiedIndices);
  }

  Future<void> _loadData({bool fromFirestore = true}) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    // Try Firestore (primary and only source).
    if (fromFirestore) {
      try {
        final firestoreData = await FishFirestoreService.fetchFishData()
            .timeout(const Duration(seconds: 10));
        if (firestoreData != null && firestoreData.isNotEmpty) {
          final result = <String, List<_FishEntry>>{};
          for (final category in ['freshwater', 'marine']) {
            final rawList = firestoreData[category];
            if (rawList != null && rawList.isNotEmpty) {
              final list = rawList
                  .map((e) => _FishEntry.fromJson(e))
                  .toList();
              list.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
              result[category] = list;
            }
          }
          if (result.isNotEmpty) {
            setState(() {
              _data = result;
              _savedData = _deepCopy(result);
              _isLoading = false;
            });
            return;
          }
        }
        // Firestore returned empty / null data.
        setState(() {
          _loadError = 'Firestore returned no fish data. '
              'Please upload data first or check your connection.';
          _isLoading = false;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('FishCompatEditor: Firestore load failed ($e).');
        }
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isAuthorizedEditor) {
      // Build the JSON map from the working copy and upload to Firestore.
      setState(() => _isSavingToFirestore = true);
      try {
        final output = <String, dynamic>{};
        for (final cat in ['freshwater', 'marine']) {
          if (_data.containsKey(cat)) {
            output[cat] = _data[cat]!.map((f) => f.toJson()).toList();
          }
        }
        await FishFirestoreService.uploadJsonData(output);
        // Only mark as saved after a successful Firestore upload.
        setState(() {
          _savedData = _deepCopy(_data);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Saved to Firestore.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Firestore save failed: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSavingToFirestore = false);
      }
    } else {
      // Local-only save (non-editor): commit working copy as the baseline.
      setState(() {
        _savedData = _deepCopy(_data);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Changes saved locally. Sign in as the editor account to save to Firestore.',
          ),
        ),
      );
    }
  }

  /// Reload the latest data from Firestore, discarding any unsaved local edits.
  Future<void> _refreshFromFirestore() async {
    if (_computeDirtyInfo().count > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'Refreshing will discard your unsaved changes. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard & Refresh'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _isRefreshing = true);
    await _loadData(fromFirestore: true);
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Refreshed from Firestore.')),
      );
    }
  }

  Future<void> _undoChanges() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Undo Changes'),
        content: const Text(
          'Revert all unsaved changes to the last saved state?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _data = _deepCopy(_savedData);
        _validationRun = false;
      });
    }
  }

  /// Shows a dialog when the user tries to leave with unsaved changes.
  /// Returns true if navigation should proceed (save or discard chosen).
  Future<bool> _confirmDiscard() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Save or discard before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save & Leave'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _saveChanges();
      return true;
    }
    return result == 'discard';
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
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _validationErrors[i],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
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
    // Auto-save (commit) before download
    setState(() => _savedData = _deepCopy(_data));
    setState(() => _isDownloading = true);
    try {
      // Build output preserving category key order
      final output = <String, dynamic>{};
      for (final cat in ['freshwater', 'marine']) {
        if (_data.containsKey(cat)) {
          output[cat] = _data[cat]!.map((f) => f.toJson()).toList();
        }
      }
      final jsonString = const JsonEncoder.withIndent('  ').convert(output);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      const fileName = 'fishcompat.json';

      if (kIsWeb) {
        downloadFile(bytes, fileName);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download started.')));
      } else {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save fishcompat.json',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
        if (path != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to $path')));
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
        category: category,
        onSave: (updated) {
          setState(() {
            _data[category]![index] = updated;
            // Propagate name change to all other fish in the same category
            if (oldName.isNotEmpty && oldName != updated.name) {
              final categoryFish = _data[category]!;
              // Update self-reference in the renamed fish's own lists.
              final self = categoryFish[index];
              categoryFish[index] = self.copyWith(
                compatible: self.compatible
                    .map((n) => n == oldName ? self.name : n)
                    .toList(),
                notRecommended: self.notRecommended
                    .map((n) => n == oldName ? self.name : n)
                    .toList(),
                notCompatible: self.notCompatible
                    .map((n) => n == oldName ? self.name : n)
                    .toList(),
                withCaution: self.withCaution
                    .map((n) => n == oldName ? self.name : n)
                    .toList(),
              );
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
                  uuid: f.uuid,
                  name: f.name,
                  imageURL: f.imageURL,
                  originHabitat: f.originHabitat,
                  careFacts: f.careFacts,
                  generalInfo: f.generalInfo,
                  compatibilityHighlights: f.compatibilityHighlights,
                  funFact: f.funFact,
                  commonNames: f.commonNames,
                  reefSafe: f.reefSafe,
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
                // Mirror name change in _savedData so propagated fish
                // don't appear dirty — only the directly-renamed fish should.
                final saved = _savedData[category];
                if (saved != null && i < saved.length) {
                  final sf = saved[i];
                  saved[i] = _FishEntry(
                    uuid: sf.uuid,
                    name: sf.name,
                    imageURL: sf.imageURL,
                    originHabitat: sf.originHabitat,
                    careFacts: sf.careFacts,
                    generalInfo: sf.generalInfo,
                    compatibilityHighlights: sf.compatibilityHighlights,
                    funFact: sf.funFact,
                    commonNames: sf.commonNames,
                    reefSafe: sf.reefSafe,
                    compatible: inCompatible
                        ? sf.compatible
                              .map((n) => n == oldName ? updated.name : n)
                              .toList()
                        : sf.compatible,
                    notRecommended: inNotRecommended
                        ? sf.notRecommended
                              .map((n) => n == oldName ? updated.name : n)
                              .toList()
                        : sf.notRecommended,
                    notCompatible: inNotCompatible
                        ? sf.notCompatible
                              .map((n) => n == oldName ? updated.name : n)
                              .toList()
                        : sf.notCompatible,
                    withCaution: inWithCaution
                        ? sf.withCaution
                              .map((n) => n == oldName ? updated.name : n)
                              .toList()
                        : sf.withCaution,
                  );
                }
              }
            }
            _validationRun = false; // reset validation badge
          });
        },
      ),
    );
  }

  // ── add fish helper ──────────────────────────────────────────────────────

  Future<void> _addFish() async {
    // Pick the category to add the fish to
    final category = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Add Fish To'),
        children: _data.keys
            .map(
              (cat) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, cat),
                child: Text(
                  _capitalize(cat),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (category == null || !mounted) return;

    // Open the edit dialog with a blank entry
    final blank = _FishEntry(
      name: '',
      imageURL: '',
      commonNames: [],
      reefSafe: category == 'marine' ? 'Yes' : null,
      compatible: [],
      notRecommended: [],
      notCompatible: [],
      withCaution: [],
    );

    await showDialog<void>(
      context: context,
      builder: (_) => _FishEditDialog(
        fish: blank,
        category: category,
        dialogTitle: 'Add Fish to ${_capitalize(category)}',
        onSave: (newFish) {
          setState(() {
            final categoryFish = _data[category]!;
            // All existing fish names default to notCompatible with the new fish
            final existingNames = categoryFish.map((f) => f.name).toList();
            final newEntry = _FishEntry(
              uuid: newFish.uuid,
              name: newFish.name,
              imageURL: newFish.imageURL,
              originHabitat: newFish.originHabitat,
              careFacts: newFish.careFacts,
              generalInfo: newFish.generalInfo,
              compatibilityHighlights: newFish.compatibilityHighlights,
              funFact: newFish.funFact,
              commonNames: newFish.commonNames,
              reefSafe: newFish.reefSafe,
              compatible: [newFish.name], // self-reference: compatible with itself
              notRecommended: [],
              notCompatible: List<String>.from(existingNames),
              withCaution: [],
            );
            categoryFish.add(newEntry);
            // Add the new fish to every existing fish's notCompatible list
            for (int i = 0; i < categoryFish.length - 1; i++) {
              final f = categoryFish[i];
              categoryFish[i] = _FishEntry(
                uuid: f.uuid,
                name: f.name,
                imageURL: f.imageURL,
                originHabitat: f.originHabitat,
                careFacts: f.careFacts,
                generalInfo: f.generalInfo,
                compatibilityHighlights: f.compatibilityHighlights,
                funFact: f.funFact,
                commonNames: f.commonNames,
                reefSafe: f.reefSafe,
                compatible: f.compatible,
                notRecommended: f.notRecommended,
                notCompatible: [...f.notCompatible, newEntry.name],
                withCaution: f.withCaution,
              );
            }
            _validationRun = false;
          });
        },
      ),
    );
  }

  // ── compatibility edit helpers ────────────────────────────────────────────

  /// Removes a fish entry from [category] at [index], also propagating the
  /// removal from all compatibility lists and deleting any associated Firebase
  /// Storage image.
  Future<void> _deleteFish(String category, int index) async {
    final fish = _data[category]![index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Fish'),
        content: Text(
          'Remove "${fish.name}" from $category? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Delete the Storage image (fire-and-forget; don't block the UI).
    if (_isFirebaseStorageUrl(fish.imageURL)) {
      _deleteStorageImageByUrl(fish.imageURL);
    }

    setState(() {
      final categoryFish = _data[category]!;
      categoryFish.removeAt(index);
      // Remove this fish from every other fish's compatibility lists.
      for (int i = 0; i < categoryFish.length; i++) {
        final f = categoryFish[i];
        final inCompatible = f.compatible.contains(fish.name);
        final inNotRecommended = f.notRecommended.contains(fish.name);
        final inNotCompatible = f.notCompatible.contains(fish.name);
        final inWithCaution = f.withCaution.contains(fish.name);
        if (!inCompatible &&
            !inNotRecommended &&
            !inNotCompatible &&
            !inWithCaution) {
          continue;
        }
        categoryFish[i] = _FishEntry(
          uuid: f.uuid,
          name: f.name,
          imageURL: f.imageURL,
          originHabitat: f.originHabitat,
          careFacts: f.careFacts,
          generalInfo: f.generalInfo,
          compatibilityHighlights: f.compatibilityHighlights,
          funFact: f.funFact,
          commonNames: f.commonNames,
          reefSafe: f.reefSafe,
          compatible: inCompatible
              ? f.compatible.where((n) => n != fish.name).toList()
              : f.compatible,
          notRecommended: inNotRecommended
              ? f.notRecommended.where((n) => n != fish.name).toList()
              : f.notRecommended,
          notCompatible: inNotCompatible
              ? f.notCompatible.where((n) => n != fish.name).toList()
              : f.notCompatible,
          withCaution: inWithCaution
              ? f.withCaution.where((n) => n != fish.name).toList()
              : f.withCaution,
        );
      }
      _validationRun = false;
    });
  }

  Future<void> _editCompatibility(String category, int index) async {
    final fish = _data[category]![index];
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FishCompatibilityDialog(
        fish: fish,
        onSave: (updatedLists) {
          setState(() {
            final categoryFish = _data[category]!;
            // Update the directly-edited fish
            categoryFish[index] = _FishEntry(
              uuid: fish.uuid,
              name: fish.name,
              imageURL: fish.imageURL,
              originHabitat: fish.originHabitat,
              careFacts: fish.careFacts,
              generalInfo: fish.generalInfo,
              compatibilityHighlights: fish.compatibilityHighlights,
              funFact: fish.funFact,
              commonNames: fish.commonNames,
              reefSafe: fish.reefSafe,
              compatible: updatedLists['compatible']!,
              notRecommended: updatedLists['notRecommended']!,
              notCompatible: updatedLists['notCompatible']!,
              withCaution: updatedLists['withCaution']!,
            );
            // Bidirectional propagation: for each fish that moved to a new
            // category in the edited fish's lists, update that fish's entry
            // for fish.name symmetrically.
            for (final catKey in _compatCategoryKeys) {
              final newList = updatedLists[catKey]!;
              final oldList = _compatListOf(catKey, fish);
              // For each fish newly placed in this category (moved from
              // another), propagate the change bidirectionally.
              // _propagateCompatChange uses a "remove-from-all / add-to-one"
              // pattern so any previous entry in the complementary fish is
              // cleaned up automatically.
              for (final addedFishName in newList.where(
                (n) => !oldList.contains(n),
              )) {
                _propagateCompatChange(
                  categoryFish,
                  addedFishName,
                  fish.name,
                  catKey,
                );
              }
            }
            _validationRun = false;
          });
        },
      ),
    );
  }

  /// Returns the compatibility sub-list for [key] from [fish].
  List<String> _compatListOf(String key, _FishEntry fish) {
    switch (key) {
      case 'compatible':
        return fish.compatible;
      case 'notRecommended':
        return fish.notRecommended;
      case 'notCompatible':
        return fish.notCompatible;
      case 'withCaution':
        return fish.withCaution;
      default:
        return const [];
    }
  }

  /// Updates [targetName]'s entry for [editedName] in [categoryFish] so that
  /// [editedName] appears in [newKey] (and nowhere else).
  void _propagateCompatChange(
    List<_FishEntry> categoryFish,
    String targetName,
    String editedName,
    String newKey,
  ) {
    final targetIndex = categoryFish.indexWhere((f) => f.name == targetName);
    if (targetIndex == -1) return;
    final f = categoryFish[targetIndex];
    categoryFish[targetIndex] = _FishEntry(
      uuid: f.uuid,
      name: f.name,
      imageURL: f.imageURL,
      originHabitat: f.originHabitat,
      careFacts: f.careFacts,
      generalInfo: f.generalInfo,
      compatibilityHighlights: f.compatibilityHighlights,
      funFact: f.funFact,
      commonNames: f.commonNames,
      reefSafe: f.reefSafe,
      compatible: newKey == 'compatible'
          ? [...f.compatible.where((n) => n != editedName), editedName]
          : f.compatible.where((n) => n != editedName).toList(),
      notRecommended: newKey == 'notRecommended'
          ? [...f.notRecommended.where((n) => n != editedName), editedName]
          : f.notRecommended.where((n) => n != editedName).toList(),
      notCompatible: newKey == 'notCompatible'
          ? [...f.notCompatible.where((n) => n != editedName), editedName]
          : f.notCompatible.where((n) => n != editedName).toList(),
      withCaution: newKey == 'withCaution'
          ? [...f.withCaution.where((n) => n != editedName), editedName]
          : f.withCaution.where((n) => n != editedName).toList(),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dirtyInfo = _computeDirtyInfo();
    final changedCount = dirtyInfo.count;
    final dirty = changedCount > 0;

    Widget body;
    if (_isLoading || _isRefreshing) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              _isRefreshing ? 'Refreshing from Firestore…' : 'Loading…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    } else if (_loadError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading fish data:\n$_loadError',
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _loadData(fromFirestore: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = _buildEditor(colorScheme, changedCount, dirtyInfo.modifiedIndices);
    }

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await _confirmDiscard();
        if (canLeave && mounted) Navigator.of(context).pop();
      },
      child: MainLayout(
        title: 'Fish Compat Editor',
        floatingActionButton: _isLoading || _isRefreshing || _loadError != null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'addFish',
                    onPressed: _addFish,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Fish'),
                  ),
                  const SizedBox(height: 8),
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
                  if (dirty) ...[
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      heroTag: 'save',
                      onPressed: _isSavingToFirestore ? null : _saveChanges,
                      icon: _isSavingToFirestore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSavingToFirestore
                            ? 'Saving…'
                            : 'Save ($changedCount)'
                                '${_isAuthorizedEditor ? "" : " (local)"}',
                      ),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      heroTag: 'undo',
                      onPressed: _undoChanges,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'refresh',
                    onPressed: _isRefreshing ? null : _refreshFromFirestore,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(height: 8),
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
                    label: const Text('Download JSON'),
                  ),
                ],
              ),
        child: body,
      ),
    );
  }

  Widget _buildEditor(
    ColorScheme colorScheme,
    int changedCount,
    Map<String, Set<int>> modifiedIndices,
  ) {
    return DefaultTabController(
      length: _data.length,
      child: Column(
        children: [
          // Debug banner
          Container(
            width: double.infinity,
            color: Colors.amber.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'DEBUG TOOL – not visible in release builds',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                // Auth / editor role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isAuthorizedEditor
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAuthorizedEditor ? Icons.edit : Icons.visibility,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAuthorizedEditor ? 'Editor' : 'Read-only',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (changedCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$changedCount unsaved',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (_validationRun) ...[
                  const SizedBox(width: 6),
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
              ],
            ),
          ),
          // Search bar + column picker
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search fish…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment<int>(value: 1, label: Text('1')),
                    ButtonSegment<int>(value: 2, label: Text('2')),
                    ButtonSegment<int>(value: 3, label: Text('3')),
                    ButtonSegment<int>(value: 4, label: Text('4')),
                  ],
                  selected: {_columnCount},
                  onSelectionChanged: (s) =>
                      setState(() => _columnCount = s.first),
                ),
              ],
            ),
          ),
          TabBar(
            tabs: _data.keys.map((cat) {
              final filtered = _filteredFish(cat);
              final total = _data[cat]!.length;
              final label = _capitalize(cat);
              return Tab(
                text: _searchQuery.isEmpty
                    ? '$label ($total)'
                    : '$label (${filtered.length}/$total)',
              );
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: _data.keys
                  .map(
                    (cat) =>
                        _buildCategoryTab(cat, colorScheme, modifiedIndices),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns (originalIndex, fish) pairs filtered by the current search query.
  List<MapEntry<int, _FishEntry>> _filteredFish(String category) {
    final entries = _data[category]!.asMap().entries;
    if (_searchQuery.isEmpty) return entries.toList();
    return entries
        .where(
          (e) =>
              e.value.name.toLowerCase().contains(_searchQuery) ||
              e.value.commonNames.any(
                (n) => n.toLowerCase().contains(_searchQuery),
              ),
        )
        .toList();
  }

  Widget _buildCategoryTab(
    String category,
    ColorScheme colorScheme,
    Map<String, Set<int>> modifiedIndices,
  ) {
    final filtered = _filteredFish(category);
    if (filtered.isEmpty) {
      return const Center(child: Text('No fish match your search.'));
    }
    final categoryModified = modifiedIndices[category] ?? const {};
    final rowCount = (filtered.length / _columnCount).ceil();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
      itemCount: rowCount,
      itemBuilder: (_, rowIdx) {
        final startIdx = rowIdx * _columnCount;
        final endIdx = min(startIdx + _columnCount, filtered.length);
        final itemsInRow = endIdx - startIdx;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int col = 0; col < _columnCount; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: col < itemsInRow
                        ? _buildFishCard(
                            category,
                            filtered[startIdx + col].key,
                            filtered[startIdx + col].value,
                            colorScheme,
                            categoryModified,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFishCard(
    String category,
    int dataIdx,
    _FishEntry f,
    ColorScheme colorScheme,
    Set<int> categoryModified,
  ) {
    // Determine if this fish has validation errors
    final hasError =
        _validationRun &&
        _validationErrors.any((e) => e.startsWith('[$category] "${f.name}"'));
    final isModified = categoryModified.contains(dataIdx);
    final placeholder = SizedBox(
      width: 56,
      height: 56,
      child: Container(
        color: colorScheme.surfaceVariant,
        child: const Icon(Icons.image_not_supported),
      ),
    );

    Widget leadingImage;
    if (_isFirebaseStorageUrl(f.imageURL)) {
      leadingImage = _FishCardImage(imageURL: f.imageURL);
    } else {
      leadingImage = Image.asset(
        f.localImagePath,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

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
          child: leadingImage,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                f.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isModified)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.edit, color: Colors.orange, size: 14),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              f.commonNames.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            if (f.reefSafe != null)
              Text(
                'Reef Safe: ${f.reefSafe}',
                style: TextStyle(
                  fontSize: 11,
                  color: f.reefSafe == 'Yes'
                      ? Colors.green.shade700
                      : f.reefSafe == 'Caution'
                      ? Colors.orange.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError)
              Icon(Icons.warning_amber, color: colorScheme.error, size: 18),
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Edit Compatibility',
              onPressed: () => _editCompatibility(category, dataIdx),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => _editFish(category, dataIdx),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Delete',
              onPressed: () => _deleteFish(category, dataIdx),
            ),
          ],
        ),
      ),
    );
  }
}

// ── storage image widget for editor card list ─────────────────────────────────

/// A 56×56 image tile for the editor card list.
///
/// For Firebase Storage URLs the resized variant (from the Resize Images
/// extension) is resolved asynchronously so the image shows correctly even
/// when the extension has deleted the original file after resizing.
class _FishCardImage extends StatefulWidget {
  final String imageURL;

  const _FishCardImage({required this.imageURL});

  @override
  State<_FishCardImage> createState() => _FishCardImageState();
}

class _FishCardImageState extends State<_FishCardImage> {
  Future<String>? _resolvedUrlFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(_FishCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageURL != oldWidget.imageURL) {
      setState(_initFuture);
    }
  }

  void _initFuture() {
    _resolvedUrlFuture = resolveResizedStorageUrl(widget.imageURL);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 56,
      height: 56,
      color: cs.surfaceVariant,
      child: const Icon(Icons.image_not_supported),
    );

    return FutureBuilder<String>(
      future: _resolvedUrlFuture,
      initialData: getCachedResizedUrl(widget.imageURL) ?? widget.imageURL,
      builder: (context, snapshot) {
        final url = snapshot.data ?? widget.imageURL;
        return CachedNetworkImage(
          imageUrl: url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder,
        );
      },
    );
  }
}

// ── edit dialog ───────────────────────────────────────────────────────────────

const _kReefSafeOptions = ['Yes', 'No', 'Caution'];

class _FishEditDialog extends StatefulWidget {
  final _FishEntry fish;
  final void Function(_FishEntry) onSave;
  final String? dialogTitle;
  final String? category;

  const _FishEditDialog({
    required this.fish,
    required this.onSave,
    this.dialogTitle,
    this.category,
  });

  @override
  State<_FishEditDialog> createState() => _FishEditDialogState();
}

class _FishEditDialogState extends State<_FishEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _originHabitatCtrl;
  late TextEditingController _generalInfoCtrl;
  late TextEditingController _funFactCtrl;
  late List<TextEditingController> _commonNameCtrls;
  late List<TextEditingController> _careFactCtrls;
  late List<TextEditingController> _compatHighlightCtrls;
  final TextEditingController _newCommonNameCtrl = TextEditingController();
  final TextEditingController _newCareFactCtrl = TextEditingController();
  final TextEditingController _newCompatHighlightCtrl = TextEditingController();
  late String? _reefSafe;

  // Pending image upload (set when user picks a new file).
  Uint8List? _pendingImageBytes;
  String? _pendingImageFileName;
  bool _isUploading = false;

  // Resolved URL for the existing Storage image shown in the preview.
  Future<String>? _resolvedImageUrlFuture;

  @override
  void initState() {
    super.initState();
    _initResolvedImageUrl();
    _nameCtrl = TextEditingController(text: widget.fish.name);
    _originHabitatCtrl =
        TextEditingController(text: widget.fish.originHabitat ?? '');
    _generalInfoCtrl =
        TextEditingController(text: widget.fish.generalInfo ?? '');
    _funFactCtrl = TextEditingController(text: widget.fish.funFact ?? '');
    _commonNameCtrls = widget.fish.commonNames
        .map((n) => TextEditingController(text: n))
        .toList();
    _careFactCtrls = widget.fish.careFacts
        .map((f) => TextEditingController(text: f))
        .toList();
    _compatHighlightCtrls = widget.fish.compatibilityHighlights
        .map((h) => TextEditingController(text: h))
        .toList();
    _reefSafe = widget.fish.reefSafe;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _originHabitatCtrl.dispose();
    _generalInfoCtrl.dispose();
    _funFactCtrl.dispose();
    _newCommonNameCtrl.dispose();
    _newCareFactCtrl.dispose();
    _newCompatHighlightCtrl.dispose();
    for (final ctrl in _commonNameCtrls) {
      ctrl.dispose();
    }
    for (final ctrl in _careFactCtrls) {
      ctrl.dispose();
    }
    for (final ctrl in _compatHighlightCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _initResolvedImageUrl() {
    if (_isFirebaseStorageUrl(widget.fish.imageURL)) {
      _resolvedImageUrlFuture = resolveResizedStorageUrl(widget.fish.imageURL);
    } else {
      _resolvedImageUrlFuture = null;
    }
  }

  @override
  void didUpdateWidget(_FishEditDialog old) {
    super.didUpdateWidget(old);
    if (widget.fish.imageURL != old.fish.imageURL) {
      _initResolvedImageUrl();
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // ensures bytes are available on web too
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    setState(() {
      _pendingImageBytes = file.bytes;
      _pendingImageFileName = file.name;
    });
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

  void _addCareFact() {
    final value = _newCareFactCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _careFactCtrls.add(TextEditingController(text: value));
      _newCareFactCtrl.clear();
    });
  }

  void _addCompatHighlight() {
    final value = _newCompatHighlightCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _compatHighlightCtrls.add(TextEditingController(text: value));
      _newCompatHighlightCtrl.clear();
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final commonNames = _commonNameCtrls
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    // Inline validation — catch the most critical field errors before saving
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }
    // An image must exist: either the original URL or a newly-picked file.
    final hasExistingImage = widget.fish.imageURL.isNotEmpty;
    if (!hasExistingImage && _pendingImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An image file is required.')),
      );
      return;
    }
    if (commonNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one common name is required.')),
      );
      return;
    }

    String imageURL = widget.fish.imageURL;

    // Upload the newly-picked file to Firebase Storage.
    if (_pendingImageBytes != null) {
      setState(() => _isUploading = true);
      final uploadedUrl = await _uploadFishImage(
        _pendingImageBytes!,
        _pendingImageFileName ?? 'fish_image.jpg',
      );
      if (!mounted) return;
      setState(() => _isUploading = false);

      if (uploadedUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Delete the old Storage image (if any) now that upload succeeded.
      if (_isFirebaseStorageUrl(widget.fish.imageURL)) {
        _deleteStorageImageByUrl(widget.fish.imageURL);
      }

      imageURL = uploadedUrl;
    }

    String? _trimOrNull(String s) => s.trim().isEmpty ? null : s.trim();

    final updated = _FishEntry(
      uuid: widget.fish.uuid,
      name: name,
      imageURL: imageURL,
      originHabitat: _trimOrNull(_originHabitatCtrl.text),
      careFacts: _careFactCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      generalInfo: _trimOrNull(_generalInfoCtrl.text),
      compatibilityHighlights: _compatHighlightCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      funFact: _trimOrNull(_funFactCtrl.text),
      commonNames: commonNames,
      reefSafe: _reefSafe,
      compatible: widget.fish.compatible,
      notRecommended: widget.fish.notRecommended,
      notCompatible: widget.fish.notCompatible,
      withCaution: widget.fish.withCaution,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  Widget _buildListEditor({
    required String sectionLabel,
    required List<TextEditingController> controllers,
    required TextEditingController newItemCtrl,
    required VoidCallback onAdd,
    required String addLabel,
    required String addHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        ...controllers.asMap().entries.map(
          (e) => Padding(
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
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  tooltip: 'Remove',
                  onPressed: () {
                    final ctrl = e.value;
                    setState(() => controllers.removeAt(e.key));
                    ctrl.dispose();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: newItemCtrl,
                decoration: InputDecoration(
                  labelText: addLabel,
                  hintText: addHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add',
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMarine = widget.category == 'marine';
    final cs = Theme.of(context).colorScheme;
    final hasExistingImage = widget.fish.imageURL.isNotEmpty;

    // Determine what to show in the image preview area.
    Widget imagePreview;
    if (_pendingImageBytes != null) {
      imagePreview = Image.memory(
        _pendingImageBytes!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    } else if (_isFirebaseStorageUrl(widget.fish.imageURL)) {
      imagePreview = FutureBuilder<String>(
        future: _resolvedImageUrlFuture,
        initialData:
            getCachedResizedUrl(widget.fish.imageURL) ?? widget.fish.imageURL,
        builder: (_, snap) => CachedNetworkImage(
          imageUrl: snap.data!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 80,
            height: 80,
            color: cs.surfaceVariant,
            child: const Icon(Icons.image),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 80,
            height: 80,
            color: cs.surfaceVariant,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    } else if (hasExistingImage) {
      imagePreview = Image.network(
        widget.fish.imageURL,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 80,
          height: 80,
          color: cs.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    } else {
      imagePreview = Container(
        width: 80,
        height: 80,
        color: cs.surfaceVariant,
        child: Icon(Icons.add_photo_alternate_outlined, color: cs.outline),
      );
    }

    return AlertDialog(
      title: Text(widget.dialogTitle ?? 'Edit: ${widget.fish.name}'),
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
              // Image upload
              Text('Image *', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imagePreview,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickImage,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(
                            hasExistingImage || _pendingImageBytes != null
                                ? 'Replace Image'
                                : 'Pick Image',
                          ),
                        ),
                        if (_pendingImageBytes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _pendingImageFileName ?? 'Selected file',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else if (hasExistingImage) ...[
                          const SizedBox(height: 4),
                          Text(
                            _isFirebaseStorageUrl(widget.fish.imageURL)
                                ? '(Storage image)'
                                : widget.fish.imageURL,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                        if (_isUploading) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Uploading…', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Origin & Habitat
              TextField(
                controller: _originHabitatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Origin & Habitat',
                  border: OutlineInputBorder(),
                  hintText:
                      'Where does this fish come from and what is its natural habitat?',
                ),
                maxLines: 3,
                minLines: 2,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              // Care Facts (list editor)
              _buildListEditor(
                sectionLabel: 'Care Facts',
                controllers: _careFactCtrls,
                newItemCtrl: _newCareFactCtrl,
                onAdd: _addCareFact,
                addLabel: 'Add care fact',
                addHint: 'e.g. Requires soft, acidic water',
              ),
              const SizedBox(height: 12),
              // General Aquarium Information
              TextField(
                controller: _generalInfoCtrl,
                decoration: const InputDecoration(
                  labelText: 'General Aquarium Information',
                  border: OutlineInputBorder(),
                  hintText: 'General information about keeping this fish…',
                ),
                maxLines: 3,
                minLines: 2,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              // Compatibility Highlights (list editor)
              _buildListEditor(
                sectionLabel: 'Compatibility Highlights',
                controllers: _compatHighlightCtrls,
                newItemCtrl: _newCompatHighlightCtrl,
                onAdd: _addCompatHighlight,
                addLabel: 'Add highlight',
                addHint: 'e.g. Peaceful with most community fish',
              ),
              const SizedBox(height: 12),
              // Fun Fact
              TextField(
                controller: _funFactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fun Fact',
                  border: OutlineInputBorder(),
                  hintText: 'An interesting fact about this species…',
                ),
                maxLines: 2,
                minLines: 1,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              // Reef Safe (marine only)
              if (isMarine) ...[
                Text(
                  'Reef Safe',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _kReefSafeOptions.contains(_reefSafe)
                      ? _reefSafe
                      : 'Yes',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _kReefSafeOptions
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _reefSafe = v),
                ),
                const SizedBox(height: 12),
              ],
              // Common Names
              Text(
                'Common Names *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              if (_commonNameCtrls.isEmpty)
                Text(
                  'No common names – at least 1 required.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ..._commonNameCtrls.asMap().entries.map(
                (e) => Padding(
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
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        tooltip: 'Remove',
                        onPressed: () {
                          final ctrl = e.value;
                          setState(() => _commonNameCtrls.removeAt(e.key));
                          ctrl.dispose();
                        },
                      ),
                    ],
                  ),
                ),
              ),
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
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isUploading ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ── compatibility category definitions ───────────────────────────────────────

/// Ordered keys for all 4 compatibility sub-categories.
const _compatCategoryKeys = [
  'compatible',
  'withCaution',
  'notRecommended',
  'notCompatible',
];

class _CompatCatDef {
  final String key;
  final String label;
  final Color headerBg;
  final Color chipBorder;

  const _CompatCatDef({
    required this.key,
    required this.label,
    required this.headerBg,
    required this.chipBorder,
  });
}

const _kCompatCats = <_CompatCatDef>[
  _CompatCatDef(
    key: 'compatible',
    label: 'Compatible',
    headerBg: Color(0xFFE8F5E9),
    chipBorder: Color(0xFF4CAF50),
  ),
  _CompatCatDef(
    key: 'withCaution',
    label: 'With Caution',
    headerBg: Color(0xFFFFF3E0),
    chipBorder: Color(0xFFFF9800),
  ),
  _CompatCatDef(
    key: 'notRecommended',
    label: 'Not Recommended',
    headerBg: Color(0xFFFBE9E7),
    chipBorder: Color(0xFFFF5722),
  ),
  _CompatCatDef(
    key: 'notCompatible',
    label: 'Not Compatible',
    headerBg: Color(0xFFFFEBEE),
    chipBorder: Color(0xFFF44336),
  ),
];

// ── compatibility editor dialog ───────────────────────────────────────────────

class _FishCompatibilityDialog extends StatefulWidget {
  final _FishEntry fish;
  final void Function(Map<String, List<String>> updatedLists) onSave;

  const _FishCompatibilityDialog({required this.fish, required this.onSave});

  @override
  State<_FishCompatibilityDialog> createState() =>
      _FishCompatibilityDialogState();
}

class _FishCompatibilityDialogState extends State<_FishCompatibilityDialog> {
  late Map<String, List<String>> _lists;

  @override
  void initState() {
    super.initState();
    final f = widget.fish;
    _lists = {
      'compatible': List<String>.from(f.compatible),
      'withCaution': List<String>.from(f.withCaution),
      'notRecommended': List<String>.from(f.notRecommended),
      'notCompatible': List<String>.from(f.notCompatible),
    };
  }

  void _moveTo(String name, String toKey) {
    setState(() {
      for (final list in _lists.values) {
        list.remove(name);
      }
      _lists[toKey]!.add(name);
    });
  }

  int get _totalFish => _lists.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Compatibility Editor',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.fish.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_totalFish fish',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: () {
                      widget.onSave(_lists);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Drag chips between columns, or use the menu button (⋮) on each chip.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── 4 columns ───────────────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _kCompatCats.asMap().entries.map((entry) {
                  final isLast = entry.key == _kCompatCats.length - 1;
                  return Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: isLast
                              ? BorderSide.none
                              : BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                        ),
                      ),
                      child: _buildColumn(entry.value),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(_CompatCatDef cat) {
    final items = _lists[cat.key]!;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => !items.contains(d.data),
      onAcceptWithDetails: (d) => _moveTo(d.data, cat.key),
      builder: (context, candidateData, _) {
        final hovered = candidateData.isNotEmpty;
        return ColoredBox(
          color: hovered ? cat.headerBg : Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column header
              ColoredBox(
                color: cat.headerBg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Text(
                        cat.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: cat.chipBorder,
                        ),
                      ),
                      Text(
                        '${items.length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              // Fish chips
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(6),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildChip(items[i], cat),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String name, _CompatCatDef cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Draggable<String>(
        data: name,
        feedback: Material(
          borderRadius: BorderRadius.circular(6),
          elevation: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cat.chipBorder,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _chipContent(name, cat),
        ),
        child: _chipContent(name, cat),
      ),
    );
  }

  Widget _chipContent(String name, _CompatCatDef cat) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: cat.chipBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2, right: 2),
        child: Row(
          children: [
            Icon(Icons.drag_indicator, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<String>(
              iconSize: 16,
              splashRadius: 14,
              padding: EdgeInsets.zero,
              tooltip: 'Move to…',
              itemBuilder: (_) => _kCompatCats
                  .where((c) => c.key != cat.key)
                  .map(
                    (c) => PopupMenuItem<String>(
                      value: c.key,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: c.chipBorder,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c.label, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onSelected: (key) => _moveTo(name, key),
            ),
          ],
        ),
      ),
    );
  }
}
