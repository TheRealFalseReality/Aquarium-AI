import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/fish.dart';
import '../models/tank.dart';
import '../providers/species_tags_provider.dart';
import '../providers/tank_provider.dart';
import '../providers/tank_tags_provider.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import '../utils/tank_harmony_calculator.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/modern_chip.dart';
import '../widgets/tag_picker_dialog.dart';

class TankCreationScreen extends ConsumerStatefulWidget {
  final Tank? existingTank; // For editing existing tanks

  const TankCreationScreen({super.key, this.existingTank});

  @override
  TankCreationScreenState createState() => TankCreationScreenState();
}

class TankCreationScreenState extends ConsumerState<TankCreationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tankNameController = TextEditingController();
  final _sizeGallonsController = TextEditingController();
  final _sizeLitersController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'freshwater';
  bool _isReef = false;
  String? _freshwaterSubtype; // 'planted' or 'brackish'; null = standard
  List<TankInhabitant> _inhabitants = [];
  List<Fish> _availableFish = [];
  DateTime _creationDate = DateTime.now();
  List<TankPhoto> _tankPhotos = [];
  List<TankTag> _tankTags = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'tank_creation_screen');

    _tabController = TabController(length: 3, vsync: this);

    // Add listener to rebuild when tab changes
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (widget.existingTank != null) {
      _tankNameController.text = widget.existingTank!.name;
      _selectedCategory = widget.existingTank!.type;
      _isReef = widget.existingTank!.isReef;
      _freshwaterSubtype = widget.existingTank!.freshwaterSubtype;
      _inhabitants = List.from(widget.existingTank!.inhabitants);
      _creationDate = widget.existingTank!.createdAt;
      _tankPhotos = List.from(widget.existingTank!.photos);
      _tankTags = List.from(widget.existingTank!.tags);
      if (widget.existingTank!.sizeGallons != null) {
        _sizeGallonsController.text = widget.existingTank!.sizeGallons!
            .toString();
      }
      if (widget.existingTank!.sizeLiters != null) {
        _sizeLitersController.text = widget.existingTank!.sizeLiters!
            .toString();
      }
      if (widget.existingTank!.notes != null) {
        _notesController.text = widget.existingTank!.notes!;
      }
    }

    // Load fish data after initialization
    _loadFishData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tankNameController.dispose();
    _sizeGallonsController.dispose();
    _sizeLitersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openTagPicker(BuildContext context) async {
    final allExistingTags = mergeTagSuggestions(
      globalTags: ref.read(tankTagsProvider),
      tanks: ref.read(tankProvider).tanks,
    );

    if (!mounted) return;
    final result = await showDialog<List<TankTag>>(
      context: context,
      builder: (_) => TagPickerDialog(
        allExistingTags: allExistingTags,
        currentTags: List.from(_tankTags),
      ),
    );
    if (result != null && mounted) {
      setState(() => _tankTags = result);
    }
  }

  Future<void> _loadFishData() async {
    try {
      final fishDataService = ref.read(fishDataServiceProvider);
      final fishData = await fishDataService.loadFishData();
      final fishList = fishData[_selectedCategory] ?? [];

      if (mounted) {
        setState(() {
          _availableFish = fishList;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showAccessibleMessage('Failed to load fish data: $e');
      }
    }
  }

  void _onCategoryChanged(String category) {
    final l10n = AppLocalizations.of(context)!;
    // If no inhabitants or same category, just proceed
    if (_inhabitants.isEmpty || _selectedCategory == category) {
      _performCategoryChange(category);
      return;
    }

    // Show confirmation dialog if there are inhabitants
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeTankType),
        content: Text(
          'Changing the tank type from ${_selectedCategory == 'freshwater' ? 'Freshwater' : 'Saltwater'} '
          'to ${category == 'freshwater' ? 'Freshwater' : 'Saltwater'} will remove all current inhabitants.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performCategoryChange(category);
            },
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
  }

  void _performCategoryChange(String category) {
    setState(() {
      _selectedCategory = category;
      _inhabitants.clear(); // Clear inhabitants when changing category
      if (category != 'marine') _isReef = false;
      if (category != 'freshwater') _freshwaterSubtype = null;
    });
    _loadFishData();
  }

  void _toggleFreshwaterSubtype(String subtype) {
    setState(() {
      _freshwaterSubtype = _freshwaterSubtype == subtype ? null : subtype;
    });
  }

  void _addInhabitant() {
    showDialog(
      context: context,
      builder: (context) => InhabitantDialog(
        availableFish: _availableFish,
        onAdd: (inhabitant) {
          setState(() {
            _inhabitants.add(inhabitant);
          });
        },
      ),
    );
  }

  void _editInhabitant(int index) {
    showDialog(
      context: context,
      builder: (context) => InhabitantDialog(
        availableFish: _availableFish,
        existingInhabitant: _inhabitants[index],
        onAdd: (inhabitant) {
          setState(() {
            _inhabitants[index] = inhabitant;
          });
        },
      ),
    );
  }

  void _removeInhabitant(int index) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(
          '${l10n.delete} "${_inhabitants[index].customName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _inhabitants.removeAt(index);
        });
      }
    });
  }

  void _duplicateInhabitant(int index) {
    final originalInhabitant = _inhabitants[index];
    final duplicatedInhabitant = TankInhabitant(
      id: const Uuid().v4(),
      customName: '${originalInhabitant.customName} (Copy)',
      fishUnit: originalInhabitant.fishUnit,
      fishUuid: originalInhabitant.fishUuid,
      quantity: originalInhabitant.quantity,
      customImageUrl: originalInhabitant.customImageUrl,
      customImagePath: originalInhabitant.customImagePath,
      dateAdded: DateTime.now(), // Use current date for duplicated inhabitant
    );

    setState(() {
      _inhabitants.insert(index + 1, duplicatedInhabitant);
    });

    context.showAccessibleMessage(
      'Duplicated "${originalInhabitant.customName}"',
    );
  }

  void _addTankPhoto() {
    showDialog(
      context: context,
      builder: (context) => _TankPhotoDialog(
        onAdd: (photo) {
          setState(() {
            _tankPhotos.add(photo);
          });
        },
      ),
    );
  }

  void _editTankPhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => _TankPhotoDialog(
        existingPhoto: _tankPhotos[index],
        onAdd: (photo) {
          setState(() {
            _tankPhotos[index] = photo;
          });
        },
      ),
    );
  }

  void _removeTankPhoto(int index) {
    setState(() {
      _tankPhotos.removeAt(index);
    });
  }

  Widget _buildTankPhotoThumbnail(TankPhoto photo, int index) {
    final imageUrl = photo.imageUrl ?? photo.imagePath;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null
                ? (imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Icon(
                              Icons.error_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        )
                      : Image.file(
                          File(imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ))
                : Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          // Date taken badge
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                '${photo.dateTaken.month}/${photo.dateTaken.day}/${photo.dateTaken.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Action buttons
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => _editTankPhoto(index),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => _removeTankPhoto(index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTank() async {
    if (_formKey.currentState!.validate()) {
      try {
        final sizeGallons = _sizeGallonsController.text.trim().isNotEmpty
            ? double.tryParse(_sizeGallonsController.text.trim())
            : null;
        final sizeLiters = _sizeLitersController.text.trim().isNotEmpty
            ? double.tryParse(_sizeLitersController.text.trim())
            : null;

        // Build temporary tank for calculations
        final tempTank = Tank(
          id: 'temp',
          name: _tankNameController.text.trim(),
          type: _selectedCategory,
          inhabitants: _inhabitants,
          sizeGallons: sizeGallons,
          sizeLiters: sizeLiters,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: _creationDate,
          updatedAt: DateTime.now(),
        );

        // Calculate harmony score and breakdown for the tank (only once during save)
        final fishData = {_selectedCategory: _availableFish};
        final harmonyScore = TankHarmonyCalculator.calculateTankHarmonyScore(
          tempTank,
          fishData,
        );

        // Calculate breakdown string (only once during save)
        String? calculationBreakdown;
        if (_inhabitants.isNotEmpty && _availableFish.isNotEmpty) {
          final tankFish = <Fish>[];
          for (final inhabitant in _inhabitants) {
            // Prefer UUID-based lookup for renamed-fish resilience; fall back to name.
            final fish = (inhabitant.fishUuid != null
                    ? _availableFish.where((f) => f.uuid == inhabitant.fishUuid).firstOrNull
                    : null) ??
                _availableFish.firstWhere(
                  (f) => f.name == inhabitant.fishUnit,
                  orElse: () => Fish(
                    name: inhabitant.fishUnit,
                    commonNames: [],
                    imageURL: '',
                    compatible: [],
                    notRecommended: [],
                    notCompatible: [],
                    withCaution: [],
                  ),
                );
            for (int i = 0; i < inhabitant.quantity; i++) {
              tankFish.add(fish);
            }
          }
          calculationBreakdown =
              TankHarmonyCalculator.generateCalculationBreakdown(tankFish);
        }

        final isReef = _selectedCategory == 'marine' ? _isReef : false;
        final freshwaterSubtype =
            _selectedCategory == 'freshwater' ? _freshwaterSubtype : null;
        final tank = widget.existingTank != null
            ? widget.existingTank!.copyWith(
                name: _tankNameController.text.trim(),
                type: _selectedCategory,
                isReef: isReef,
                freshwaterSubtype: freshwaterSubtype,
                clearFreshwaterSubtype: freshwaterSubtype == null,
                inhabitants: _inhabitants,
                sizeGallons: sizeGallons,
                sizeLiters: sizeLiters,
                notes: _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
                // Preserve old score as previousHarmonyScore before updating
                previousHarmonyScore: widget.existingTank!.harmonyScore,
                harmonyScore: harmonyScore,
                calculationBreakdown: calculationBreakdown,
                createdAt: _creationDate,
                photos: _tankPhotos,
                tags: _tankTags,
              )
            : Tank.create(
                name: _tankNameController.text.trim(),
                type: _selectedCategory,
                isReef: isReef,
                freshwaterSubtype: freshwaterSubtype,
                inhabitants: _inhabitants,
                sizeGallons: sizeGallons,
                sizeLiters: sizeLiters,
                notes: _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
                harmonyScore: harmonyScore,
                calculationBreakdown: calculationBreakdown,
                createdAt: _creationDate,
                photos: _tankPhotos,
                tags: _tankTags,
              );

        if (widget.existingTank != null) {
          await ref.read(tankProvider.notifier).updateTank(tank);

          // Log tank update analytics
          AnalyticsService.logTankAction(
            action: 'update_tank',
            tankType: tank.type,
            tankSize: tank.sizeGallons?.toInt(),
          );
        } else {
          await ref.read(tankProvider.notifier).addTank(tank);

          // Log tank creation analytics
          AnalyticsService.logTankAction(
            action: 'create_tank',
            tankType: tank.type,
            tankSize: tank.sizeGallons?.toInt(),
          );
          AnalyticsService.logFeatureUsed(
            featureName: 'tank_creation',
            parameters: {
              'tank_type': tank.type,
              'inhabitant_count': tank.inhabitants.length,
              'has_notes': tank.notes?.isNotEmpty == true ? 'true' : 'false',
              'has_size': (tank.sizeGallons != null || tank.sizeLiters != null)
                  ? 'true'
                  : 'false',
            },
          );
        }

        if (mounted) {
          // Show success message before navigation
          final parentContext = context;
          final successMessage = widget.existingTank != null
              ? 'Tank updated successfully!'
              : 'Tank created successfully!';

          Navigator.of(context).pop();

          // Use a delayed message to ensure it shows after navigation
          Future.delayed(const Duration(milliseconds: 100), () {
            if (parentContext.mounted) {
              parentContext.showAccessibleMessage(successMessage);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          context.showAccessibleMessage('Failed to save tank: $e');
        }
      }
    }
  }

  void _cancelAndReturn() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tankState = ref.watch(tankProvider);

    return Scaffold(
      body: Column(
        children: [
          // Sticky Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered Title
                Column(
                  children: [
                    Text(
                      widget.existingTank != null
                          ? 'Edit Your Tank'
                          : 'Create Your Tank',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Design and save your custom aquarium with inhabitants.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                // X Button on the right
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelAndReturn,
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
          ),

          // TabBar
          TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            dividerColor: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.2),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                icon: Icon(
                  Icons.info_outline,
                  color: _tabController.index == 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                text: 'General',
              ),
              Tab(
                icon: Icon(
                  Icons.pets,
                  color: _tabController.index == 1
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                text: 'Inhabitants',
              ),
              Tab(
                icon: Icon(
                  Icons.photo_library,
                  color: _tabController.index == 2
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                text: 'Photos',
              ),
            ],
          ),

          // TabBarView Content
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(),
                  _buildInhabitantsTab(),
                  _buildPhotosTab(),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Buttons
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: tankState.isLoading ? null : _cancelAndReturn,
                    icon: const Icon(Icons.cancel),
                    label: Text(l10n.cancel),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Save Button
                Expanded(
                  flex: 2, // Give save button more space
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: tankState.isLoading ? null : _saveTank,
                      icon: tankState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        widget.existingTank != null
                            ? 'Update Tank'
                            : 'Save Tank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // General Tab: Tank name, size, notes, date, type
  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tank Name
          TextFormField(
            controller: _tankNameController,
            decoration: const InputDecoration(
              labelText: 'Tank Name',
              hintText: 'My Community Tank',
              border: OutlineInputBorder(),
            ),
            textAlign: TextAlign.center,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a tank name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Tank Type Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tank Type',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              ModernSelectableChip(
                label: 'Freshwater',
                emoji: '🐟',
                selected: _selectedCategory == 'freshwater',
                onTap: () => _onCategoryChanged('freshwater'),
              ),
              ModernSelectableChip(
                label: 'Saltwater',
                emoji: '🪼',
                selected: _selectedCategory == 'marine',
                onTap: () => _onCategoryChanged('marine'),
              ),
            ],
          ),
          // Reef toggle – only visible for saltwater tanks, shown as a subtype
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _selectedCategory == 'marine'
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 2,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.saltwaterSubtype,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                ModernSelectableChip(
                                  label: l10n.markAsReef,
                                  emoji: '🪸',
                                  selected: _isReef,
                                  onTap: () =>
                                      setState(() => _isReef = !_isReef),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Freshwater subtype – only visible for freshwater tanks
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _selectedCategory == 'freshwater'
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 2,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.freshwaterSubtype,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ModernSelectableChip(
                                      label: l10n.plantedTank,
                                      emoji: '🌿',
                                      selected:
                                          _freshwaterSubtype == 'planted',
                                      onTap: () =>
                                          _toggleFreshwaterSubtype('planted'),
                                    ),
                                    ModernSelectableChip(
                                      label: l10n.brackishTank,
                                      emoji: '🦀',
                                      selected:
                                          _freshwaterSubtype == 'brackish',
                                      onTap: () =>
                                          _toggleFreshwaterSubtype('brackish'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Tank Size Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.straighten,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tank Size (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sizeGallonsController,
                  decoration: const InputDecoration(
                    labelText: 'Gallons',
                    hintText: '55',
                    border: OutlineInputBorder(),
                    suffixText: 'gal',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    // Auto-convert gallons to liters
                    if (value.isNotEmpty) {
                      final gallons = double.tryParse(value);
                      if (gallons != null) {
                        final liters = gallons * 3.78541;
                        _sizeLitersController.text = liters.toStringAsFixed(1);
                      }
                    } else {
                      _sizeLitersController.clear();
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final size = double.tryParse(value);
                      if (size == null || size <= 0) {
                        return 'Please enter a valid size';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sizeLitersController,
                  decoration: const InputDecoration(
                    labelText: 'Liters',
                    hintText: '208',
                    border: OutlineInputBorder(),
                    suffixText: 'L',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    // Auto-convert liters to gallons
                    if (value.isNotEmpty) {
                      final liters = double.tryParse(value);
                      if (liters != null) {
                        final gallons = liters / 3.78541;
                        _sizeGallonsController.text = gallons.toStringAsFixed(
                          1,
                        );
                      }
                    } else {
                      _sizeGallonsController.clear();
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final size = double.tryParse(value);
                      if (size == null || size <= 0) {
                        return 'Please enter a valid size';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tank Notes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.note_outlined,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tank Notes (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Tank Notes',
              hintText:
                  'Special considerations, water parameters, equipment, etc.',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 24),

          // Tank Tags Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.label_outline,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tags (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tankTags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tankTags.map((tag) {
                final tagColor = tag.color != null
                    ? Color(tag.color!)
                    : Theme.of(context).colorScheme.secondary;
                final onTagColor = tagColor.computeLuminance() > 0.4
                    ? Colors.black87
                    : Colors.white;
                return Chip(
                  label: Text(
                    tag.name,
                    style: TextStyle(fontSize: 12, color: onTagColor),
                  ),
                  backgroundColor: tagColor.withOpacity(0.85),
                  side: BorderSide(color: tagColor, width: 1),
                  deleteIconColor: onTagColor.withOpacity(0.7),
                  onDeleted: () {
                    setState(() {
                      _tankTags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _openTagPicker(context),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              _tankTags.isEmpty
                  ? AppLocalizations.of(context)!.addTag
                  : AppLocalizations.of(context)!.manageTags,
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Creation Date Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Creation Date',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: _creationDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                setState(() {
                  _creationDate = selectedDate;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Date',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Row(
                    children: [
                      Text(
                        '${_creationDate.month}/${_creationDate.day}/${_creationDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Inhabitants Tab
  Widget _buildInhabitantsTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inhabitants Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inhabitants',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _availableFish.isEmpty ? null : _addInhabitant,
                icon: const Icon(Icons.add),
                label: Text(l10n.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_inhabitants.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No inhabitants added yet',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the Add button to start building your tank community',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._inhabitants.asMap().entries.map((entry) {
              final index = entry.key;
              final inhabitant = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: _getFishImageUrl(inhabitant) != null
                              ? (_getFishImageUrl(
                                      inhabitant,
                                    )!.startsWith('http')
                                    ? CachedNetworkImageProvider(
                                        _getFishImageUrl(inhabitant)!,
                                      )
                                    : FileImage(
                                            File(_getFishImageUrl(inhabitant)!),
                                          )
                                          as ImageProvider)
                              : null,
                          backgroundColor: _getFishImageUrl(inhabitant) == null
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: _getFishImageUrl(inhabitant) == null
                              ? Icon(
                                  Icons.pets,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  size: 24,
                                )
                              : null,
                        ),
                        if (inhabitant.quantity > 1)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '${inhabitant.quantity}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  title: Text(inhabitant.customName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Fish Type: ${inhabitant.fishUnit}'),
                      if (inhabitant.speciesTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: inhabitant.speciesTags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer
                                          .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 10,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _duplicateInhabitant(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editInhabitant(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeInhabitant(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Photos Tab
  Widget _buildPhotosTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tank Photos Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tank Photos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addTankPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: Text(l10n.addPhoto),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tankPhotos.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tank photos added yet',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add photos of your tank to track its progress over time',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tankPhotos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return _buildTankPhotoThumbnail(photo, index);
              }).toList(),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String? _getFishImageUrl(TankInhabitant inhabitant) {
    // Prioritize custom image URL, then custom image path, then default fish image
    if (inhabitant.customImageUrl != null &&
        inhabitant.customImageUrl!.isNotEmpty) {
      return inhabitant.customImageUrl;
    }
    if (inhabitant.customImagePath != null &&
        inhabitant.customImagePath!.isNotEmpty) {
      return inhabitant.customImagePath;
    }

    // Fall back to default fish image
    try {
      final fish = (inhabitant.fishUuid != null
              ? _availableFish.where((f) => f.uuid == inhabitant.fishUuid).firstOrNull
              : null) ??
          _availableFish.firstWhere(
            (f) => f.name == inhabitant.fishUnit,
          );
      return fish.imageURL.isNotEmpty ? fish.imageURL : null;
    } catch (e) {
      return null;
    }
  }
}

class InhabitantDialog extends ConsumerStatefulWidget {
  final List<Fish> availableFish;
  final TankInhabitant? existingInhabitant;
  final Function(TankInhabitant) onAdd;
  final VoidCallback? onDelete;

  const InhabitantDialog({super.key,
    required this.availableFish,
    required this.onAdd,
    this.existingInhabitant,
    this.onDelete,
  });

  @override
  ConsumerState<InhabitantDialog> createState() => _InhabitantDialogState();
}

class _InhabitantDialogState extends ConsumerState<InhabitantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  final _urlController = TextEditingController();
  final _addSpeciesTagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedFishUnit;
  String? _selectedFishUuid;
  List<Fish> _filteredFish = [];
  String? _customImageUrl;
  String? _customImagePath;
  DateTime? _dateAdded;
  bool _fishSelectorExpanded = false;
  bool _customNameUserModified = false;
  bool _addSpeciesTagVisible = false;
  List<String> _selectedSpeciesTags = [];
  bool _speciesSectionExpanded = false;
  String? _reefSafeFilter;

  @override
  void initState() {
    super.initState();
    _filteredFish = widget.availableFish;
    _searchController.addListener(_filterFish);
    if (widget.existingInhabitant != null) {
      _customNameController.text = widget.existingInhabitant!.customName;
      _quantityController.text = widget.existingInhabitant!.quantity.toString();

      // Resolve the fish: try UUID lookup first (handles renamed fish), then
      // fall back to name-based lookup for backward compatibility.
      Fish? resolvedFish = widget.existingInhabitant!.fishUuid != null
          ? widget.availableFish
                .where((f) => f.uuid == widget.existingInhabitant!.fishUuid)
                .firstOrNull
          : null;
      resolvedFish ??= widget.availableFish
          .where((f) => f.name == widget.existingInhabitant!.fishUnit)
          .firstOrNull;

      if (resolvedFish != null) {
        _selectedFishUnit = resolvedFish.name;
        _selectedFishUuid = resolvedFish.uuid;
        // Start collapsed since a valid fish is found
        _fishSelectorExpanded = false;
      } else {
        // Fish no longer exists in data (UUID changed or renamed without UUID).
        // Leave _selectedFishUnit null so the user must re-select, and open
        // the fish picker automatically.
        _fishSelectorExpanded = true;
      }

      _customImageUrl = widget.existingInhabitant!.customImageUrl;
      _customImagePath = widget.existingInhabitant!.customImagePath;
      _dateAdded = widget.existingInhabitant!.dateAdded;
      _urlController.text = _customImageUrl ?? '';
      _selectedSpeciesTags = List<String>.from(
        widget.existingInhabitant!.speciesTags,
      );
      // When editing, check if the name has been user-modified (not the default pattern)
      final defaultName = 'My ${widget.existingInhabitant!.fishUnit}';
      _customNameUserModified =
          widget.existingInhabitant!.customName != defaultName;
    } else {
      _quantityController.text = '1';
      _dateAdded = DateTime.now(); // Default to now for new inhabitants
      // Start expanded so user can pick a fish type
      _fishSelectorExpanded = true;
    }
    _customNameController.addListener(_onCustomNameChanged);
  }

  void _onCustomNameChanged() {
    if (!_customNameUserModified) {
      // Check if the current value deviates from the auto-generated default
      final currentDefault = _selectedFishUnit != null
          ? 'My $_selectedFishUnit'
          : '';
      if (_customNameController.text != currentDefault) {
        setState(() {
          _customNameUserModified = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _customNameController.removeListener(_onCustomNameChanged);
    _customNameController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    _urlController.dispose();
    _addSpeciesTagController.dispose();
    super.dispose();
  }

  void _filterFish() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFish = widget.availableFish.where((fish) {
        // Reef safe filter (only for fish that have reefSafe field)
        if (_reefSafeFilter != null && fish.reefSafe != null) {
          if (fish.reefSafe != _reefSafeFilter) return false;
        }
        if (query.isEmpty) return true;
        // Check fish name and common names
        final nameMatches =
            fish.name.toLowerCase().contains(query) ||
            fish.commonNames.any((name) => name.toLowerCase().contains(query));

        // Check species tags
        final tags = ref.read(speciesTagsProvider).tags[fish.name] ?? [];
        final tagsMatch = tags.any((tag) => tag.toLowerCase().contains(query));

        return nameMatches || tagsMatch;
      }).toList();
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image != null) {
        setState(() {
          _customImagePath = image.path;
          _customImageUrl = null; // Clear URL if file is selected
          _urlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        context.showAccessibleMessage('Failed to pick image: $e');
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image != null) {
        setState(() {
          _customImagePath = image.path;
          _customImageUrl = null; // Clear URL if file is selected
          _urlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        context.showAccessibleMessage('Failed to take photo: $e');
      }
    }
  }

  void _setImageFromUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _customImageUrl = url;
        _customImagePath = null; // Clear file path if URL is set
      });
    }
  }

  void _clearCustomImage() {
    setState(() {
      _customImageUrl = null;
      _customImagePath = null;
      _urlController.clear();
    });
  }

  String? _getDisplayImageUrl() {
    if (_customImageUrl != null && _customImageUrl!.isNotEmpty) {
      return _customImageUrl;
    }
    if (_customImagePath != null && _customImagePath!.isNotEmpty) {
      return _customImagePath;
    }
    return null;
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedFishUnit != null) {
      final inhabitant = TankInhabitant(
        id: widget.existingInhabitant?.id ?? const Uuid().v4(),
        customName: _customNameController.text.trim(),
        fishUnit: _selectedFishUnit!,
        fishUuid: _selectedFishUuid,
        quantity: int.parse(_quantityController.text),
        customImageUrl: _customImageUrl,
        customImagePath: _customImagePath,
        dateAdded: _dateAdded,
        speciesTags: _selectedSpeciesTags,
      );

      widget.onAdd(inhabitant);
      Navigator.of(context).pop();
    } else if (_selectedFishUnit == null) {
      // Show snackbar if no fish type selected
      context.showAccessibleMessage('Please select a fish type');
    }
  }

  Widget _buildFishSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedFish = _selectedFishUnit != null
        ? widget.availableFish
              .where((f) => f.name == _selectedFishUnit)
              .firstOrNull
        : null;

    // Show a warning if we are editing an existing inhabitant whose fish type
    // could not be resolved (fish was renamed or UUID changed in data).
    final showMissingFishWarning = widget.existingInhabitant != null &&
        selectedFish == null &&
        _fishSelectorExpanded;

    // Get available species tags for the selected fish type.
    // Merge fish.commonNames with user-added species tags so that new
    // commonNames entries in fish_data.json are always reflected here,
    // just like they are in search and everywhere else in the app.
    final availableSpeciesTags = _selectedFishUnit != null
        ? {
            ...(selectedFish?.commonNames ?? []),
            ...(ref.watch(speciesTagsProvider).tags[_selectedFishUnit] ?? []),
          }.toList()
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning banner when the previous fish type is no longer in the data
        if (showMissingFishWarning) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.inhabitantFishTypeNoLongerAvailable(
                      widget.existingInhabitant!.fishUnit,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Header row with title and expand/change button
        Row(
          children: [
            Text(
              'Fish Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (selectedFish != null && !_fishSelectorExpanded)
              TextButton.icon(
                onPressed: () => setState(() => _fishSelectorExpanded = true),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Collapsed: show only the selected fish chip
        if (selectedFish != null && !_fishSelectorExpanded)
          InkWell(
            onTap: () => setState(() => _fishSelectorExpanded = true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: selectedFish.imageURL,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.pets,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedFish.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),

        // Species tags section (shown when a fish is selected)
        if (selectedFish != null && !_fishSelectorExpanded) ...[
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _speciesSectionExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _speciesSectionExpanded = expanded;
                  if (!expanded) {
                    _addSpeciesTagVisible = false;
                  }
                });
              },
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 6),
              title: Text(
                'Species (Optional)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                _speciesSectionExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              children: [
                if (availableSpeciesTags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: availableSpeciesTags.map((tag) {
                      final isSelected = _selectedSpeciesTags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedSpeciesTags = [tag];
                            } else {
                              _selectedSpeciesTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 6),
                if (_addSpeciesTagVisible)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addSpeciesTagController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Add species...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty &&
                                _selectedFishUnit != null) {
                              ref
                                  .read(speciesTagsProvider.notifier)
                                  .addTag(_selectedFishUnit!, value.trim());
                            }
                            setState(() {
                              _addSpeciesTagController.clear();
                              _addSpeciesTagVisible = false;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final value = _addSpeciesTagController.text;
                          if (value.trim().isNotEmpty &&
                              _selectedFishUnit != null) {
                            ref
                                .read(speciesTagsProvider.notifier)
                                .addTag(_selectedFishUnit!, value.trim());
                          }
                          setState(() {
                            _addSpeciesTagController.clear();
                            _addSpeciesTagVisible = false;
                          });
                        },
                        icon: const Icon(Icons.check, size: 18),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Confirm',
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _addSpeciesTagController.clear();
                            _addSpeciesTagVisible = false;
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Cancel',
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _addSpeciesTagVisible = true),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      l10n.addCustomSpecies,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],

        // Expanded: show search + full grid
        if (_fishSelectorExpanded) ...[
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Fish',
              hintText: 'Search by name...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (widget.availableFish.any((f) => f.reefSafe != null)) ...[
            const SizedBox(height: 8),
            _buildReefSafeFilter(context),
          ],
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 380),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filteredFish.map((fish) {
                  final isSelected = _selectedFishUnit == fish.name;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        // Clear species tags only when a different fish type is selected
                        if (_selectedFishUnit != fish.name) {
                          _selectedSpeciesTags = [];
                          _addSpeciesTagVisible = false;
                          _addSpeciesTagController.clear();
                        }
                        _selectedFishUnit = fish.name;
                        _selectedFishUuid = fish.uuid;
                        // Only auto-fill custom name if user hasn't modified it
                        if (!_customNameUserModified) {
                          _customNameController.text = 'My ${fish.name}';
                        }
                        // Collapse the selector after picking a fish
                        _fishSelectorExpanded = false;
                      });
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: fish.imageURL,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.pets,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fish.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : null,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Widget _buildReefSafeFilter(BuildContext context) {
    const options = ['Yes', 'No', 'Caution'];
    final colors = {
      'Yes': Colors.green,
      'No': Colors.red,
      'Caution': Colors.orange,
    };
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Reef Safe:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        ...options.map((opt) {
          final selected = _reefSafeFilter == opt;
          final color = colors[opt]!;
          return FilterChip(
            label: Text(opt),
            selected: selected,
            selectedColor: color.withOpacity(0.2),
            checkmarkColor: color,
            labelStyle: TextStyle(
              color: selected ? color : null,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: selected ? color : Theme.of(context).colorScheme.outline,
            ),
            onSelected: (_) {
              setState(() => _reefSafeFilter = selected ? null : opt);
              _filterFish();
            },
            visualDensity: VisualDensity.compact,
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.fromLTRB(12, 48, 12, 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Title
              Text(
                widget.existingInhabitant != null
                    ? 'Edit Inhabitant'
                    : 'Add Inhabitant',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _customNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Custom Name',
                                  hintText: 'My Angelfish',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a name';
                                  }
                                  return null;
                                },
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter quantity';
                                  }
                                  final quantity = int.tryParse(value);
                                  if (quantity == null || quantity < 1) {
                                    return 'Please enter a valid quantity';
                                  }
                                  return null;
                                },
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Date Added Field
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _dateAdded ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              helpText: 'Select Date Added',
                            );
                            if (picked != null) {
                              setState(() {
                                _dateAdded = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date Added',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _dateAdded != null
                                  ? '${_dateAdded!.month}/${_dateAdded!.day}/${_dateAdded!.year}'
                                  : 'Select date',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fish Type Selection with Images
                        _buildFishSelector(context),
                        if (_selectedFishUnit == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Please select a fish type',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Custom Image Section
                        Text(
                          'Custom Image (Optional)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Image Preview
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _getDisplayImageUrl() == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 32,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No custom image selected',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: _customImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: _customImageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onErrorContainer,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onErrorContainer,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                        )
                                      : Image.file(
                                          File(_customImagePath!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onErrorContainer,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onErrorContainer,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                        ),
                                ),
                        ),
                        const SizedBox(height: 12),

                        // Image Source Options
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.gallery),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _pickImageFromCamera,
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.camera),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (_getDisplayImageUrl() != null)
                              OutlinedButton.icon(
                                onPressed: _clearCustomImage,
                                icon: const Icon(Icons.clear, size: 18),
                                label: Text(l10n.clear),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // URL Input Field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                decoration: const InputDecoration(
                                  labelText: 'Or enter image URL',
                                  hintText: 'https://example.com/image.jpg',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.link),
                                ),
                                onSubmitted: (_) => _setImageFromUrl(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _setImageFromUrl,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              child: Text(l10n.set),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  if (widget.existingInhabitant != null &&
                      widget.onDelete != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.deleteInhabitant),
                              content: Text(
                                l10n.deleteInhabitantConfirm(
                                    widget.existingInhabitant!.customName),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: Text(
                                    l10n.delete,
                                    style: TextStyle(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            Navigator.of(context).pop();
                            widget.onDelete!();
                          }
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        label: Text(
                          l10n.deleteInhabitant,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(
                            widget.existingInhabitant != null
                                ? 'Update'
                                : 'Add',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog for adding/editing tank photos
class _TankPhotoDialog extends StatefulWidget {
  final TankPhoto? existingPhoto;
  final Function(TankPhoto) onAdd;

  const _TankPhotoDialog({this.existingPhoto, required this.onAdd});

  @override
  State<_TankPhotoDialog> createState() => _TankPhotoDialogState();
}

class _TankPhotoDialogState extends State<_TankPhotoDialog> {
  final _picker = ImagePicker();
  final _urlController = TextEditingController();
  String? _customImageUrl;
  String? _customImagePath;
  DateTime _dateTaken = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingPhoto != null) {
      _customImageUrl = widget.existingPhoto!.imageUrl;
      _customImagePath = widget.existingPhoto!.imagePath;
      _dateTaken = widget.existingPhoto!.dateTaken;
      if (_customImageUrl != null) {
        _urlController.text = _customImageUrl!;
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image != null) {
        setState(() {
          _customImagePath = image.path;
          _customImageUrl = null;
          _urlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        context.showAccessibleMessage('Failed to pick image: $e');
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image != null) {
        setState(() {
          _customImagePath = image.path;
          _customImageUrl = null;
          _urlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        context.showAccessibleMessage('Failed to take photo: $e');
      }
    }
  }

  void _setImageFromUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _customImageUrl = url;
        _customImagePath = null;
      });
    }
  }

  void _clearCustomImage() {
    setState(() {
      _customImageUrl = null;
      _customImagePath = null;
      _urlController.clear();
    });
  }

  String? _getDisplayImageUrl() {
    if (_customImageUrl != null && _customImageUrl!.isNotEmpty) {
      return _customImageUrl;
    }
    if (_customImagePath != null && _customImagePath!.isNotEmpty) {
      return _customImagePath;
    }
    return null;
  }

  void _save() {
    if (_customImageUrl == null && _customImagePath == null) {
      context.showAccessibleMessage('Please add an image');
      return;
    }

    final photo = TankPhoto(
      id: widget.existingPhoto?.id ?? const Uuid().v4(),
      imageUrl: _customImageUrl,
      imagePath: _customImagePath,
      dateTaken: _dateTaken,
    );

    widget.onAdd(photo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Title
              Text(
                widget.existingPhoto != null
                    ? 'Edit Tank Photo'
                    : 'Add Tank Photo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Preview
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _getDisplayImageUrl() == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No image selected',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: _customImageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: _customImageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.errorContainer,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onErrorContainer,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Failed to load image',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onErrorContainer,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      )
                                    : Image.file(
                                        File(_customImagePath!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Image Source Options
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.gallery),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.camera),
                          ),
                          if (_getDisplayImageUrl() != null)
                            OutlinedButton.icon(
                              onPressed: _clearCustomImage,
                              icon: const Icon(Icons.clear, size: 18),
                              label: Text(l10n.clear),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // URL Input
                      Text(
                        'Or enter image URL:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              decoration: const InputDecoration(
                                hintText: 'https://example.com/image.jpg',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.link),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _setImageFromUrl,
                            child: Text(l10n.load),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Date Taken Field
                      Text(
                        'Date Taken',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _dateTaken,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            helpText: 'Select Date Taken',
                          );
                          if (picked != null) {
                            setState(() {
                              _dateTaken = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_dateTaken.month}/${_dateTaken.day}/${_dateTaken.year}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(
                        widget.existingPhoto != null ? 'Update' : 'Add',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
