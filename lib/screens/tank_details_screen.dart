import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../models/tank.dart';
import '../models/water_parameter.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import '../utils/backup_restore_utils.dart';
import '../widgets/accessible_feedback.dart';
import 'dosing_logger_screen.dart';
import 'notification_logger_screen.dart';
import 'notification_management_screen.dart';
import 'parameter_logger_screen.dart';
import 'tank_creation_screen.dart';

/// Dedicated screen for displaying tank details with tabbed navigation
///
/// This replaces the previous modal dialog implementation while maintaining
/// backwards compatibility with existing tank data.
class TankDetailsScreen extends ConsumerStatefulWidget {
  final Tank tank;

  const TankDetailsScreen({super.key, required this.tank});

  @override
  TankDetailsScreenState createState() => TankDetailsScreenState();
}

class TankDetailsScreenState extends ConsumerState<TankDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCalculationBreakdown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    // Add listener to rebuild when tab changes
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Log screen view
    AnalyticsService.logScreenView(screenName: 'tank_details_screen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Get the latest tank state from the provider
  Tank _getCurrentTank() {
    final tanks = ref.watch(tankProvider).tanks;
    return tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tank = _getCurrentTank();
    final cs = Theme.of(context).colorScheme;

    // Watch the centralized fish data provider
    final fishDataAsync = ref.watch(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );

    // Resolve banner photo (if set)
    TankPhoto? bannerPhoto;
    if (tank.bannerPhotoId != null) {
      try {
        bannerPhoto = tank.photos.firstWhere((p) => p.id == tank.bannerPhotoId);
      } catch (_) {
        bannerPhoto = null;
      }
    }
    final hasBanner =
        bannerPhoto != null &&
        (bannerPhoto.imageUrl != null || bannerPhoto.imagePath != null);

    // Gradient colors based on tank type
    final gradientColors = tank.type == 'freshwater'
        ? [
            cs.primary.withOpacity(0.08),
            cs.primaryContainer.withOpacity(0.15),
            cs.surface,
          ]
        : [
            cs.secondary.withOpacity(0.08),
            cs.secondaryContainer.withOpacity(0.15),
            cs.surface,
          ];

    return MainLayout(
      title: tank.name,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              tank.name,
              style: hasBanner
                  ? const TextStyle(
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    )
                  : null,
            ),
            backgroundColor: hasBanner
                ? Colors.transparent
                : cs.surface.withOpacity(0.95),
            elevation: 0,
            iconTheme: hasBanner
                ? const IconThemeData(color: Colors.white)
                : null,
            actionsIconTheme: hasBanner
                ? const IconThemeData(color: Colors.white)
                : null,
            flexibleSpace: bannerPhoto != null
                ? _buildBannerFlexibleSpace(bannerPhoto)
                : null,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: hasBanner ? Colors.white : cs.primary,
              indicatorWeight: 3,
              labelColor: hasBanner ? Colors.white : cs.primary,
              unselectedLabelColor: hasBanner
                  ? Colors.white.withOpacity(0.7)
                  : cs.onSurface.withOpacity(0.6),
              dividerColor: hasBanner
                  ? Colors.white.withOpacity(0.2)
                  : cs.outlineVariant.withOpacity(0.2),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.dashboard_outlined,
                    color: _tabIconColor(0, cs, hasBanner),
                  ),
                  text: l10n.overview,
                ),
                Tab(
                  icon: Icon(
                    Icons.photo_library_outlined,
                    color: _tabIconColor(1, cs, hasBanner),
                  ),
                  text: l10n.photos,
                ),
                Tab(
                  icon: Icon(
                    Icons.science_outlined,
                    color: _tabIconColor(2, cs, hasBanner),
                  ),
                  text: l10n.waterParameters,
                ),
                Tab(
                  icon: Icon(
                    Icons.medication_outlined,
                    color: _tabIconColor(3, cs, hasBanner),
                  ),
                  text: l10n.dosing,
                ),
                Tab(
                  icon: Icon(
                    Icons.history,
                    color: _tabIconColor(4, cs, hasBanner),
                  ),
                  text: l10n.activity,
                ),
                Tab(
                  icon: Icon(
                    Icons.note_outlined,
                    color: _tabIconColor(5, cs, hasBanner),
                  ),
                  text: l10n.notes,
                ),
              ],
            ),
            actions: [
              // Share button
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: l10n.shareTank,
                onPressed: () {
                  BackupRestoreUtils.shareTank(context, ref, tank);
                },
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: l10n.editTank,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          TankCreationScreen(existingTank: tank),
                    ),
                  );
                },
              ),
              // Notifications button
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: l10n.notifications,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          NotificationManagementScreen(tank: tank),
                    ),
                  );
                },
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, tank, fishData),
              _buildPhotosTab(context, tank),
              _buildWaterParametersTab(context, tank),
              _buildDosingTab(context, tank),
              _buildActivityTab(context, tank),
              _buildNotesTab(context, tank),
            ],
          ),
          floatingActionButton: _buildFab(context, tank),
        ),
      ),
    );
  }

  /// Returns the appropriate icon color for a tab based on whether a banner
  /// is displayed and whether the tab is currently selected.
  Color _tabIconColor(int tabIndex, ColorScheme cs, bool hasBanner) {
    final isSelected = _tabController.index == tabIndex;
    if (hasBanner) {
      return isSelected ? Colors.white : Colors.white.withOpacity(0.7);
    }
    // Use theme accent colors per tab to match the original design
    final Color selectedColor;
    switch (tabIndex) {
      case 1:
      case 4:
        selectedColor = cs.secondary;
        break;
      case 2:
      case 5:
        selectedColor = cs.tertiary;
        break;
      default:
        selectedColor = cs.primary;
    }
    return isSelected ? selectedColor : cs.onSurface.withOpacity(0.6);
  }

  /// Builds the banner image for the AppBar flexibleSpace
  Widget _buildBannerFlexibleSpace(TankPhoto photo) {
    final imageUrl = photo.imageUrl ?? photo.imagePath;
    if (imageUrl == null) return const SizedBox.expand();
    return Stack(
      fit: StackFit.expand,
      children: [
        imageUrl.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const SizedBox.expand(),
              )
            : Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.expand(),
              ),
        // Dark overlay for text readability
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Color(0xBB000000)],
            ),
          ),
        ),
      ],
    );
  }

  /// Sets or clears the banner photo for the tank details screen
  void _setBannerPhoto(Tank tank, String? photoId) {
    final updatedTank = photoId == null
        ? tank.copyWith(clearBannerPhotoId: true, updatedAt: DateTime.now())
        : tank.copyWith(bannerPhotoId: photoId, updatedAt: DateTime.now());
    ref.read(tankProvider.notifier).updateTank(updatedTank);
  }

  /// Add a new photo to the tank
  void _addPhoto(BuildContext context, Tank tank) {
    showDialog(
      context: context,
      builder: (context) => _TankPhotoDialog(
        onSave: (photo) {
          final updatedTank = tank.copyWith(
            photos: [...tank.photos, photo],
            updatedAt: DateTime.now(),
          );
          ref.read(tankProvider.notifier).updateTank(updatedTank);
        },
      ),
    );
  }

  /// Edit an existing photo
  void _editPhoto(BuildContext context, Tank tank, TankPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => _TankPhotoDialog(
        existingPhoto: photo,
        onSave: (updated) {
          final updatedPhotos = tank.photos
              .map((p) => p.id == photo.id ? updated : p)
              .toList();
          final updatedTank = tank.copyWith(
            photos: updatedPhotos,
            updatedAt: DateTime.now(),
          );
          ref.read(tankProvider.notifier).updateTank(updatedTank);
        },
      ),
    );
  }

  /// Delete a photo from the tank
  void _deletePhoto(BuildContext context, Tank tank, TankPhoto photo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Remove this photo from the tank?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final isBanner = photo.id == tank.bannerPhotoId;
              final updatedTank = tank.copyWith(
                photos: tank.photos.where((p) => p.id != photo.id).toList(),
                clearBannerPhotoId: isBanner,
                updatedAt: DateTime.now(),
              );
              ref.read(tankProvider.notifier).updateTank(updatedTank);
            },
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable edit/delete popup menu for list items
  Widget _buildEditDeleteMenu({
    required BuildContext context,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 8),
              Text(l10n.edit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shows a generic delete confirmation dialog
  void _confirmDelete(BuildContext context, {required VoidCallback onConfirm}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating action button - context-sensitive per tab
  Widget? _buildFab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    switch (_tabController.index) {
      case 1: // Photos
        return FloatingActionButton.extended(
          heroTag: 'fab_photos',
          onPressed: () => _addPhoto(context, tank),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(l10n.addPhoto),
        );
      case 2: // Parameters
        return FloatingActionButton.extended(
          heroTag: 'fab_parameters',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ParameterLoggerScreen(tank: tank, openAddDialog: true),
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.addParameter),
        );
      case 3: // Dosing
        return FloatingActionButton.extended(
          heroTag: 'fab_dosing',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  DosingLoggerScreen(tank: tank, openAddDialog: true),
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.addDose),
        );
      case 4: // Activity
        return FloatingActionButton.extended(
          heroTag: 'fab_activity',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NotificationLoggerScreen(
                tank: tank,
                openAddDialog: true,
                initialTabIndex: 1,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.addLogEntry),
        );
      case 5: // Notes
        return FloatingActionButton.extended(
          heroTag: 'fab_notes',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NotificationLoggerScreen(
                tank: tank,
                openAddDialog: true,
                initialTabIndex: 0,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.addNote),
        );
      default:
        return null;
    }
  }

  /// Overview tab - Tank info, harmony score, inhabitants, action buttons
  Widget _buildOverviewTab(
    BuildContext context,
    Tank tank,
    Map<String, List<Fish>>? fishData,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tank info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tank.type == 'freshwater'
                              ? [cs.primary, cs.primary.withOpacity(0.7)]
                              : [cs.secondary, cs.secondary.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (tank.type == 'freshwater'
                                        ? cs.primary
                                        : cs.secondary)
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        tank.type == 'freshwater'
                            ? Icons.water_drop
                            : Icons.waves,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tank.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tank.type == 'freshwater'
                                ? l10n.freshwaterTank
                                : (tank.isReef
                                      ? l10n.reefTank
                                      : l10n.saltwaterTank),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats chips
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (tank.sizeGallons != null || tank.sizeLiters != null)
                      _buildStatChip(
                        context,
                        Icons.straighten,
                        _formatTankSize(tank),
                      ),
                    if (tank.sizeGallons != null || tank.sizeLiters != null)
                      _buildStatChip(
                        context,
                        Icons.line_weight,
                        _formatWaterWeight(tank),
                      ),
                    if (tank.inhabitants.isNotEmpty && fishData != null)
                      _buildHarmonyScoreChip(tank),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Inhabitants section
        if (tank.inhabitants.isNotEmpty && fishData != null) ...[
          _buildInhabitantsSection(context, tank, fishData),
          const SizedBox(height: 16),
        ],

        // Compatibility calculation breakdown
        if (tank.inhabitants.isNotEmpty &&
            fishData != null &&
            tank.calculationBreakdown != null) ...[
          _buildCompatibilitySection(context, tank),
          const SizedBox(height: 16),
        ],

        // Timestamps
        _buildTimestampsCard(context, tank),
      ],
    );
  }

  /// Photos tab - Tank photos gallery
  Widget _buildPhotosTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (tank.photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPhotos,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: tank.photos.length,
      itemBuilder: (context, index) {
        final photo = tank.photos[index];
        final imageUrl = photo.imageUrl ?? photo.imagePath;

        return GestureDetector(
          onTap: () => _showPhotoMaximized(context, photo, tank),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Image.file(
                          File(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        )
                else
                  Container(
                    color: cs.surfaceContainerHighest,
                    child: const Icon(Icons.image_not_supported),
                  ),
                // Date overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
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
                    child: Text(
                      DateFormat.yMMMd().format(photo.dateTaken),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Banner indicator (top-left)
                if (photo.id == tank.bannerPhotoId)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                // Photo options menu (top-right)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 16,
                      ),
                      iconSize: 16,
                      padding: const EdgeInsets.all(4),
                      onSelected: (value) {
                        if (value == 'edit') _editPhoto(context, tank, photo);
                        if (value == 'delete') {
                          _deletePhoto(context, tank, photo);
                        }
                        if (value == 'set_banner') {
                          _setBannerPhoto(tank, photo.id);
                        }
                        if (value == 'remove_banner') {
                          _setBannerPhoto(tank, null);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: photo.id == tank.bannerPhotoId
                              ? 'remove_banner'
                              : 'set_banner',
                          child: Row(
                            children: [
                              Icon(
                                photo.id == tank.bannerPhotoId
                                    ? Icons.star
                                    : Icons.star_outline,
                                size: 18,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                photo.id == tank.bannerPhotoId
                                    ? l10n.removeBanner
                                    : l10n.setAsBanner,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: cs.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: TextStyle(color: cs.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Water Parameters tab - Latest water parameters
  Widget _buildWaterParametersTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (tank.waterParameters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noParameters,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Sort parameters by date and group by type
    final sortedParams = List<WaterParameter>.from(tank.waterParameters)
      ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.latestWaterParameters,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Show all parameters as cards
        ...sortedParams.map((param) {
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.science_outlined, color: cs.primary),
              ),
              title: Text(param.parameterType.toUpperCase()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${param.value} ${param.unit ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_jm().format(param.dateRecorded),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (param.notes != null && param.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      param.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: _buildEditDeleteMenu(
                context: context,
                onEdit: () =>
                    showParameterSheet(context, tank, existingParameter: param),
                onDelete: () => _confirmDelete(
                  context,
                  onConfirm: () {
                    final updatedTank = tank.copyWith(
                      waterParameters: tank.waterParameters
                          .where((p) => p.id != param.id)
                          .toList(),
                      updatedAt: DateTime.now(),
                    );
                    ref.read(tankProvider.notifier).updateTank(updatedTank);
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Dosing tab - Dosing diary entries
  Widget _buildDosingTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (tank.dosingEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDosing,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Get latest 10 dosing entries
    final recentEntries = tank.dosingEntries.reversed.take(10).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${l10n.recentDosing} (${recentEntries.length}/${tank.dosingEntries.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...recentEntries.map((entry) {
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.medication, color: cs.primary),
              ),
              title: Text(entry.treatmentName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.amount} ${entry.unit}'),
                  Text(
                    DateFormat.yMMMd().add_jm().format(entry.dateDosed),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              trailing: _buildEditDeleteMenu(
                context: context,
                onEdit: () =>
                    showDosingSheet(context, tank, existingEntry: entry),
                onDelete: () => _confirmDelete(
                  context,
                  onConfirm: () {
                    final updatedTank = tank.copyWith(
                      dosingEntries: tank.dosingEntries
                          .where((e) => e.id != entry.id)
                          .toList(),
                      updatedAt: DateTime.now(),
                    );
                    ref.read(tankProvider.notifier).updateTank(updatedTank);
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Activity tab - Activity log and notification logs
  Widget _buildActivityTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (tank.notificationLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              l10n.noActivity,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Get latest 10 activity logs
    final recentLogs = tank.notificationLogs.reversed.take(10).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${l10n.recentActivity} (${recentLogs.length}/${tank.notificationLogs.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...recentLogs.map((log) {
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: Icon(_getActivityIcon(log.type), color: cs.primary),
              ),
              title: Text(
                log.customCategory ?? log.type.toString().split('.').last,
              ),
              subtitle: Text(
                DateFormat.yMMMd().add_jm().format(log.loggedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              trailing: _buildEditDeleteMenu(
                context: context,
                onEdit: () =>
                    showLogEntrySheet(context, tank, existingEntry: log),
                onDelete: () => _confirmDelete(
                  context,
                  onConfirm: () {
                    final updatedTank = tank.copyWith(
                      notificationLogs: tank.notificationLogs
                          .where((l) => l.id != log.id)
                          .toList(),
                      updatedAt: DateTime.now(),
                    );
                    ref.read(tankProvider.notifier).updateTank(updatedTank);
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Notes tab - Tank notes
  Widget _buildNotesTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (tank.tankNotes.isEmpty && (tank.notes == null || tank.notes!.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noNotes,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Legacy notes field
        if (tank.notes != null && tank.notes!.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.tankNotes,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(tank.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tank notes list
        if (tank.tankNotes.isNotEmpty) ...[
          Text(
            l10n.notesSection,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...tank.tankNotes.reversed.map((note) {
            return Card(
              child: ListTile(
                title: Text(note.content),
                subtitle: Text(
                  DateFormat.yMMMd().add_jm().format(note.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: _buildEditDeleteMenu(
                  context: context,
                  onEdit: () =>
                      showNoteSheet(context, tank, existingNote: note),
                  onDelete: () => _confirmDelete(
                    context,
                    onConfirm: () {
                      final updatedTank = tank.copyWith(
                        tankNotes: tank.tankNotes
                            .where((n) => n.id != note.id)
                            .toList(),
                        updatedAt: DateTime.now(),
                      );
                      ref.read(tankProvider.notifier).updateTank(updatedTank);
                    },
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // Helper methods

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyScoreChip(Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final score = tank.harmonyScore ?? 0.0;
    final percentage = (score * 100).toInt();

    Color scoreColor;
    if (score >= 0.8) {
      scoreColor = Colors.green;
    } else if (score >= 0.6) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 16, color: scoreColor),
          const SizedBox(width: 6),
          Text(
            '${l10n.harmony}: $percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTankSize(Tank tank) {
    if (tank.sizeGallons != null) {
      return '${tank.sizeGallons!.toStringAsFixed(1)} gal';
    } else if (tank.sizeLiters != null) {
      return '${tank.sizeLiters!.toStringAsFixed(1)} L';
    }
    return 'N/A';
  }

  String _formatWaterWeight(Tank tank) {
    if (tank.sizeGallons != null) {
      final weightLbs = tank.sizeGallons! * 8.34;
      return '${weightLbs.toStringAsFixed(1)} lbs';
    } else if (tank.sizeLiters != null) {
      final weightKg = tank.sizeLiters!;
      return '${weightKg.toStringAsFixed(1)} kg';
    }
    return 'N/A';
  }

  Widget _buildInhabitantsSection(
    BuildContext context,
    Tank tank,
    Map<String, List<Fish>> fishData,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pets,
                    color: cs.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.inhabitantsLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tank.inhabitants.map((inhabitant) {
              final fishImageUrl = _getFishImageUrl(
                tank.type,
                inhabitant.fishUnit,
                fishData,
                inhabitant: inhabitant,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: fishImageUrl != null
                              ? (fishImageUrl.startsWith('http')
                                    ? CachedNetworkImageProvider(fishImageUrl)
                                    : FileImage(File(fishImageUrl))
                                          as ImageProvider)
                              : null,
                          backgroundColor: fishImageUrl == null
                              ? cs.primaryContainer
                              : null,
                          child: fishImageUrl == null
                              ? Icon(
                                  Icons.shape_line,
                                  color: cs.onPrimaryContainer,
                                  size: 22,
                                )
                              : null,
                        ),
                        // Quantity badge
                        if (inhabitant.quantity > 1)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cs.surface,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${inhabitant.quantity}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inhabitant.customName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            inhabitant.fishUnit,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (inhabitant.speciesTags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
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
                                          color: cs.secondaryContainer
                                              .withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: cs.onSecondaryContainer,
                                              ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          if (inhabitant.dateAdded != null)
                            Text(
                              'Added: ${inhabitant.dateAdded!.month}/${inhabitant.dateAdded!.day}/${inhabitant.dateAdded!.year}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Helper method to get fish image URL (prioritizes custom images)
  String? _getFishImageUrl(
    String tankType,
    String fishName,
    Map<String, List<Fish>>? fishData, {
    TankInhabitant? inhabitant,
  }) {
    // Prioritize custom images if inhabitant is provided
    if (inhabitant != null) {
      if (inhabitant.customImageUrl != null &&
          inhabitant.customImageUrl!.isNotEmpty) {
        return inhabitant.customImageUrl;
      }
      if (inhabitant.customImagePath != null &&
          inhabitant.customImagePath!.isNotEmpty) {
        return inhabitant.customImagePath;
      }
    }

    // Fall back to default fish image
    if (fishData == null) return null;

    final categoryFish = fishData[tankType] ?? [];
    final fish = categoryFish.firstWhere(
      (f) => f.name == fishName,
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

  Widget _buildCompatibilitySection(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _showCalculationBreakdown = !_showCalculationBreakdown;
                });
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calculate,
                      color: cs.onTertiaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.compatibilityCalculation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showCalculationBreakdown
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            if (_showCalculationBreakdown) ...[
              const SizedBox(height: 12),
              Text(
                tank.calculationBreakdown ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampsCard(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: cs.onSurface.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  l10n.timestamps,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.createdLabel}: ${DateFormat.yMMMd().add_jm().format(tank.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${l10n.lastUpdated}: ${DateFormat.yMMMd().add_jm().format(tank.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(dynamic type) {
    // Handle both NotificationType enum and string
    final typeStr = type.toString().split('.').last.toLowerCase();

    switch (typeStr) {
      case 'feeding':
        return Icons.restaurant;
      case 'dosing':
        return Icons.medication;
      case 'waterchange':
        return Icons.water;
      case 'testing':
        return Icons.science;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.event;
    }
  }

  void _showPhotoMaximized(BuildContext context, TankPhoto photo, Tank tank) {
    final imageUrl = photo.imageUrl ?? photo.imagePath;
    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final isBanner = photo.id == tank.bannerPhotoId;
        return Dialog(
          backgroundColor: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  DateFormat.yMMMd().format(photo.dateTaken),
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isBanner ? Icons.star : Icons.star_outline,
                      color: isBanner ? Colors.amber : Colors.white,
                    ),
                    tooltip: isBanner ? l10n.removeBanner : l10n.setAsBanner,
                    onPressed: () {
                      _setBannerPhoto(tank, isBanner ? null : photo.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Image.file(
                          File(imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dialog for adding or editing a tank photo
class _TankPhotoDialog extends StatefulWidget {
  final TankPhoto? existingPhoto;
  final Function(TankPhoto) onSave;

  const _TankPhotoDialog({this.existingPhoto, required this.onSave});

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
      if (mounted) context.showAccessibleMessage('Failed to pick image: $e');
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
      if (mounted) context.showAccessibleMessage('Failed to take photo: $e');
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
    widget.onSave(photo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                widget.existingPhoto != null ? 'Edit Photo' : l10n.addPhoto,
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
                          border: Border.all(color: cs.outline, width: 1),
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
                                      color: cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No image selected',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
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
                                            const Icon(Icons.error),
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
                      // Date Taken
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
                          );
                          if (picked != null) {
                            setState(() => _dateTaken = picked);
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
                        widget.existingPhoto != null ? 'Update' : l10n.add,
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
