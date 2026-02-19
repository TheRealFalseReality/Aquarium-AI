import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../models/fish.dart';
import '../models/water_parameter.dart';
import '../models/dosing_entry.dart';
import '../models/notification_log.dart';
import '../providers/tank_provider.dart';
import '../services/fish_data_service.dart';
import '../utils/tank_harmony_calculator.dart';
import '../services/analytics_service.dart';
import '../l10n/app_localizations.dart';
import 'tank_creation_screen.dart';
import 'notification_management_screen.dart';

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
            title: Text(tank.name),
            backgroundColor: cs.surface.withOpacity(0.95),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: cs.primary,
              indicatorWeight: 3,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface.withOpacity(0.6),
              tabs: [
                Tab(icon: Icon(Icons.dashboard_outlined, color: _tabController.index == 0 ? cs.primary : cs.onSurface.withOpacity(0.6)), text: l10n.overview),
                Tab(icon: Icon(Icons.photo_library_outlined, color: _tabController.index == 1 ? cs.secondary : cs.onSurface.withOpacity(0.6)), text: l10n.photos),
                Tab(icon: Icon(Icons.science_outlined, color: _tabController.index == 2 ? cs.tertiary : cs.onSurface.withOpacity(0.6)), text: l10n.waterParameters),
                Tab(icon: Icon(Icons.medication_outlined, color: _tabController.index == 3 ? cs.primary : cs.onSurface.withOpacity(0.6)), text: l10n.dosing),
                Tab(icon: Icon(Icons.history, color: _tabController.index == 4 ? cs.secondary : cs.onSurface.withOpacity(0.6)), text: l10n.activity),
                Tab(icon: Icon(Icons.note_outlined, color: _tabController.index == 5 ? cs.tertiary : cs.onSurface.withOpacity(0.6)), text: l10n.notes),
              ],
            ),
            actions: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: l10n.editTank,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TankCreationScreen(existingTank: tank),
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
                      builder: (context) => NotificationManagementScreen(tank: tank),
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
        ),
      ),
    );
  }

  /// Overview tab - Tank info, harmony score, inhabitants, action buttons
  Widget _buildOverviewTab(BuildContext context, Tank tank, Map<String, List<Fish>>? fishData) {
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
                            color: (tank.type == 'freshwater' 
                                ? cs.primary 
                                : cs.secondary).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tank.type == 'freshwater' 
                                ? l10n.freshwaterTank
                                : l10n.saltwaterTank,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      _buildStatChip(context, Icons.straighten, _formatTankSize(tank)),
                    if (tank.sizeGallons != null || tank.sizeLiters != null)
                      _buildStatChip(context, Icons.line_weight, _formatWaterWeight(tank)),
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
            Icon(Icons.photo_library_outlined, size: 64, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              l10n.noPhotos,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addPhotosHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
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
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
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
            Icon(Icons.science_outlined, size: 64, color: cs.onSurface.withOpacity(0.3)),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Show all parameters as cards
        ...sortedParams.map((param) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.science_outlined, color: cs.primary),
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
            ),
          );
        }).toList(),
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
            Icon(Icons.medication_outlined, size: 64, color: cs.onSurface.withOpacity(0.3)),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recentEntries.map((entry) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.medication, color: cs.primary),
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
              trailing: entry.notes != null && entry.notes!.isNotEmpty
                  ? Icon(Icons.note, color: cs.onSurface.withOpacity(0.5))
                  : null,
            ),
          );
        }).toList(),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recentLogs.map((log) {
          return Card(
            child: ListTile(
              leading: Icon(_getActivityIcon(log.type), color: cs.primary),
              title: Text(log.customCategory ?? log.type.toString().split('.').last),
              subtitle: Text(
                DateFormat.yMMMd().add_jm().format(log.loggedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              trailing: log.notes != null && log.notes!.isNotEmpty
                  ? Icon(Icons.note, color: cs.onSurface.withOpacity(0.5))
                  : null,
            ),
          );
        }).toList(),
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
            Icon(Icons.note_outlined, size: 64, color: cs.onSurface.withOpacity(0.3)),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...tank.tankNotes.reversed.map((note) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.content),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.yMMMd().add_jm().format(note.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyScoreChip(Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
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
        border: Border.all(
          color: scoreColor.withOpacity(0.4),
        ),
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

  Widget _buildInhabitantsSection(BuildContext context, Tank tank, Map<String, List<Fish>> fishData) {
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
                  child: Icon(Icons.pets, color: cs.onSecondaryContainer, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.inhabitantsLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tank.inhabitants.map((inhabitant) {
              final fishImageUrl = _getFishImageUrl(tank.type, inhabitant.fishUnit, fishData, inhabitant: inhabitant);
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
                                : FileImage(File(fishImageUrl)) as ImageProvider)
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
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          ],
        ),
      ),
    );
  }

  /// Helper method to get fish image URL (prioritizes custom images)
  String? _getFishImageUrl(String tankType, String fishName, Map<String, List<Fish>>? fishData, {TankInhabitant? inhabitant}) {
    // Prioritize custom images if inhabitant is provided
    if (inhabitant != null) {
      if (inhabitant.customImageUrl != null && inhabitant.customImageUrl!.isNotEmpty) {
        return inhabitant.customImageUrl;
      }
      if (inhabitant.customImagePath != null && inhabitant.customImagePath!.isNotEmpty) {
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
                    child: Icon(Icons.calculate, color: cs.onTertiaryContainer, size: 20),
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
                    _showCalculationBreakdown ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            if (_showCalculationBreakdown) ...[
              const SizedBox(height: 12),
              Text(
                tank.calculationBreakdown ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
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
      builder: (context) => Dialog(
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
            ),
            Expanded(
              child: InteractiveViewer(
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
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
      ),
    );
  }
}
