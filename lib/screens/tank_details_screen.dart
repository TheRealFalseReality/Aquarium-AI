import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tank.dart';
import '../models/fish.dart';
import '../models/water_parameter.dart';
import '../models/dosing_entry.dart';
import '../models/notification_log.dart';
import '../models/tank_notification.dart';
import '../utils/tank_harmony_calculator.dart';
import '../l10n/app_localizations.dart';
import 'tank_creation_screen.dart';
import 'parameter_logger_screen.dart';
import 'dosing_logger_screen.dart';
import 'notification_management_screen.dart';
import 'notification_logger_screen.dart';
import 'photo_analysis_screen.dart';

class TankDetailsScreen extends ConsumerStatefulWidget {
  final Tank tank;
  final Map<String, List<Fish>>? fishData;

  const TankDetailsScreen({
    super.key,
    required this.tank,
    this.fishData,
  });

  @override
  TankDetailsScreenState createState() => TankDetailsScreenState();
}

class TankDetailsScreenState extends ConsumerState<TankDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    // AI-inspired gradient colors based on tank type
    final gradientColors = widget.tank.type == 'freshwater'
        ? [
            Colors.blue.shade400.withOpacity(0.15),
            Colors.cyan.shade300.withOpacity(0.15),
          ]
        : [
            Colors.indigo.shade400.withOpacity(0.15),
            Colors.purple.shade300.withOpacity(0.15),
          ];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.tank.type == 'freshwater'
                          ? [Colors.blue.shade400, Colors.cyan.shade300]
                          : [Colors.indigo.shade400, Colors.purple.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  widget.tank.type == 'freshwater'
                                      ? Icons.water_drop
                                      : Icons.waves,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.tank.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      widget.tank.type == 'freshwater'
                                          ? 'Freshwater Tank'
                                          : 'Saltwater Tank',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: isMobile,
                  tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
                  tabs: const [
                    Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 20)),
                    Tab(text: 'Inhabitants', icon: Icon(Icons.pets, size: 20)),
                    Tab(text: 'Parameters', icon: Icon(Icons.science_outlined, size: 20)),
                    Tab(text: 'Activity', icon: Icon(Icons.history, size: 20)),
                    Tab(text: 'Dosing', icon: Icon(Icons.medication_liquid, size: 20)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, cs),
              _buildInhabitantsTab(context, cs),
              _buildParametersTab(context, cs, l10n),
              _buildActivityTab(context, cs, l10n),
              _buildDosingTab(context, cs, l10n),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TankCreationScreen(existingTank: widget.tank),
            ),
          );
        },
        icon: const Icon(Icons.edit),
        label: Text(l10n.editTank),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (widget.tank.sizeGallons != null || widget.tank.sizeLiters != null)
                _buildStatChip(context, Icons.straighten, _formatTankSize(widget.tank)),
              if (widget.tank.sizeGallons != null || widget.tank.sizeLiters != null)
                _buildStatChip(context, Icons.line_weight, _formatWaterWeight(widget.tank)),
              if (widget.tank.inhabitants.isNotEmpty && widget.fishData != null)
                _buildHarmonyScoreChip(widget.tank),
            ],
          ),

          const SizedBox(height: 20),

          // Tank photos section
          if (widget.tank.photos.isNotEmpty) ...[
            _buildSectionCard(
              context,
              cs,
              title: 'Tank Photos (${widget.tank.photos.length})',
              icon: Icons.photo_library_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tank.photos.map((photo) {
                  final imageUrl = photo.imageUrl ?? photo.imagePath;
                  return GestureDetector(
                    onTap: () => _showPhotoMaximized(context, photo),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.outline, width: 2),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: imageUrl != null
                                ? (imageUrl.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: cs.errorContainer,
                                          child: Icon(
                                            Icons.error_outline,
                                            color: cs.onErrorContainer,
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
                                    color: cs.surfaceVariant,
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(6),
                                  bottomRight: Radius.circular(6),
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
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes section
          if (widget.tank.notes != null && widget.tank.notes!.isNotEmpty) ...[
            _buildSectionCard(
              context,
              cs,
              title: 'Notes',
              icon: Icons.note_outlined,
              child: Text(
                widget.tank.notes!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Calculation Breakdown
          if (widget.tank.inhabitants.isNotEmpty && widget.fishData != null) ...[
            _buildSectionCard(
              context,
              cs,
              title: 'Compatibility Calculation',
              icon: Icons.calculate,
              isExpandable: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.tank.calculationBreakdown ?? 'No calculation available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Dates
          _buildSectionCard(
            context,
            cs,
            title: 'Tank Information',
            icon: Icons.info_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Created ${_formatDate(widget.tank.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (widget.tank.updatedAt != widget.tank.createdAt) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.update, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'Updated ${_formatDate(widget.tank.updatedAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildParametersTab(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.tank.waterParameters.isNotEmpty) ...[
            _buildSectionCard(
              context,
              cs,
              title: 'Water Parameters',
              icon: Icons.science_outlined,
              action: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ParameterLoggerScreen(tank: widget.tank),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: Text(l10n.manage),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              child: _buildLatestParameters(context, widget.tank, cs),
            ),
          ] else ...[
            _buildEmptyState(
              context,
              cs,
              icon: Icons.water_drop_outlined,
              title: 'No parameters logged yet',
              description: 'Start tracking your water parameters to monitor your aquarium\'s health',
              actionLabel: l10n.addParameter,
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ParameterLoggerScreen(tank: widget.tank),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.tank.notificationLogs.isNotEmpty) ...[
            _buildSectionCard(
              context,
              cs,
              title: l10n.activityLog,
              icon: Icons.history,
              iconColor: Colors.green,
              action: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificationLoggerScreen(tank: widget.tank),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: Text(l10n.manage),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              child: _buildLatestActivityLogs(context, widget.tank, cs),
            ),
          ] else ...[
            _buildEmptyState(
              context,
              cs,
              icon: Icons.history_outlined,
              title: l10n.noActivityLogsYet,
              description: l10n.noActivityLogsDescription,
              actionLabel: l10n.addLogEntry,
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NotificationLoggerScreen(tank: widget.tank),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDosingTab(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.tank.dosingEntries.isNotEmpty) ...[
            _buildSectionCard(
              context,
              cs,
              title: 'Dosing Diary',
              icon: Icons.medication_liquid,
              iconColor: Colors.purple,
              action: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DosingLoggerScreen(tank: widget.tank),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: Text(l10n.manage),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              child: _buildLatestDosingEntries(context, widget.tank, cs),
            ),
          ] else ...[
            _buildEmptyState(
              context,
              cs,
              icon: Icons.medication_liquid_outlined,
              title: 'No dosing entries yet',
              description: 'Start tracking treatments and supplements added to your aquarium',
              actionLabel: l10n.addDose,
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DosingLoggerScreen(tank: widget.tank),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInhabitantsTab(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            context,
            cs,
            title: 'Inhabitants (${_getTotalInhabitantCount(widget.tank.inhabitants)})',
            icon: Icons.pets,
            child: widget.tank.inhabitants.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No inhabitants added yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  )
                : Column(
                    children: widget.tank.inhabitants.map((inhabitant) {
                      final fishImageUrl = _getFishImageUrl(
                        widget.tank.type,
                        inhabitant.fishUnit,
                        widget.fishData,
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
                                  backgroundColor:
                                      fishImageUrl == null ? cs.primaryContainer : null,
                                  child: fishImageUrl == null
                                      ? Icon(
                                          Icons.shape_line,
                                          color: cs.onPrimaryContainer,
                                          size: 22,
                                        )
                                      : null,
                                ),
                                if (inhabitant.quantity > 1)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
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
                                  if (inhabitant.dateAdded != null)
                                    Text(
                                      'Added: ${inhabitant.dateAdded!.month}/${inhabitant.dateAdded!.day}/${inhabitant.dateAdded!.year}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    ColorScheme cs, {
    required String title,
    required IconData icon,
    Color? iconColor,
    Widget? action,
    required Widget child,
    bool isExpandable = false,
  }) {
    if (isExpandable) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, size: 18, color: iconColor ?? cs.onSurfaceVariant),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          children: [child],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: cs.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyScoreChip(Tank tank) {
    final harmonyScore = tank.harmonyScore;
    if (harmonyScore == null) return const SizedBox.shrink();

    final label = TankHarmonyCalculator.getHarmonyLabel(harmonyScore);
    final percentage = (harmonyScore * 100).toStringAsFixed(0);
    
    Color chipColor;
    Color textColor;
    if (harmonyScore >= 0.8) {
      chipColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else if (harmonyScore >= 0.7) {
      chipColor = Colors.yellow.shade100;
      textColor = Colors.yellow.shade800;
    } else if (harmonyScore >= 0.6) {
      chipColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else {
      chipColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shape_line,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$label ($percentage%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTankSize(Tank tank) {
    if (tank.sizeGallons != null && tank.sizeLiters != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gal (${tank.sizeLiters!.toStringAsFixed(0)} L)';
    } else if (tank.sizeGallons != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gallons';
    } else if (tank.sizeLiters != null) {
      return '${tank.sizeLiters!.toStringAsFixed(0)} liters';
    }
    return '';
  }

  String _formatWaterWeight(Tank tank) {
    if (tank.sizeGallons != null && tank.sizeLiters != null) {
      final pounds = tank.sizeGallons! * 8.34;
      final kilograms = tank.sizeLiters!;
      return '${pounds.toStringAsFixed(0)} lbs (${kilograms.toStringAsFixed(0)} kg)';
    } else if (tank.sizeGallons != null) {
      final pounds = tank.sizeGallons! * 8.34;
      return '${pounds.toStringAsFixed(0)} pounds';
    } else if (tank.sizeLiters != null) {
      final kilograms = tank.sizeLiters!;
      return '${kilograms.toStringAsFixed(0)} kilograms';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  int _getTotalInhabitantCount(List<TankInhabitant> inhabitants) {
    return inhabitants.fold(0, (total, inhabitant) => total + inhabitant.quantity);
  }

  String? _getFishImageUrl(
    String tankType,
    String fishUnit,
    Map<String, List<Fish>>? fishData, {
    TankInhabitant? inhabitant,
  }) {
    if (inhabitant != null) {
      if (inhabitant.customImageUrl != null && inhabitant.customImageUrl!.isNotEmpty) {
        return inhabitant.customImageUrl;
      }
      if (inhabitant.customImagePath != null && inhabitant.customImagePath!.isNotEmpty) {
        return inhabitant.customImagePath;
      }
    }
    
    if (fishData == null) return null;
    
    final categoryFish = fishData[tankType] ?? [];
    final fish = categoryFish.firstWhere(
      (f) => f.name == fishUnit,
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

  Widget _buildLatestParameters(BuildContext context, Tank tank, ColorScheme cs) {
    if (tank.waterParameters.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestByType = <String, WaterParameter>{};
    for (var param in tank.waterParameters) {
      if (!latestByType.containsKey(param.parameterType) ||
          param.dateRecorded.isAfter(latestByType[param.parameterType]!.dateRecorded)) {
        latestByType[param.parameterType] = param;
      }
    }

    final paramOrder = tank.type == 'marine'
        ? ['ammonia', 'nitrite', 'nitrate', 'phosphate', 'salinity', 'calcium', 'magnesium', 'iodine', 'kh', 'gh', 'alkalinity', 'orp', 'ph', 'potassium', 'tds']
        : ['ammonia', 'nitrite', 'nitrate', 'phosphate', 'kh', 'gh', 'alkalinity', 'orp', 'ph', 'potassium', 'tds'];
    
    final paramLabels = {
      'ammonia': 'NH3',
      'nitrite': 'NO2',
      'nitrate': 'NO3',
      'phosphate': 'PO4',
      'salinity': 'Sal',
      'calcium': 'Ca',
      'magnesium': 'Mg',
      'kh': 'KH',
      'gh': 'GH',
      'alkalinity': 'Alk',
      'orp': 'ORP',
      'ph': 'pH',
      'potassium': 'K',
      'tds': 'TDS',
      'iodine': 'I',
    };

    final paramIcons = {
      'ammonia': Icons.warning,
      'nitrite': Icons.science,
      'nitrate': Icons.analytics,
      'phosphate': Icons.bubble_chart,
      'salinity': Icons.water,
      'calcium': Icons.diamond,
      'magnesium': Icons.bolt,
      'kh': Icons.shield,
      'gh': Icons.hardware,
      'alkalinity': Icons.balance,
      'orp': Icons.battery_charging_full,
      'ph': Icons.science_outlined,
      'potassium': Icons.spa,
      'tds': Icons.grain,
      'iodine': Icons.ac_unit,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: paramOrder
          .where((type) => latestByType.containsKey(type))
          .map((type) {
        final param = latestByType[type]!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                paramIcons[type] ?? Icons.water_drop,
                size: 14,
                color: cs.primary,
              ),
              const SizedBox(width: 4),
              Text(
                paramLabels[type] ?? type,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${param.value.toStringAsFixed(param.value < 10 ? 1 : 0)}${param.unit ?? ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLatestActivityLogs(BuildContext context, Tank tank, ColorScheme cs) {
    if (tank.notificationLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedLogs = List.from(tank.notificationLogs)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final recentLogs = sortedLogs.take(5).toList();

    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...recentLogs.map((log) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
          final daysDifference = today.difference(logDate).inDays;
          
          final timeAgo = daysDifference == 0
              ? l10n.today
              : daysDifference == 1
                  ? l10n.yesterday
                  : daysDifference < 7
                      ? l10n.daysAgo(daysDifference)
                      : '${log.loggedAt.month}/${log.loggedAt.day}/${log.loggedAt.year}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getActivityIcon(log.type),
                    size: 16,
                    color: _getActivityColor(log.type),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.getDisplayName(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (tank.notificationLogs.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.moreActivities(tank.notificationLogs.length - 5),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLatestDosingEntries(BuildContext context, Tank tank, ColorScheme cs) {
    if (tank.dosingEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = List<DosingEntry>.from(tank.dosingEntries)
      ..sort((a, b) => b.dateDosed.compareTo(a.dateDosed));
    final recentEntries = sortedEntries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...recentEntries.map((entry) {
          final daysSince = DateTime.now().difference(entry.dateDosed).inDays;
          final timeAgo = daysSince == 0
              ? 'Today'
              : daysSince == 1
                  ? 'Yesterday'
                  : daysSince < 7
                      ? '$daysSince days ago'
                      : '${entry.dateDosed.month}/${entry.dateDosed.day}/${entry.dateDosed.year}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication_liquid,
                    size: 16,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.treatmentName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '${entry.amount}${entry.unit} • $timeAgo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (tank.dosingEntries.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${tank.dosingEntries.length - 5} more doses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getActivityIcon(NotificationType type) {
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

  Color _getActivityColor(NotificationType type) {
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

  void _showPhotoMaximized(BuildContext context, TankPhoto photo) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = photo.imageUrl ?? photo.imagePath;
    if (imageUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.failedToLoadImage(error.toString()),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Image.file(
                        File(imageUrl),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Date taken: ${photo.dateTaken.month}/${photo.dateTaken.day}/${photo.dateTaken.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    
                    Uint8List? imageBytes;
                    try {
                      if (imageUrl.startsWith('http')) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.aiAnalysisNotSupportedForCloudImages),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        return;
                      } else {
                        final file = File(imageUrl);
                        imageBytes = await file.readAsBytes();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.failedToLoadImage(e.toString())),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                      return;
                    }
                    
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PhotoAnalysisScreen(
                            initialImageBytes: imageBytes,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.9),
                          Colors.blue.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
