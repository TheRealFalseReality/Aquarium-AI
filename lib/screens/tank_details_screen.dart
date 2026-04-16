import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/dosing_entry.dart';
import '../models/dosing_preset.dart';
import '../models/fish.dart';
import '../models/tank.dart';
import '../models/water_parameter.dart';
import '../providers/app_settings_provider.dart';
import '../providers/dosing_presets_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import '../services/notification_service.dart';
import '../utils/backup_restore_utils.dart';
import '../models/notification_log.dart';
import '../models/tank_notification.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/dosing_preset_editor_dialog.dart';
import '../widgets/notification_reschedule_dialog.dart';
import 'dosing_calculator.dart';
import 'notification_logger_screen.dart';
import 'notification_management_screen.dart';
import 'parameter_logger_screen.dart';
import 'tank_creation_screen.dart';
import 'tank_inhabitant_screen.dart';

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
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

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
                    Icons.notifications_outlined,
                    color: _tabIconColor(4, cs, hasBanner),
                  ),
                  text: l10n.upcomingNotifications,
                ),
                Tab(
                  icon: Icon(
                    Icons.history,
                    color: _tabIconColor(5, cs, hasBanner),
                  ),
                  text: l10n.activity,
                ),
                Tab(
                  icon: Icon(
                    Icons.note_outlined,
                    color: _tabIconColor(6, cs, hasBanner),
                  ),
                  text: l10n.notes,
                ),
              ],
            ),
            actions: const [],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, tank, fishData),
              _buildPhotosTab(context, tank),
              _buildWaterParametersTab(context, tank),
              _buildDosingTab(context, tank),
              _buildUpcomingNotificationsTab(context, tank),
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
      case 5:
        selectedColor = cs.secondary;
        break;
      case 2:
      case 6:
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

  /// Quick add a photo directly via image picker (bypasses the full photo dialog)
  Future<void> _quickAddPhoto(BuildContext context, Tank tank) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addPhoto),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l10n.gallery),
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          TextButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(l10n.camera),
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null || !mounted) return;
      final currentTank = _getCurrentTank();
      final photo = TankPhoto(
        id: const Uuid().v4(),
        imagePath: picked.path,
        dateTaken: DateTime.now(),
      );
      final updatedTank = currentTank.copyWith(
        photos: [...currentTank.photos, photo],
        updatedAt: DateTime.now(),
      );
      ref.read(tankProvider.notifier).updateTank(updatedTank);
      AnalyticsService.logFeatureUsed(featureName: 'quick_add_tank_photo');
    } catch (e) {
      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n2.failedToPickImage)),
        );
      }
    }
  }

  /// Quick add inhabitant via the InhabitantDialog; auto-saves the tank.
  void _quickAddInhabitant(BuildContext context, Tank tank) {
    final fishDataAsync = ref.read(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );
    final availableFish = fishData?[tank.type] ?? const <Fish>[];
    showDialog<void>(
      context: context,
      builder: (_) => InhabitantDialog(
        availableFish: availableFish,
        onAdd: (inhabitant) {
          final currentTank = _getCurrentTank();
          final updatedTank = currentTank.copyWith(
            inhabitants: [...currentTank.inhabitants, inhabitant],
            updatedAt: DateTime.now(),
          );
          ref.read(tankProvider.notifier).updateTank(updatedTank);
          AnalyticsService.logFeatureUsed(
            featureName: 'quick_add_inhabitant',
            parameters: {'fish_type': inhabitant.fishUnit},
          );
        },
      ),
    );
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

  /// Floating action button - context-sensitive per tab.
  /// Tab 0 (Overview) shows a speed-dial FAB with tank actions.
  Widget? _buildFab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    switch (_tabController.index) {
      case 0: // Overview – tank actions speed-dial
        return _buildTankActionsFab(context, tank, l10n);
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
        return _buildDosingFab(context, tank);
      case 4: // Upcoming Notifications
        return FloatingActionButton.extended(
          heroTag: 'fab_notifications',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  NotificationManagementScreen(tank: tank),
            ),
          ),
          icon: const Icon(Icons.notifications_outlined),
          label: Text(l10n.manageNotifications),
        );
      case 5: // Activity
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
      case 6: // Notes
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

  /// Speed-dial FAB for the Overview tab – shows Edit, Share, Notifications,
  /// Add Inhabitant, Quick Add Photo, Quick Add Parameters, Quick Add Dosing,
  /// and Quick Add Activity.
  Widget _buildTankActionsFab(
      BuildContext context, Tank tank, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini action buttons (only visible when expanded)
        AnimatedOpacity(
          opacity: _fabOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSlide(
            offset: _fabOpen ? Offset.zero : const Offset(0, 0.5),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: !_fabOpen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFabAction(
                    heroTag: 'fab_action_notifications',
                    icon: Icons.notifications_outlined,
                    label: l10n.notifications,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              NotificationManagementScreen(tank: tank),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFabAction(
                    heroTag: 'fab_action_share',
                    icon: Icons.share_outlined,
                    label: l10n.shareTank,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      BackupRestoreUtils.shareTank(context, ref, tank);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFabAction(
                    heroTag: 'fab_action_activity',
                    icon: Icons.history,
                    label: l10n.addLogEntry,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NotificationLoggerScreen(
                            tank: tank,
                            openAddDialog: true,
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFabAction(
                    heroTag: 'fab_action_dosing',
                    icon: Icons.medication_outlined,
                    label: l10n.recordDose,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      _showRecordDoseSheet(context, tank);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFabAction(
                    heroTag: 'fab_action_parameters',
                    icon: Icons.science_outlined,
                    label: l10n.addParameter,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ParameterLoggerScreen(
                            tank: tank,
                            openAddDialog: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFabAction(
                    heroTag: 'fab_action_photo',
                    icon: Icons.add_a_photo_outlined,
                    label: l10n.quickAddPhoto,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      _quickAddPhoto(context, tank);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFabAction(
                    heroTag: 'fab_action_add_inhabitant',
                    icon: Icons.pets,
                    label: l10n.addInhabitant,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      _quickAddInhabitant(context, tank);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFabAction(
                    heroTag: 'fab_action_edit',
                    icon: Icons.edit_outlined,
                    label: l10n.editTank,
                    cs: cs,
                    onPressed: () {
                      setState(() => _fabOpen = false);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              TankCreationScreen(existingTank: tank),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
        // Main toggle FAB
        FloatingActionButton(
          heroTag: 'fab_tank_actions_main',
          tooltip: l10n.tankActions,
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_fabOpen ? Icons.close : Icons.more_vert),
          ),
        ),
      ],
    );
  }

  /// Builds a single mini FAB row (icon button + label).
  Widget _buildFabAction({
    required String heroTag,
    required IconData icon,
    required String label,
    required ColorScheme cs,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: cs.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: heroTag,
          onPressed: onPressed,
          child: Icon(icon),
        ),
      ],
    );
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
                          Row(
                            children: [
                              Text(
                                _tankTypeEmoji(tank),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  tank.type == 'freshwater'
                                      ? (tank.freshwaterSubtype == 'planted'
                                            ? l10n.plantedFreshwaterTank
                                            : tank.freshwaterSubtype ==
                                                    'brackish'
                                            ? l10n.brackishTank
                                            : l10n.freshwaterTank)
                                      : (tank.isReef
                                            ? l10n.reefTank
                                            : l10n.saltwaterTank),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
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
                    if (tank.sizeGallons != null || tank.sizeLiters != null)
                      _buildSubstrateChip(context, tank),
                    _buildTankAgeChip(context, tank),
                    if (tank.inhabitants.isNotEmpty && fishData != null)
                      _buildHarmonyScoreChip(tank),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Health at a glance card
        _buildHealthSummaryCard(context, tank),

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

  /// Health summary card — "Health at a Glance"
  Widget _buildHealthSummaryCard(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Last water change — single-pass search through notification logs
    NotificationLog? latestWaterChangeLog;
    for (final log in tank.notificationLogs) {
      if (log.type == NotificationType.waterChange) {
        if (latestWaterChangeLog == null ||
            log.loggedAt.isAfter(latestWaterChangeLog.loggedAt)) {
          latestWaterChangeLog = log;
        }
      }
    }
    final lastWaterChange = latestWaterChangeLog != null
        ? DateFormat('MMM d, yyyy').format(latestWaterChangeLog.loggedAt)
        : '-';

    // Last parameter test — single-pass search through water parameters
    WaterParameter? latestParam;
    for (final p in tank.waterParameters) {
      if (latestParam == null ||
          p.dateRecorded.isAfter(latestParam.dateRecorded)) {
        latestParam = p;
      }
    }
    final lastParamTest = latestParam != null
        ? DateFormat('MMM d, yyyy').format(latestParam.dateRecorded)
        : '-';

    // Total inhabitants count
    final totalInhabitants = tank.inhabitants.fold<int>(
      0,
      (sum, i) => sum + i.quantity,
    );
    final totalInhabitantsText = tank.inhabitants.isEmpty
        ? '-'
        : '$totalInhabitants';

    // Overdue notifications count
    final overdueCount =
        tank.notifications.where((n) => n.enabled && n.shouldTrigger()).length;
    final overdueText = overdueCount > 0 ? overdueCount.toString() : '-';
    final overdueColor =
        overdueCount > 0 ? Colors.orange : cs.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.healthAtAGlance,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthStatItem(
                    context,
                    icon: Icons.water_drop_outlined,
                    label: l10n.lastWaterChange,
                    value: lastWaterChange,
                  ),
                ),
                Expanded(
                  child: _buildHealthStatItem(
                    context,
                    icon: Icons.science_outlined,
                    label: l10n.lastParameterTest,
                    value: lastParamTest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHealthStatItem(
                    context,
                    icon: Icons.pets_outlined,
                    label: l10n.inhabitantsLabel,
                    value: totalInhabitantsText,
                  ),
                ),
                Expanded(
                  child: _buildHealthStatItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: l10n.overdueNotifications,
                    value: overdueText,
                    valueColor: overdueColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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

    // Group by type and find the latest reading per type (sorted by date desc)
    final Map<String, WaterParameter> latestPerType = {};
    for (final p in tank.waterParameters) {
      final existing = latestPerType[p.parameterType];
      if (existing == null ||
          p.dateRecorded.isAfter(existing.dateRecorded)) {
        latestPerType[p.parameterType] = p;
      }
    }
    final latestParams = latestPerType.values.toList()
      ..sort((a, b) => a.parameterType.compareTo(b.parameterType));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Navigation banner → full history screen with graphs
        OutlinedButton.icon(
          icon: const Icon(Icons.show_chart),
          label: Text(l10n.viewHistoryAndGraphs),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ParameterLoggerScreen(tank: tank),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          l10n.latestReadings,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 2-column mosaic grid of latest readings per parameter type
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: latestParams.length,
          itemBuilder: (context, index) {
            final param = latestParams[index];
            final color = _getParameterColor(param.parameterType);
            return _buildParameterMosaicTile(context, param, color, tank);
          },
        ),
      ],
    );
  }

  /// Compact mosaic tile for a single latest water parameter reading.
  Widget _buildParameterMosaicTile(
    BuildContext context,
    WaterParameter param,
    Color color,
    Tank tank,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ParameterLoggerScreen(tank: tank),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getParameterIcon(param.parameterType),
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _getParameterLabel(param.parameterType, context),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${param.value}${param.unit != null && param.unit!.isNotEmpty ? ' ${param.unit}' : ''}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, y').format(param.dateRecorded),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the display label for a water parameter type.
  String _getParameterLabel(String parameterType, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (parameterType) {
      case 'ammonia':
        return l10n.ammonia;
      case 'nitrite':
        return l10n.nitrite;
      case 'nitrate':
        return l10n.nitrate;
      case 'phosphate':
        return l10n.phosphate;
      case 'salinity':
        return l10n.salinity;
      case 'calcium':
        return l10n.calcium;
      case 'magnesium':
        return l10n.magnesium;
      case 'kh':
        return l10n.kh;
      case 'gh':
        return l10n.gh;
      case 'alkalinity':
        return l10n.alkalinity;
      case 'orp':
        return l10n.orp;
      case 'ph':
        return l10n.ph;
      case 'potassium':
        return l10n.potassium;
      case 'tds':
        return l10n.tds;
      case 'iodine':
        return l10n.iodine;
      case 'temperature':
        return l10n.temperature;
      default:
        if (parameterType.isEmpty) return l10n.custom;
        return parameterType[0].toUpperCase() +
            (parameterType.length > 1 ? parameterType.substring(1) : '');
    }
  }

  /// Returns the icon for a water parameter type.
  IconData _getParameterIcon(String parameterType) {
    switch (parameterType) {
      case 'ammonia':
        return Icons.warning;
      case 'nitrite':
        return Icons.science;
      case 'nitrate':
        return Icons.analytics;
      case 'phosphate':
        return Icons.bubble_chart;
      case 'salinity':
        return Icons.water;
      case 'calcium':
        return Icons.diamond;
      case 'magnesium':
        return Icons.bolt;
      case 'kh':
        return Icons.shield;
      case 'gh':
        return Icons.hardware;
      case 'alkalinity':
        return Icons.balance;
      case 'orp':
        return Icons.battery_charging_full;
      case 'ph':
        return Icons.science_outlined;
      case 'potassium':
        return Icons.spa;
      case 'tds':
        return Icons.grain;
      case 'iodine':
        return Icons.ac_unit;
      case 'temperature':
        return Icons.thermostat;
      default:
        return Icons.science;
    }
  }

  /// Returns the accent color for a water parameter type.
  Color _getParameterColor(String parameterType) {
    switch (parameterType) {
      case 'ammonia':
        return Colors.amber;
      case 'nitrite':
        return Colors.orange;
      case 'nitrate':
        return Colors.red;
      case 'phosphate':
        return Colors.purple;
      case 'salinity':
        return Colors.blue;
      case 'calcium':
        return Colors.teal;
      case 'magnesium':
        return Colors.cyan;
      case 'kh':
        return Colors.indigo;
      case 'gh':
        return Colors.brown;
      case 'alkalinity':
        return Colors.lightBlue;
      case 'orp':
        return Colors.green;
      case 'ph':
        return Colors.lime;
      case 'potassium':
        return Colors.deepPurple;
      case 'tds':
        return Colors.blueGrey;
      case 'iodine':
        return Colors.deepOrange;
      case 'temperature':
        return Colors.redAccent;
      default:
        return Colors.teal;
    }
  }

  /// Dosing tab - Integrated dosing calculator + dosing history log
  Widget _buildDosingTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // All dosing entries, newest first
    final allEntries = tank.dosingEntries.toList()
      ..sort((a, b) => b.dateDosed.compareTo(a.dateDosed));

    // Group entries by treatment name
    final grouped = <String, List<DosingEntry>>{};
    for (var entry in allEntries) {
      grouped.putIfAbsent(entry.treatmentName, () => []).add(entry);
    }

    if (allEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                l10n.noDosingEntries,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary card ────────────────────────────────────────────────
        _buildDosingSummaryCard(context, tank, allEntries),
        const SizedBox(height: 16),

        // ── Dosing History ──────────────────────────────────────────────
        Text(
          '${l10n.dosingHistory} (${allEntries.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Grouped by treatment name
        ...grouped.entries.map((group) {
          final treatmentName = group.key;
          final entries = group.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              title: Text(
                treatmentName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                l10n.dosingEntryCount(entries.length),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              children: entries.map((entry) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  title: Text(
                    '${entry.amount} ${entry.unit}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMd().add_jm().format(entry.dateDosed),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty)
                        Text(
                          entry.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                  trailing: _buildEditDeleteMenu(
                    context: context,
                    onEdit: () => _showRecordDoseSheet(
                      context,
                      tank,
                      existingEntry: entry,
                    ),
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
                        AnalyticsService.logFeatureUsed(
                          featureName: 'dosing_entry_deleted',
                          parameters: {
                            'treatment_name': entry.treatmentName,
                            'tank_type': tank.type,
                          },
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
        // Extra bottom padding so FAB doesn't obscure the last item
        const SizedBox(height: 80),
      ],
    );
  }

  /// Summary card for the dosing tab showing totals and last dose
  Widget _buildDosingSummaryCard(
    BuildContext context,
    Tank tank,
    List<DosingEntry> allEntries,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final uniqueTreatments =
        allEntries.map((e) => e.treatmentName).toSet().length;
    final lastDose = allEntries.isNotEmpty ? allEntries.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: cs.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.dosingSum,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDosingSummaryItem(
                    context,
                    l10n.totalDoses,
                    allEntries.length.toString(),
                    Icons.medication,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDosingSummaryItem(
                    context,
                    l10n.treatments,
                    uniqueTreatments.toString(),
                    Icons.inventory_2,
                  ),
                ),
              ],
            ),
            if (lastDose != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.dosingLastDose(
                        DateFormat('MMM d, yyyy').format(lastDose.dateDosed),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDosingSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the dosing FAB with two options: Record Dose & Calculate & Record
  Widget _buildDosingFab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Calculate & Record option
        FloatingActionButton.extended(
          heroTag: 'fab_dosing_calc',
          onPressed: () => _showCalcAndRecordSheet(context, tank),
          icon: const Icon(Icons.calculate_outlined),
          label: Text(l10n.calculateAndRecord),
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
        ),
        const SizedBox(height: 10),
        // Quick Record option
        FloatingActionButton.extended(
          heroTag: 'fab_dosing_record',
          onPressed: () => _showRecordDoseSheet(context, tank),
          icon: const Icon(Icons.add),
          label: Text(l10n.recordDose),
        ),
      ],
    );
  }

  /// Shows a bottom sheet to quickly record a dose using dosing presets
  void _showRecordDoseSheet(
    BuildContext context,
    Tank tank, {
    DosingEntry? existingEntry,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RecordDoseSheet(
        tank: tank,
        existingEntry: existingEntry,
      ),
    );
  }

  /// Shows a bottom sheet to calculate a dose for a tank and record it
  void _showCalcAndRecordSheet(BuildContext context, Tank tank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CalcAndRecordDoseSheet(tank: tank),
    );
  }

  /// Upcoming Notifications tab - Shows enabled notifications sorted by next date
  Widget _buildUpcomingNotificationsTab(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Filter to enabled notifications and sort by next scheduled date
    final enabledNotifications = tank.notifications
        .where((n) => n.enabled)
        .toList()
      ..sort((a, b) {
        final aDate = a.getImmediateNextDate();
        final bDate = b.getImmediateNextDate();
        return aDate.compareTo(bDate);
      });

    if (enabledNotifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: cs.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noUpcomingNotifications,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noUpcomingNotificationsDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.notifications_outlined),
                label: Text(l10n.manageNotifications),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationManagementScreen(tank: tank),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        // Navigate to full notification management screen
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications_outlined),
          label: Text(l10n.manageNotifications),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  NotificationManagementScreen(tank: tank),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 12),
        ...enabledNotifications.map((notification) {
          return _buildUpcomingNotificationCard(
            context,
            tank,
            notification,
          );
        }),
      ],
    );
  }

  /// Builds a card for an upcoming notification with reschedule and quick-log actions
  Widget _buildUpcomingNotificationCard(
    BuildContext context,
    Tank tank,
    TankNotification notification,
  ) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final DateTime displayDate = notification.getImmediateNextDate();
    final now = DateTime.now();
    final isOverdue = displayDate.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.customTitle ??
                            notification.getDisplayName(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(displayDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOverdue
                              ? cs.error
                              : cs.onSurface.withOpacity(0.6),
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (notification.notes != null &&
                notification.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notification.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (notification.repeatFrequency != RepeatFrequency.none)
                  Chip(
                    label: Text(
                      _getUpcomingRepeatText(notification),
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                if (isOverdue)
                  Chip(
                    label: Text(
                      AppLocalizations.of(context)!.overdue,
                      style: TextStyle(fontSize: 12, color: cs.onError),
                    ),
                    backgroundColor: cs.error,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Builder(
                    builder: (context) {
                      final timeText = _getUpcomingTimeFromNow(displayDate);
                      if (timeText == null) return const SizedBox.shrink();
                      return Chip(
                        label: Text(
                          timeText,
                          style: const TextStyle(fontSize: 12),
                        ),
                        avatar: const Icon(Icons.schedule, size: 16),
                        backgroundColor: cs.secondaryContainer,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons: Quick Log + Reschedule
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _quickLogFromUpcoming(tank, notification),
                    icon: const Icon(Icons.add_task, size: 18),
                    label: Text(AppLocalizations.of(context)!.quickLog),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _getNotificationColor(notification.type),
                      side: BorderSide(
                        color: _getNotificationColor(notification.type)
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _rescheduleFromUpcoming(tank, notification),
                    icon: const Icon(Icons.update, size: 18),
                    label: Text(AppLocalizations.of(context)!.reschedule),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(
                        color: cs.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Quick log an activity from the upcoming notifications tab
  Future<void> _quickLogFromUpcoming(
    Tank tank,
    TankNotification notification,
  ) async {
    final currentTank = _getCurrentTank();
    final notificationService = NotificationService();

    // Create a new log entry based on the notification type
    final log = NotificationLog.create(
      type: notification.type,
      customCategory: notification.type == NotificationType.other
          ? (notification.customCategory ?? 'Other')
          : null,
      notes: notification.notes,
      notificationId: notification.id,
    );

    final updatedLogs = [...currentTank.notificationLogs, log];

    // Reschedule matching notifications based on the new activity
    final updatedNotifications = await notificationService
        .rescheduleMatchingNotifications(
          tankId: currentTank.id,
          tankName: currentTank.name,
          notifications: currentTank.notifications,
          activityLogs: updatedLogs,
          activityType: log.type,
          activityCustomCategory: log.customCategory,
        );

    // Update the tank with new activity logs and updated notifications
    var updatedTank = currentTank.copyWith(
      notificationLogs: updatedLogs,
      updatedAt: DateTime.now(),
    );

    // Apply the updated notifications with new scheduledNextDate
    if (updatedNotifications.isNotEmpty) {
      final notificationsList = updatedTank.notifications.map((n) {
        final updated = updatedNotifications.firstWhere(
          (u) => u.id == n.id,
          orElse: () => n,
        );
        return updated;
      }).toList();
      updatedTank = updatedTank.copyWith(notifications: notificationsList);
    }

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(l10n.activityLogged);
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'quick_log_from_upcoming',
      parameters: {'type': notification.type.name},
    );
  }

  /// Reschedule a notification from the upcoming notifications tab
  Future<void> _rescheduleFromUpcoming(
    Tank tank,
    TankNotification notification,
  ) async {
    final option = await NotificationRescheduleDialog.show(
      context,
      notification,
    );

    if (option == null || !mounted) return;

    final currentTank = _getCurrentTank();
    final notificationService = NotificationService();

    TankNotification updatedNotification;
    switch (option) {
      case RescheduleOption.rescheduleFromNow:
        final nextDate = notification.getNextNotificationDateFromBase(
          DateTime.now(),
          useCurrentTime: true,
        );
        updatedNotification = notification.copyWith(
          scheduledNextDate: nextDate,
          updatedAt: DateTime.now(),
        );
        break;
      case RescheduleOption.keepOriginal:
        final nextDate = notification.getNextNotificationDateFromBase(
          DateTime.now(),
          useCurrentTime: false,
        );
        updatedNotification = notification.copyWith(
          scheduledNextDate: nextDate,
          updatedAt: DateTime.now(),
        );
        break;
      case RescheduleOption.doNothing:
      case RescheduleOption.cancelAll:
        return;
    }

    // Update the notification in the tank
    final updatedNotifications = currentTank.notifications
        .map((n) => n.id == notification.id ? updatedNotification : n)
        .toList();

    final updatedTank = currentTank.copyWith(
      notifications: updatedNotifications,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    // Re-schedule the platform notification
    await notificationService.scheduleNotification(
      tankId: currentTank.id,
      tankName: currentTank.name,
      notification: updatedNotification,
      activityLogs: currentTank.notificationLogs,
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(l10n.notificationUpdated);
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'reschedule_from_upcoming',
      parameters: {
        'type': notification.type.name,
        'option': option.name,
      },
    );
  }

  /// Get notification icon for upcoming tab
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Icons.restaurant;
      case NotificationType.dosing:
        return Icons.medication_liquid;
      case NotificationType.waterChange:
        return Icons.water_drop;
      case NotificationType.testing:
        return Icons.science;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.other:
        return Icons.notifications;
    }
  }

  /// Get notification color for upcoming tab
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Colors.orange;
      case NotificationType.dosing:
        return Colors.purple;
      case NotificationType.waterChange:
        return Colors.blue;
      case NotificationType.testing:
        return Colors.teal;
      case NotificationType.maintenance:
        return Colors.brown;
      case NotificationType.other:
        return Colors.grey;
    }
  }

  /// Get repeat text for upcoming notification cards
  String _getUpcomingRepeatText(TankNotification notification) {
    final l10n = AppLocalizations.of(context)!;

    if (notification.repeatInterval == 1) {
      return notification.repeatFrequency.displayName;
    }

    final String unitName;
    switch (notification.repeatFrequency) {
      case RepeatFrequency.daily:
        unitName = l10n.days;
        break;
      case RepeatFrequency.weekly:
        unitName = l10n.weeks;
        break;
      case RepeatFrequency.monthly:
        unitName = l10n.months;
        break;
      case RepeatFrequency.yearly:
        unitName = l10n.years;
        break;
      default:
        return notification.repeatFrequency.displayName;
    }

    return l10n.everyXDays(notification.repeatInterval, unitName);
  }

  /// Get time-from-now text for upcoming notification cards
  String? _getUpcomingTimeFromNow(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    final l10n = AppLocalizations.of(context)!;

    if (difference.isNegative) return null;

    final days = difference.inDays;
    final hours = difference.inHours;
    final minutes = difference.inMinutes;

    if (days > 0) {
      if (days == 1) return l10n.inLessThan2Days;
      return l10n.inXDays(days);
    } else if (hours > 0) {
      if (hours == 1) return l10n.inLessThan2Hours;
      return l10n.inXHours(hours);
    } else if (minutes > 0) {
      if (minutes == 1) return l10n.inOneMinute;
      return l10n.inXMinutes(minutes);
    } else {
      return l10n.inLessThanAMinute;
    }
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

    // All activity logs, newest first
    final allLogs = tank.notificationLogs.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Navigation banner → full NotificationLoggerScreen (activity tab)
        OutlinedButton.icon(
          icon: const Icon(Icons.history),
          label: Text(l10n.openActivityLog),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NotificationLoggerScreen(
                tank: tank,
                initialTabIndex: 1,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          '${l10n.recentActivity} (${allLogs.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...allLogs.map((log) {
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: Icon(_getActivityIcon(log.type), color: cs.primary),
              ),
              title: Text(log.getDisplayName()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMd().add_jm().format(log.loggedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (log.notes != null && log.notes!.isNotEmpty)
                    Text(
                      log.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
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
        // Navigation banner → full NotificationLoggerScreen (notes tab)
        OutlinedButton.icon(
          icon: const Icon(Icons.note_outlined),
          label: Text(l10n.openNotesLog),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NotificationLoggerScreen(
                tank: tank,
                initialTabIndex: 0,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 12),

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
    final appSettings = ref.watch(appSettingsProvider);

    Color scoreColor;
    if (score >= 0.8) {
      scoreColor = Colors.green;
    } else if (score >= 0.6) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    // Delta chip
    Widget? deltaChip;
    if (!appSettings.tankHideHarmonyDelta &&
        tank.previousHarmonyScore != null) {
      final delta = score - tank.previousHarmonyScore!;
      if (delta.abs() >= 0.005) {
        final sign = delta > 0 ? '+' : '';
        final deltaStr = '$sign${(delta * 100).toStringAsFixed(0)}%';
        final deltaColor =
            delta > 0 ? Colors.green.shade700 : Colors.red.shade700;
        deltaChip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: deltaColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: deltaColor.withOpacity(0.4)),
          ),
          child: Text(
            deltaStr,
            style: TextStyle(
              fontSize: 12,
              color: deltaColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    final chip = Container(
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

    if (deltaChip == null) return chip;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [chip, const SizedBox(width: 6), deltaChip],
    );
  }

  /// Formats a duration (since a date) as "X years Y months old".
  String _formatAge(BuildContext context, DateTime since) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    int years = now.year - since.year;
    int months = now.month - since.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    // Use compact "Xy Zm" format via l10n, but show words when years or
    // months are zero so the chip reads more naturally.
    if (years == 0 && months == 0) return '<1m';
    return l10n.ageYearsMonths(years, months);
  }

  Widget _buildTankAgeChip(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ageText = _formatAge(context, tank.createdAt);
    if (ageText.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${l10n.tankAge}: $ageText',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
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

  /// Returns the emoji representing this tank's type/subtype.
  String _tankTypeEmoji(Tank tank) {
    if (tank.type == 'freshwater') {
      if (tank.freshwaterSubtype == 'planted') return '🌿';
      if (tank.freshwaterSubtype == 'brackish') return '🦀';
      return '🐟'; // plain freshwater
    }
    if (tank.isReef) return '🪸';
    return '🌊'; // plain marine/saltwater
  }

  /// Returns the substrate lbs-per-gallon midpoint for the given tank's type.
  /// Planted freshwater uses 2–3 lbs/gal (mid: 2.5); all others use 1–2 (mid: 1.5).
  double _substrateRecLbsPerGallon(Tank tank) {
    if (tank.type == 'freshwater' && tank.freshwaterSubtype == 'planted') {
      return 2.5; // mid of Planted range (2–3 lbs/gal)
    }
    return 1.5; // mid of Standard range (1–2 lbs/gal)
  }

  Widget _buildSubstrateChip(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;

    // Use override if set, otherwise calculate from tank size
    String label;
    if (tank.substrateOverrideLbs != null) {
      label = l10n.substrateCustomLbs(tank.substrateOverrideLbs!.round());
    } else {
      final lbsPerGal = _substrateRecLbsPerGallon(tank);
      if (tank.sizeGallons != null) {
        final recLbs = (tank.sizeGallons! * lbsPerGal).round();
        label = l10n.substrateRecommendedLbs(recLbs);
      } else if (tank.sizeLiters != null) {
        // Substrate bulk density: 100 lbs/ft³ (standard gravel); 1 ft³ = 28.3168 L
        const double lbsPerLiterSubstrate = 100.0 / 28.3168;
        final gallons = tank.sizeLiters! / 3.78541;
        final recLbs = gallons * lbsPerGal;
        final recSubLiters = (recLbs / lbsPerLiterSubstrate).round();
        label = l10n.substrateRecommendedLiters(recSubLiters);
      } else {
        return const SizedBox.shrink();
      }
    }

    final cs = Theme.of(context).colorScheme;
    final hasOverride = tank.substrateOverrideLbs != null;
    return GestureDetector(
      onTap: () => _showSubstrateOverrideDialog(context, tank),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasOverride
              ? cs.tertiaryContainer.withOpacity(0.7)
              : cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasOverride
                ? cs.tertiary.withOpacity(0.6)
                : cs.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers,
              size: 16,
              color: hasOverride
                  ? cs.tertiary
                  : cs.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: hasOverride ? cs.onTertiaryContainer : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 12,
              color: hasOverride
                  ? cs.tertiary
                  : cs.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubstrateOverrideDialog(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: tank.substrateOverrideLbs != null
          ? tank.substrateOverrideLbs!.toStringAsFixed(1)
          : '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.substrateOverrideTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.substrateOverrideBody,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.substrateOverrideFieldLabel,
                  suffixText: 'lbs',
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            if (tank.substrateOverrideLbs != null)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final updated = tank.copyWith(
                    clearSubstrateOverrideLbs: true,
                    updatedAt: DateTime.now(),
                  );
                  ref.read(tankProvider.notifier).updateTank(updated);
                },
                child: Text(l10n.substrateOverrideClear),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value != null && value > 0) {
                  Navigator.of(ctx).pop();
                  final updated = tank.copyWith(
                    substrateOverrideLbs: value,
                    updatedAt: DateTime.now(),
                  );
                  ref.read(tankProvider.notifier).updateTank(updated);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
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
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TankInhabitantScreen(
                        tank: tank,
                        inhabitant: inhabitant,
                        availableFish: fishData[tank.type] ?? const [],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
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
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            tag,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color:
                                                      cs.onSecondaryContainer,
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
                                      color:
                                          cs.onSurfaceVariant.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: cs.onSurface.withOpacity(0.35),
                      ),
                    ],
                  ),
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

// ════════════════════════════════════════════════════════════════════════════
// ── Volume units for dosing entries ────────────────────────────────────────
// ════════════════════════════════════════════════════════════════════════════

const List<String> _kDosingVolumeUnits = [
  'mL',
  'L',
  'oz',
  'tsp',
  'tbsp',
  'drops',
  'g',
  'gal',
  'cups',
];

// ════════════════════════════════════════════════════════════════════════════
// ── Record Dose Bottom Sheet ──────────────────────────────────────────────
// ════════════════════════════════════════════════════════════════════════════

/// A bottom sheet for quickly recording a dose using dosing presets.
/// Replaces the old DosingLoggerScreen's _AddDosingEntrySheet.
class _RecordDoseSheet extends ConsumerStatefulWidget {
  final Tank tank;
  final DosingEntry? existingEntry;

  const _RecordDoseSheet({required this.tank, this.existingEntry});

  @override
  ConsumerState<_RecordDoseSheet> createState() => _RecordDoseSheetState();
}

class _RecordDoseSheetState extends ConsumerState<_RecordDoseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _customNameController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedUnit;
  String? _selectedPresetId; // null = not chosen, 'custom' = custom entry

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _amountController.text = entry.amount.toString();
      _notesController.text = entry.notes ?? '';
      _selectedDate = entry.dateDosed;
      _selectedUnit = entry.unit;
      // Try to match existing entry to a preset
      final presets = ref.read(dosingPresetsProvider);
      final matchedPreset = presets.where(
        (p) => p.name == entry.treatmentName,
      );
      if (matchedPreset.isNotEmpty) {
        _selectedPresetId = matchedPreset.first.id;
      } else {
        _selectedPresetId = 'custom';
        _customNameController.text = entry.treatmentName;
      }
    } else {
      _selectedDate = DateTime.now();
      _selectedUnit = 'mL';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  String _getTreatmentName() {
    if (_selectedPresetId == 'custom') {
      return _customNameController.text.trim();
    }
    final presets = ref.read(dosingPresetsProvider);
    try {
      return presets.firstWhere((p) => p.id == _selectedPresetId).name;
    } catch (_) {
      return _customNameController.text.trim();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;
    final isEditing = widget.existingEntry != null;
    final treatmentName = _getTreatmentName();
    final amount = double.parse(_amountController.text);
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    // Get current tank from provider for latest state
    final tanks = ref.read(tankProvider).tanks;
    final currentTank = tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );

    if (isEditing) {
      final entry = widget.existingEntry!.copyWith(
        treatmentName: treatmentName,
        amount: amount,
        unit: _selectedUnit,
        dateDosed: _selectedDate,
        notes: notes,
      );
      final updatedEntries = currentTank.dosingEntries.map((e) {
        return e.id == entry.id ? entry : e;
      }).toList();
      final updatedTank = currentTank.copyWith(
        dosingEntries: updatedEntries,
        updatedAt: DateTime.now(),
      );
      ref.read(tankProvider.notifier).updateTank(updatedTank);
      AnalyticsService.logFeatureUsed(
        featureName: 'dosing_entry_updated',
        parameters: {
          'treatment_name': treatmentName,
          'tank_type': currentTank.type,
          'unit': _selectedUnit,
        },
      );
    } else {
      final entry = DosingEntry.create(
        treatmentName: treatmentName,
        amount: amount,
        unit: _selectedUnit,
        dateDosed: _selectedDate,
        notes: notes,
      );
      final updatedEntries = [...currentTank.dosingEntries, entry];
      final updatedTank = currentTank.copyWith(
        dosingEntries: updatedEntries,
        updatedAt: DateTime.now(),
      );
      ref.read(tankProvider.notifier).updateTank(updatedTank);
      AnalyticsService.logFeatureUsed(
        featureName: 'dosing_entry_added',
        parameters: {
          'treatment_name': treatmentName,
          'tank_type': currentTank.type,
          'unit': _selectedUnit,
          'has_notes': notes != null ? 'true' : 'false',
        },
      );
      AnalyticsService.logTankAction(
        action: 'dosing_entry_added',
        tankType: currentTank.type,
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.dosingRecordedSnack),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existingEntry != null;
    final presets = ref.watch(dosingPresetsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      isEditing ? l10n.dosingRecordUpdate : l10n.dosingRecordTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product preset dropdown
              DropdownButtonFormField<String>(
                value: _selectedPresetId,
                decoration: InputDecoration(
                  labelText: '${l10n.dosingProduct} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medication_outlined),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                items: [
                  ...presets.map((preset) {
                    return DropdownMenuItem(
                      value: preset.id,
                      child: Row(
                        children: [
                          Icon(
                            dosingIconFromName(preset.iconName),
                            size: 18,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Text(preset.name, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.dosingCustomProduct, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPresetId = value;
                    if (value != 'custom') {
                      _customNameController.clear();
                      // Auto-set unit from preset
                      try {
                        final preset =
                            presets.firstWhere((p) => p.id == value);
                        _selectedUnit = preset.unit;
                      } catch (_) {}
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return l10n.validationSelectProduct;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom name (shown only when "Custom" is selected)
              if (_selectedPresetId == 'custom') ...[
                TextFormField(
                  controller: _customNameController,
                  decoration: InputDecoration(
                    labelText: '${l10n.dosingCustomProductName} *',
                    hintText: l10n.dosingCustomProductName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (_selectedPresetId == 'custom' &&
                        (value == null || value.trim().isEmpty)) {
                      return l10n.validationEnterProductName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Amount and unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: '${l10n.dosingAmount} *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.science),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.validationRequired;
                        }
                        if (double.tryParse(value) == null) {
                          return l10n.validationInvalidNumber;
                        }
                        if (double.parse(value) <= 0) {
                          return l10n.validationMustBePositive;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: l10n.doseUnit,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                      ),
                      items: _kDosingVolumeUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUnit = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date & Time
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.dosingDateLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy - h:mm a').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.dosingNotes,
                  hintText: l10n.dosingNotesHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isEditing ? l10n.dosingRecordUpdate : l10n.dosingRecordSave,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ── Calculate & Record Dose Bottom Sheet ──────────────────────────────────
// ════════════════════════════════════════════════════════════════════════════

/// A bottom sheet that integrates the dosing calculator and then records the
/// calculated dose as a dosing entry on the tank.
class _CalcAndRecordDoseSheet extends ConsumerStatefulWidget {
  final Tank tank;

  const _CalcAndRecordDoseSheet({required this.tank});

  @override
  ConsumerState<_CalcAndRecordDoseSheet> createState() =>
      _CalcAndRecordDoseSheetState();
}

class _CalcAndRecordDoseSheetState
    extends ConsumerState<_CalcAndRecordDoseSheet> {
  // ── Calculator state ─────────────────────────────────────────────────────
  String _volumeUnit = 'Gallons';
  String? _selectedPresetId;
  final _tankSizeController = TextEditingController();
  final _doseAmountController = TextEditingController();
  final _dosePerVolumeController = TextEditingController();
  final _notesController = TextEditingController();
  double? _totalDose;
  String _resultUnit = 'mL';

  @override
  void initState() {
    super.initState();
    // Auto-fill tank size from tank settings
    final tank = widget.tank;
    if (tank.sizeGallons != null && tank.sizeGallons! > 0) {
      _tankSizeController.text = _formatNumber(tank.sizeGallons!);
      _volumeUnit = 'Gallons';
    } else if (tank.sizeLiters != null && tank.sizeLiters! > 0) {
      _tankSizeController.text = _formatNumber(tank.sizeLiters!);
      _volumeUnit = 'Liters';
    }
  }

  @override
  void dispose() {
    _tankSizeController.dispose();
    _doseAmountController.dispose();
    _dosePerVolumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  DosingPreset? _findPreset(List<DosingPreset> presets, String? id) {
    if (id == null || id == 'custom') return null;
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _selectPreset(String? id) {
    final presets = ref.read(dosingPresetsProvider);
    setState(() {
      _selectedPresetId = id;
      _totalDose = null;
      if (id != null && id != 'custom') {
        final preset = _findPreset(presets, id);
        if (preset != null) {
          if (_volumeUnit == 'Gallons') {
            _doseAmountController.text =
                _formatNumber(preset.doseAmountGal);
            _dosePerVolumeController.text =
                _formatNumber(preset.perVolumeGal);
          } else {
            _doseAmountController.text =
                _formatNumber(preset.doseAmountLiter);
            _dosePerVolumeController.text =
                _formatNumber(preset.perVolumeLiter);
          }
          _resultUnit = preset.unit;
        }
      } else if (id == 'custom') {
        _doseAmountController.clear();
        _dosePerVolumeController.clear();
        _resultUnit = 'mL';
      }
    });
  }

  void _calculate() {
    final tankSize = double.tryParse(_tankSizeController.text);
    final doseAmount = double.tryParse(_doseAmountController.text);
    final perVolume = double.tryParse(_dosePerVolumeController.text);

    if (tankSize == null ||
        tankSize <= 0 ||
        doseAmount == null ||
        doseAmount <= 0 ||
        perVolume == null ||
        perVolume <= 0) {
      setState(() => _totalDose = null);
      return;
    }

    AnalyticsService.logCalculatorUsed(
      calculatorType: 'dosing',
      inputData: {
        'preset': _selectedPresetId ?? 'none',
        'volume_unit': _volumeUnit,
        'source': 'tank_details',
      },
    );

    setState(() {
      _totalDose = (doseAmount / perVolume) * tankSize;
    });
  }

  void _recordCalculatedDose() {
    if (_totalDose == null || _selectedPresetId == null) return;

    final presets = ref.read(dosingPresetsProvider);
    final selectedPreset = _findPreset(presets, _selectedPresetId);
    final treatmentName =
        selectedPreset?.name ?? AppLocalizations.of(context)!.dosingCustomProduct;

    final tanks = ref.read(tankProvider).tanks;
    final currentTank = tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );

    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final entry = DosingEntry.create(
      treatmentName: treatmentName,
      amount: double.parse(_totalDose!.toStringAsFixed(2)),
      unit: _resultUnit,
      dateDosed: DateTime.now(),
      notes: notes,
    );

    final updatedEntries = [...currentTank.dosingEntries, entry];
    final updatedTank = currentTank.copyWith(
      dosingEntries: updatedEntries,
      updatedAt: DateTime.now(),
    );
    ref.read(tankProvider.notifier).updateTank(updatedTank);

    AnalyticsService.logFeatureUsed(
      featureName: 'dosing_entry_added',
      parameters: {
        'treatment_name': treatmentName,
        'tank_type': currentTank.type,
        'unit': _resultUnit,
        'source': 'calculator',
      },
    );
    AnalyticsService.logTankAction(
      action: 'dosing_entry_added',
      tankType: currentTank.type,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.dosingRecordedSnack),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPresetPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final presets = ref.read(dosingPresetsProvider);

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.science_outlined, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.dosingPresetTitle,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      ...presets.map((preset) {
                        final isSelected = _selectedPresetId == preset.id;
                        final unitAbbrev = _volumeUnit == 'Gallons'
                            ? l10n.dosingGalAbbrev
                            : l10n.dosingLAbbrev;
                        final doseAmt = _volumeUnit == 'Gallons'
                            ? preset.doseAmountGal
                            : preset.doseAmountLiter;
                        final perVol = _volumeUnit == 'Gallons'
                            ? preset.perVolumeGal
                            : preset.perVolumeLiter;
                        final subtitle =
                            '${_formatNumber(doseAmt)} ${preset.unit} per ${_formatNumber(perVol)} $unitAbbrev';

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              dosingIconFromName(preset.iconName),
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            preset.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: Theme.of(ctx)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: cs.primary, size: 22)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => Navigator.pop(ctx, preset.id),
                        );
                      }),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedPresetId == 'custom'
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: _selectedPresetId == 'custom'
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          l10n.dosingPresetCustom,
                          style: TextStyle(
                            fontWeight: _selectedPresetId == 'custom'
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _selectedPresetId == 'custom'
                                ? cs.primary
                                : cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          l10n.dosingCustomSubtitle,
                          style: Theme.of(ctx)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        trailing: _selectedPresetId == 'custom'
                            ? Icon(Icons.check_circle,
                                color: cs.primary, size: 22)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => Navigator.pop(ctx, 'custom'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: cs.primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          l10n.dosingAddNewProduct,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                        subtitle: Text(
                          l10n.dosingAddNewProductSubtitle,
                          style: Theme.of(ctx)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          showDosingPresetEditorDialog(context, ref)
                              .then((newPresetId) {
                            if (newPresetId != null) {
                              _selectPreset(newPresetId);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
        _selectPreset(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final presets = ref.watch(dosingPresetsProvider);
    final selectedPreset = _findPreset(presets, _selectedPresetId);

    // Build the current preset display label
    final String presetDisplayLabel;
    if (_selectedPresetId == null) {
      presetDisplayLabel = l10n.dosingSelectProduct;
    } else if (_selectedPresetId == 'custom') {
      presetDisplayLabel = l10n.dosingPresetCustom;
    } else {
      presetDisplayLabel = selectedPreset?.name ?? l10n.dosingPresetCustom;
    }

    final bool isCustom =
        _selectedPresetId == null || _selectedPresetId == 'custom';

    // Dose description for the selected preset
    String? presetDoseDescription;
    if (selectedPreset != null) {
      final unitAbbrev = _volumeUnit == 'Gallons'
          ? l10n.dosingGalAbbrev
          : l10n.dosingLAbbrev;
      final doseAmt = _volumeUnit == 'Gallons'
          ? selectedPreset.doseAmountGal
          : selectedPreset.doseAmountLiter;
      final perVol = _volumeUnit == 'Gallons'
          ? selectedPreset.perVolumeGal
          : selectedPreset.perVolumeLiter;
      presetDoseDescription =
          '${_formatNumber(doseAmt)} ${selectedPreset.unit} per ${_formatNumber(perVol)} $unitAbbrev';
    }

    // Format the dose result
    final String? formattedDose = _totalDose != null
        ? (_totalDose! == _totalDose!.roundToDouble()
            ? _totalDose!.toStringAsFixed(1)
            : _totalDose!.toStringAsFixed(2))
        : null;

    final bool showTsp =
        _totalDose != null && _resultUnit == 'mL' && _totalDose! >= 1;
    final String tspValue =
        showTsp ? (_totalDose! / 5).toStringAsFixed(2) : '';
    final bool showCaps =
        _totalDose != null && _resultUnit == 'mL' && _totalDose! >= 5;
    final String capValue =
        showCaps ? (_totalDose! / 5).toStringAsFixed(1) : '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l10n.dosingCalcRecordTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dosingCalculatorSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 16),

            // ── Volume unit toggle ────────────────────────────────────────
            Row(
              children: [
                Text(
                  l10n.units,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'Gallons',
                      label: Text(l10n.gallons),
                    ),
                    ButtonSegment(
                      value: 'Liters',
                      label: Text(l10n.liters),
                    ),
                  ],
                  selected: {_volumeUnit},
                  onSelectionChanged: (value) {
                    setState(() {
                      _volumeUnit = value.first;
                      _totalDose = null;
                      // Update tank size for the other unit
                      final tank = widget.tank;
                      if (_volumeUnit == 'Gallons' &&
                          tank.sizeGallons != null &&
                          tank.sizeGallons! > 0) {
                        _tankSizeController.text =
                            _formatNumber(tank.sizeGallons!);
                      } else if (_volumeUnit == 'Liters' &&
                          tank.sizeLiters != null &&
                          tank.sizeLiters! > 0) {
                        _tankSizeController.text =
                            _formatNumber(tank.sizeLiters!);
                      }
                    });
                    if (_selectedPresetId != null &&
                        _selectedPresetId != 'custom') {
                      _selectPreset(_selectedPresetId!);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Product preset selector ───────────────────────────────────
            InkWell(
              onTap: () => _showPresetPicker(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: selectedPreset != null
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedPreset != null
                        ? cs.primary.withOpacity(0.5)
                        : cs.outline.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedPreset != null
                          ? dosingIconFromName(selectedPreset.iconName)
                          : Icons.science_outlined,
                      color: selectedPreset != null
                          ? cs.primary
                          : cs.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            presetDisplayLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: selectedPreset != null
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface,
                                ),
                          ),
                          if (presetDoseDescription != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              presetDoseDescription,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onPrimaryContainer
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: selectedPreset != null
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tank size input ───────────────────────────────────────────
            TextField(
              controller: _tankSizeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.dosingTankSize,
                hintText:
                    _volumeUnit == 'Gallons' ? 'e.g. 55' : 'e.g. 200',
                suffixText:
                    _volumeUnit == 'Gallons' ? l10n.gallons : l10n.liters,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.water_outlined),
                helperText: (widget.tank.sizeGallons != null ||
                        widget.tank.sizeLiters != null)
                    ? l10n.dosingTankSizeAutoFilled
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── Dose amount / per volume ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doseAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.dosingDoseAmountLabel,
                      hintText: 'e.g. 5',
                      suffixText: _resultUnit,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.science_outlined),
                    ),
                    enabled: isCustom,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.dosingPer,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _dosePerVolumeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _volumeUnit == 'Gallons'
                          ? l10n.gallons
                          : l10n.liters,
                      hintText: 'e.g. 50',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.straighten_outlined),
                    ),
                    enabled: isCustom,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Notes (optional) ──────────────────────────────────────────
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.dosingNotes,
                hintText: l10n.dosingNotesHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // ── Calculate button ──────────────────────────────────────────
            if (_totalDose == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_outlined),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  label: Text(
                    l10n.dosingCalculateFirst,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // ── Results + Record button ───────────────────────────────────
            if (_totalDose != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science_rounded,
                            color: cs.primary, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.dosingResultTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedPreset != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.dosingResultProduct(selectedPreset.name),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  cs.onPrimaryContainer.withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      '$formattedDose $_resultUnit',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (showTsp) ...[
                      const SizedBox(height: 4),
                      Text(
                        '≈ $tspValue ${l10n.dosingTeaspoons}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color:
                                  cs.onPrimaryContainer.withOpacity(0.8),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (showCaps) ...[
                      const SizedBox(height: 2),
                      Text(
                        '≈ $capValue ${l10n.dosingCapfuls}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color:
                                  cs.onPrimaryContainer.withOpacity(0.8),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _recordCalculatedDose,
                  icon: const Icon(Icons.save),
                  label: Text(l10n.dosingRecordCalculated),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Recalculate link
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _totalDose = null),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.dosingCalculateFirst),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
