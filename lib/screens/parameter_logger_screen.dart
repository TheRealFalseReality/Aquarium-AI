import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../models/water_parameter.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../utils/parameter_range_alerts.dart';
import '../utils/parameter_trend_alerts.dart';
import '../widgets/out_of_range_alerts_banner.dart';

/// Returns the localized display name for [parameterType].
/// Module-level so both [ParameterLoggerScreenState] and
/// [_AddParameterSheetState] can call it without duplication.
String _parameterLabel(String parameterType, BuildContext context) {
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

const List<String> _freshwaterDefaultParameterTypes = [
  'temperature',
  'ammonia',
  'nitrite',
  'nitrate',
  'phosphate',
  'kh',
  'gh',
  'alkalinity',
  'orp',
  'ph',
  'potassium',
  'tds',
];

const List<String> _marineOnlyParameterTypes = [
  'salinity',
  'calcium',
  'magnesium',
  'iodine',
];

List<String> _defaultParameterTypesForTank(Tank tank) =>
    tank.type == 'marine'
        ? [..._freshwaterDefaultParameterTypes, ..._marineOnlyParameterTypes]
        : _freshwaterDefaultParameterTypes;

class ParameterLoggerScreen extends ConsumerStatefulWidget {
  final Tank tank;
  final bool openAddDialog;

  const ParameterLoggerScreen({
    super.key,
    required this.tank,
    this.openAddDialog = false,
  });

  @override
  ParameterLoggerScreenState createState() => ParameterLoggerScreenState();
}

class ParameterLoggerScreenState extends ConsumerState<ParameterLoggerScreen> {
  String? _expandedParameter;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'parameter_logger_screen');
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addParameter(context);
      });
    }
  }

  Tank _getCurrentTank() {
    // Get the latest tank state from the provider
    final tanks = ref.watch(tankProvider).tanks;
    return tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
  }

  Map<String, ParameterBoundsConfig> _customBoundsByType(Tank tank) {
    return {
      for (final profile in tank.parameterProfiles)
        if (profile.minValue != null || profile.maxValue != null)
          profile.parameterType: ParameterBoundsConfig(
            minValue: profile.minValue,
            maxValue: profile.maxValue,
          ),
    };
  }

  List<String> _allParameterTypesForTank(Tank tank) {
    final ordered = <String>[];
    final seen = <String>{};
    final defaults = _defaultParameterTypesForTank(tank);
    final profileTypes = tank.parameterProfiles.map((p) => p.parameterType);
    final loggedTypes = tank.waterParameters.map((p) => p.parameterType);
    for (final type in [...defaults, ...profileTypes, ...loggedTypes]) {
      if (seen.add(type)) {
        ordered.add(type);
      }
    }
    return ordered;
  }

  void _addParameter(BuildContext context) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddParameterSheet(tank: currentTank),
    );
  }

  void _editParameter(BuildContext context, WaterParameter parameter) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _AddParameterSheet(tank: currentTank, existingParameter: parameter),
    );
  }

  void _openParameterProfiles(BuildContext context) {
    AnalyticsService.logFeatureUsed(
      featureName: 'parameter_profiles_opened',
      parameters: {'source': 'parameter_logger'},
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ParameterProfilesSheet(tankId: widget.tank.id),
    );
  }

  void _deleteParameter(WaterParameter parameter) {
    final currentTank = _getCurrentTank();
    final updatedParameters = currentTank.waterParameters
        .where((p) => p.id != parameter.id)
        .toList();
    final updatedTank = currentTank.copyWith(
      waterParameters: updatedParameters,
      updatedAt: DateTime.now(),
    );
    ref.read(tankProvider.notifier).updateTank(updatedTank);

    // Log parameter deletion
    AnalyticsService.logFeatureUsed(
      featureName: 'parameter_deleted',
      parameters: {
        'parameter_type': parameter.parameterType,
        'tank_type': currentTank.type,
        'remaining_parameters': updatedParameters.length,
      },
    );

    AnalyticsService.logTankAction(
      action: 'parameter_deleted',
      tankType: currentTank.type,
    );
  }

  void _analyzeReading(WaterParameter parameter) {
    final l10n = AppLocalizations.of(context)!;
    final currentTank = _getCurrentTank();
    final parameterLabel = _getParameterLabel(parameter.parameterType, context);
    final prompt = parameter.notes != null && parameter.notes!.trim().isNotEmpty
        ? l10n.analyzeReadingPromptWithNotes(
            currentTank.name,
            currentTank.type,
            parameterLabel,
            parameter.value.toString(),
            parameter.unit ?? '',
            DateFormat('yyyy-MM-dd HH:mm').format(parameter.dateRecorded),
            parameter.notes!.trim(),
          )
        : l10n.analyzeReadingPromptWithoutNotes(
            currentTank.name,
            currentTank.type,
            parameterLabel,
            parameter.value.toString(),
            parameter.unit ?? '',
            DateFormat('yyyy-MM-dd HH:mm').format(parameter.dateRecorded),
          );

    AnalyticsService.logFeatureUsed(
      featureName: 'parameter_reading_analyze_with_ai',
      parameters: {
        'parameter_type': parameter.parameterType,
        'tank_type': currentTank.type,
        'has_notes': parameter.notes?.trim().isNotEmpty == true ? 'true' : 'false',
      },
    );

    Navigator.pushNamed(
      context,
      '/chatbot',
      arguments: {'initialPrompt': prompt},
    );
  }

  Map<String, List<WaterParameter>> _groupParametersByType(Tank tank) {
    final grouped = <String, List<WaterParameter>>{};
    for (var param in tank.waterParameters) {
      if (!grouped.containsKey(param.parameterType)) {
        grouped[param.parameterType] = [];
      }
      grouped[param.parameterType]!.add(param);
    }
    // Sort each group by date (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    });
    return grouped;
  }

  String _getParameterLabel(String parameterType, BuildContext context) =>
      _parameterLabel(parameterType, context);

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
        // For custom parameters, use a generic icon
        return Icons.science;
    }
  }

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
        // For custom parameters, use a teal color
        return Colors.teal;
    }
  }

  Color _getThresholdColor(
    String parameterType,
    double value, {
    String? unit,
    Map<String, ParameterBoundsConfig>? customBounds,
  }) {
    final status = getParameterStatus(
      parameterType,
      value,
      unit: unit,
      customBounds: customBounds,
    );
    return switch (status) {
      ParameterStatus.normal => Colors.green,
      ParameterStatus.caution => Colors.yellow.shade700,
      ParameterStatus.warning => Colors.orange,
      ParameterStatus.critical => Colors.red,
    };
  }

  /// Minimum number of entries to show on the graph when falling back from the 30-day filter
  static const int _minGraphEntries = 10;

  /// Date span thresholds for determining X-axis label intervals
  static const int _wideSpanThreshold =
      20; // Days; use interval of 5 above this
  static const int _mediumSpanThreshold =
      7; // Days; use interval of 2 above this

  /// Get parameters for the graph display.
  /// Returns a record with the filtered parameters and whether we're using the fallback mode.
  /// - First tries to get data from the last 30 days
  /// - If no data in last 30 days, falls back to showing the most recent entries
  ({List<WaterParameter> params, bool isRecentFallback}) _getParametersForGraph(
    List<WaterParameter> parameters,
  ) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final last30Days = parameters
        .where((p) => p.dateRecorded.isAfter(thirtyDaysAgo))
        .toList();

    if (last30Days.isNotEmpty) {
      return (params: last30Days, isRecentFallback: false);
    }

    // No data in last 30 days, fall back to showing the most recent entries
    // Sort by date (newest first) and take up to N most recent entries
    final sortedByDateDesc = List<WaterParameter>.from(parameters)
      ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    final recentParams = sortedByDateDesc.take(_minGraphEntries).toList();

    return (params: recentParams, isRecentFallback: true);
  }

  Widget _buildParameterGraph(
    List<WaterParameter> parameters,
    String parameterType,
    Map<String, ParameterBoundsConfig> customBounds,
  ) {
    if (parameters.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get parameters for graph display with smart fallback
    final graphData = _getParametersForGraph(parameters);
    final filteredParams = graphData.params;
    final isRecentFallback = graphData.isRecentFallback;

    if (filteredParams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No data available',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Sort by date (oldest first for chart)
    final sortedParams = List<WaterParameter>.from(filteredParams)
      ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

    // Get latest value for display
    final latestParam = sortedParams.last;
    final latestValue = latestParam.value;
    final latestUnit = latestParam.unit ?? '';
    final latestColor = _getThresholdColor(
      parameterType,
      latestValue,
      unit: latestUnit,
      customBounds: customBounds,
    );

    // Create data spots with color segments
    final spots = <FlSpot>[];
    final spotColors = <Color>[];
    final oldestDate = sortedParams.first.dateRecorded;

    for (var param in sortedParams) {
      final daysDiff = param.dateRecorded
          .difference(oldestDate)
          .inDays
          .toDouble();
      spots.add(FlSpot(daysDiff, param.value));
      spotColors.add(
        _getThresholdColor(
          parameterType,
          param.value,
          unit: param.unit,
          customBounds: customBounds,
        ),
      );
    }

    // Use the latest value's threshold color for the line, except for salinity which is always blue
    final lineColor = parameterType == 'salinity' ? Colors.blue : latestColor;
    final maxY = sortedParams
        .map((p) => p.value)
        .reduce((a, b) => a > b ? a : b);
    final minY = sortedParams
        .map((p) => p.value)
        .reduce((a, b) => a < b ? a : b);
    final yRange = maxY - minY;
    final yPadding = yRange * 0.1;

    // Calculate the actual date range for the X axis
    final newestDate = sortedParams.last.dateRecorded;
    final daySpan = newestDate.difference(oldestDate).inDays.toDouble();
    final maxXValue = daySpan > 0
        ? daySpan
        : 1.0; // Ensure at least 1 day span for single data point

    // Build the graph title based on the data range
    final String graphTitle;
    if (isRecentFallback) {
      graphTitle =
          'Last ${sortedParams.length} Reading${sortedParams.length == 1 ? '' : 's'}';
    } else {
      graphTitle = 'Last 30 Days Trend';
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                graphTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: latestColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: latestColor, width: 1.5),
                ),
                child: Text(
                  'Latest: ${latestValue.toStringAsFixed(2)}$latestUnit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: latestColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yRange > 0 ? yRange / 5 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxXValue > _wideSpanThreshold
                          ? 5
                          : (maxXValue > _mediumSpanThreshold ? 2 : 1),
                      getTitlesWidget: (value, meta) {
                        final date = oldestDate.add(
                          Duration(days: value.toInt()),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: yRange > 0 ? yRange / 4 : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                minX: 0,
                maxX: maxXValue,
                minY: minY - yPadding,
                maxY: maxY + yPadding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Color each dot based on its threshold
                        final dotColor = spotColors[index];
                        return FlDotCirclePainter(
                          radius: 4,
                          color: dotColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = oldestDate.add(
                          Duration(days: spot.x.toInt()),
                        );
                        final param = sortedParams.firstWhere(
                          (p) =>
                              p.dateRecorded.difference(oldestDate).inDays ==
                              spot.x.toInt(),
                          orElse: () => sortedParams.first,
                        );
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(2)}${param.unit ?? ''}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final currentTank = _getCurrentTank();
    final customBounds = _customBoundsByType(currentTank);
    final groupedParameters = _groupParametersByType(currentTank);
    final proactiveAlerts = buildProactiveParameterAlerts(
      currentTank.waterParameters,
    );
    final outOfRangeAlerts = buildCurrentOutOfRangeAlerts(
      currentTank.waterParameters,
      tankType: currentTank.type,
      customBounds: customBounds,
    );

    final parameterTypes = _allParameterTypesForTank(currentTank);

    return MainLayout(
      title: '${currentTank.name} - Parameters',
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentTank.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addParameter(context),
              tooltip: 'Add Parameter',
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => _openParameterProfiles(context),
              tooltip: l10n.manageParameterRanges,
            ),
          ],
        ),
        body: currentTank.waterParameters.isEmpty
            ? _buildEmptyState(context)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Water Parameter History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your aquarium\'s water quality over time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (outOfRangeAlerts.isNotEmpty) ...[
                    OutOfRangeAlertsBanner(
                      alerts: outOfRangeAlerts,
                      parameterLabel: (type) =>
                          _parameterLabel(type, context),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (proactiveAlerts.isNotEmpty) ...[
                    _buildProactiveTrendAlerts(context, proactiveAlerts),
                    const SizedBox(height: 24),
                  ],
                  ...parameterTypes.map((paramType) {
                    final parameters = groupedParameters[paramType] ?? [];
                    if (parameters.isEmpty) return const SizedBox.shrink();

                    final isExpanded = _expandedParameter == paramType;
                    final color = _getParameterColor(paramType);

                    // Latest reading for status badge
                    final latestStatus = getParameterStatus(
                      paramType,
                      parameters.first.value,
                      unit: parameters.first.unit,
                      customBounds: customBounds,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getParameterIcon(paramType),
                                color: color,
                              ),
                            ),
                            title: Text(
                              _getParameterLabel(paramType, context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${parameters.length} ${parameters.length == 1 ? l10n.reading : l10n.readings}',
                                  ),
                                ),
                                if (latestStatus !=
                                    ParameterStatus.normal) ...[
                                  const SizedBox(width: 6),
                                  _buildStatusBadge(context, latestStatus),
                                ],
                              ],
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onTap: () {
                              setState(() {
                                _expandedParameter = isExpanded
                                    ? null
                                    : paramType;
                              });
                            },
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            _buildParameterGraph(
                              parameters,
                              paramType,
                              customBounds,
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                'All Readings',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...parameters.map(
                              (param) => _buildParameterItem(context, param),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addParameter(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.addReading),
        ),
      ),
    );
  }

  /// Small coloured badge showing [status] — shown inline in the subtitle of
  /// each parameter card header when the latest reading is not normal.
  Widget _buildStatusBadge(BuildContext context, ParameterStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final color = switch (status) {
      ParameterStatus.critical => Colors.red,
      ParameterStatus.warning => Colors.orange,
      ParameterStatus.caution => Colors.amber.shade700,
      ParameterStatus.normal => Colors.green,
    };
    final label = switch (status) {
      ParameterStatus.critical => l10n.parameterStatusCritical,
      ParameterStatus.warning => l10n.warning,
      ParameterStatus.caution => l10n.parameterStatusCaution,
      ParameterStatus.normal => '',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProactiveTrendAlerts(
    BuildContext context,
    List<ParameterTrendAlert> alerts,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.primaryContainer.withOpacity(0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: cs.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.proactiveTrendFlagsTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alerts.map((alert) {
              final message = switch (alert.parameterType) {
                'nitrate' => l10n.nitrateRisingDaysAlert(alert.trendDays),
                _ => '',
              };

              if (message.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(message),
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

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 80,
              color: cs.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Parameters Logged Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your water parameters to monitor your aquarium\'s health over time.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _addParameter(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFirstReading),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterItem(BuildContext context, WaterParameter parameter) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final customBounds = _customBoundsByType(_getCurrentTank());
    final thresholdColor = _getThresholdColor(
      parameter.parameterType,
      parameter.value,
      unit: parameter.unit,
      customBounds: customBounds,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 56,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: thresholdColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${parameter.value}${parameter.unit ?? ''}',
          style: TextStyle(fontWeight: FontWeight.bold, color: thresholdColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      title: Text(
        dateFormat.format(parameter.dateRecorded),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () => _analyzeReading(parameter),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.analyzeThis),
          ),
          if (parameter.notes != null)
            Text(
              parameter.notes!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: cs.primary,
            onPressed: () => _editParameter(context, parameter),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _showDeleteDialog(context, parameter),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WaterParameter parameter) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteReading),
        content: Text(l10n.deleteReadingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              _deleteParameter(parameter);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _ParameterProfilesSheet extends ConsumerStatefulWidget {
  final String tankId;

  const _ParameterProfilesSheet({required this.tankId});

  @override
  ConsumerState<_ParameterProfilesSheet> createState() =>
      _ParameterProfilesSheetState();
}

class _ParameterProfilesSheetState
    extends ConsumerState<_ParameterProfilesSheet> {
  Tank? _currentTank() {
    final tanks = ref.watch(tankProvider).tanks;
    for (final tank in tanks) {
      if (tank.id == widget.tankId) return tank;
    }
    return null;
  }

  bool _isBuiltInForTank(String parameterType, Tank tank) {
    return _defaultParameterTypesForTank(tank).contains(parameterType);
  }

  Future<void> _deleteCustomProfile(
    BuildContext context,
    Tank tank,
    String parameterType,
  ) async {
    final updatedProfiles = tank.parameterProfiles
        .where((p) => p.parameterType != parameterType)
        .toList();
    final updatedTank = tank.copyWith(
      parameterProfiles: updatedProfiles,
      updatedAt: DateTime.now(),
    );
    await ref.read(tankProvider.notifier).updateTank(updatedTank);
    AnalyticsService.logFeatureUsed(
      featureName: 'parameter_profile_removed',
      parameters: {
        'parameter_type': parameterType,
        'tank_type': tank.type,
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.parameterRemoved)),
    );
  }

  Future<void> _openProfileEditor(
    BuildContext context,
    Tank tank, {
    TankParameterProfile? existing,
    String? fixedType,
    bool creatingCustom = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final typeController = TextEditingController(
      text: fixedType ?? existing?.parameterType ?? '',
    );
    final unitController = TextEditingController(
      text: existing?.preferredUnit ?? '',
    );
    final minController = TextEditingController(
      text: existing?.minValue?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: existing?.maxValue?.toString() ?? '',
    );

    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          creatingCustom
              ? l10n.addCustomParameter
              : l10n.editParameterBoundsTitle(
                  _parameterLabel(
                    fixedType ?? existing?.parameterType ?? '',
                    context,
                  ),
                ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: typeController,
                enabled: creatingCustom,
                decoration: InputDecoration(
                  labelText: l10n.parameterTypeLabel,
                  hintText: l10n.customParameterHint,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: unitController,
                decoration: InputDecoration(labelText: l10n.defaultUnitLabel),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: minController,
                decoration: InputDecoration(
                  labelText: l10n.minBoundLabel,
                  hintText: l10n.optionalLabel,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxController,
                decoration: InputDecoration(
                  labelText: l10n.maxBoundLabel,
                  hintText: l10n.optionalLabel,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final parameterType = typeController.text.trim().toLowerCase();
              final minText = minController.text.trim();
              final maxText = maxController.text.trim();
              final minValue = minText.isEmpty ? null : double.tryParse(minText);
              final maxValue = maxText.isEmpty ? null : double.tryParse(maxText);

              if (parameterType.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.parameterNameRequired)),
                );
                return;
              }

              if ((minText.isNotEmpty && minValue == null) ||
                  (maxText.isNotEmpty && maxValue == null)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.enterValidNumber)),
                );
                return;
              }

              if (minValue != null &&
                  maxValue != null &&
                  minValue > maxValue) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.minMustBeLessOrEqualMax)),
                );
                return;
              }

              final isBuiltIn = _isBuiltInForTank(parameterType, tank);
              final preferredUnit = unitController.text.trim().isEmpty
                  ? null
                  : unitController.text.trim();
              final shouldRemoveOverride =
                  isBuiltIn &&
                  !creatingCustom &&
                  minValue == null &&
                  maxValue == null &&
                  preferredUnit == null;

              final updatedProfiles = [...tank.parameterProfiles];
              updatedProfiles.removeWhere(
                (p) => p.parameterType == parameterType,
              );
              if (!shouldRemoveOverride) {
                updatedProfiles.add(
                  TankParameterProfile(
                    parameterType: parameterType,
                    preferredUnit: preferredUnit,
                    minValue: minValue,
                    maxValue: maxValue,
                    isCustom:
                        creatingCustom ||
                        existing?.isCustom == true ||
                        !_isBuiltInForTank(parameterType, tank),
                  ),
                );
              }

              final updatedTank = tank.copyWith(
                parameterProfiles: updatedProfiles,
                updatedAt: DateTime.now(),
              );
              ref.read(tankProvider.notifier).updateTank(updatedTank);
              AnalyticsService.logFeatureUsed(
                featureName: 'parameter_profile_saved',
                parameters: {
                  'parameter_type': parameterType,
                  'tank_type': tank.type,
                  'is_custom': (creatingCustom || existing?.isCustom == true)
                      ? 'true'
                      : 'false',
                  'has_min': minValue != null ? 'true' : 'false',
                  'has_max': maxValue != null ? 'true' : 'false',
                },
              );
              Navigator.pop(context, true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (didSave == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.parameterBoundsSaved)),
      );
    }
  }

  String _profileSummary(
    BuildContext context,
    TankParameterProfile? profile,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (profile == null) return l10n.usingDefaultRange;
    final minText = profile.minValue?.toString() ?? '—';
    final maxText = profile.maxValue?.toString() ?? '—';
    final unitText = profile.preferredUnit?.isNotEmpty == true
        ? profile.preferredUnit!
        : l10n.noneLabel;
    return l10n.parameterProfileSummary(minText, maxText, unitText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tank = _currentTank();
    if (tank == null) {
      return const SizedBox.shrink();
    }

    final profileByType = {
      for (final profile in tank.parameterProfiles) profile.parameterType: profile,
    };
    final availableTypes = <String>[];
    final seen = <String>{};
    for (final type in [
      ..._defaultParameterTypesForTank(tank),
      ...tank.waterParameters.map((p) => p.parameterType),
      ...tank.parameterProfiles.map((p) => p.parameterType),
    ]) {
      if (seen.add(type)) availableTypes.add(type);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.manageParameterRanges,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              l10n.manageParameterRangesDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openProfileEditor(
                  context,
                  tank,
                  creatingCustom: true,
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.addCustomParameter),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                itemCount: availableTypes.length,
                itemBuilder: (context, index) {
                  final type = availableTypes[index];
                  final profile = profileByType[type];
                  final isCustom = profile?.isCustom == true &&
                      !_isBuiltInForTank(type, tank);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(_parameterLabel(type, context)),
                      subtitle: Text(_profileSummary(context, profile)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openProfileEditor(
                              context,
                              tank,
                              existing: profile,
                              fixedType: type,
                            ),
                          ),
                          if (isCustom)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () => _deleteCustomProfile(
                                context,
                                tank,
                                type,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddParameterSheet extends ConsumerStatefulWidget {
  final Tank tank;
  final WaterParameter? existingParameter;

  const _AddParameterSheet({required this.tank, this.existingParameter});

  @override
  ConsumerState<_AddParameterSheet> createState() => _AddParameterSheetState();
}

class _AddParameterSheetState extends ConsumerState<_AddParameterSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedParameter;
  final _customParameterNameController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedUnit;

  final Map<String, List<String>> _unitOptions = {
    'ammonia': ['ppm', 'mg/L'],
    'nitrite': ['ppm', 'mg/L'],
    'nitrate': ['ppm', 'mg/L'],
    'phosphate': ['ppm', 'mg/L'],
    'salinity': ['ppt', 'SG'],
    'calcium': ['ppm', 'mg/L'],
    'magnesium': ['ppm', 'mg/L'],
    'kh': ['dKH', 'meq/L', 'ppm'],
    'gh': ['dGH', 'meq/L', 'ppm'],
    'alkalinity': ['meq/L', 'dKH'],
    'orp': ['mV'],
    'ph': ['pH'],
    'potassium': ['ppm', 'mg/L'],
    'tds': ['ppm', 'mg/L'],
    'iodine': ['ppm', 'mg/L'],
    'temperature': ['°F', '°C'],
    'custom': [
      'ppm',
      'mg/L',
      '%',
      'dKH',
      'meq/L',
      'mV',
      'pH',
      'ppt',
      'SG',
      'dGH',
      '°F',
      '°C',
    ],
  };

  List<TankParameterProfile> get _profiles => widget.tank.parameterProfiles;

  List<String> get _availableParameterTypes {
    final types = <String>[];
    final seen = <String>{};
    for (final type in [
      ..._defaultParameterTypesForTank(widget.tank),
      ..._profiles.map((p) => p.parameterType),
    ]) {
      if (seen.add(type)) {
        types.add(type);
      }
    }
    return types;
  }

  TankParameterProfile? _profileForType(String type) {
    for (final profile in _profiles) {
      if (profile.parameterType == type) {
        return profile;
      }
    }
    return null;
  }

  List<String> _unitsForParameter(String type) {
    final fromProfile = _profileForType(type)?.preferredUnit;
    final base = List<String>.from(_unitOptions[type] ?? _unitOptions['custom']!);
    if (fromProfile == null || fromProfile.isEmpty) {
      return base;
    }
    base.remove(fromProfile);
    return [fromProfile, ...base];
  }

  @override
  void initState() {
    super.initState();
    final availableTypes = _availableParameterTypes;
    if (widget.existingParameter != null) {
      // Initialize with existing parameter data
      final existingType = widget.existingParameter!.parameterType;
      if (availableTypes.contains(existingType) && existingType != 'custom') {
        _selectedParameter = existingType;
      } else {
        // It's a custom parameter
        _selectedParameter = 'custom';
        _customParameterNameController.text = existingType;
      }
      _valueController.text = widget.existingParameter!.value.toString();
      _notesController.text = widget.existingParameter!.notes ?? '';
      _selectedDate = widget.existingParameter!.dateRecorded;
      _selectedUnit = widget.existingParameter!.unit ?? 'ppm';
    } else {
      // Initialize with default values for new parameter
      _selectedParameter = 'temperature';
      _selectedDate = DateTime.now();
      _selectedUnit = _unitsForParameter(_selectedParameter).first;
    }

    final validUnits = _unitsForParameter(_selectedParameter);
    if (!validUnits.contains(_selectedUnit)) {
      _selectedUnit = validUnits.first;
    }
  }

  @override
  void dispose() {
    _customParameterNameController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
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

  String _getParameterType() {
    // If "custom" is selected, use the text field value
    if (_selectedParameter == 'custom') {
      return _customParameterNameController.text.trim().toLowerCase();
    }
    // Otherwise use the selected parameter from dropdown
    return _selectedParameter;
  }

  List<TankParameterProfile> _withUpdatedPreferredUnit(
    List<TankParameterProfile> profiles,
    String parameterType,
    String selectedUnit, {
    required bool isCustomSelection,
  }) {
    final updatedProfiles = [...profiles];
    final existingIndex = updatedProfiles.indexWhere(
      (p) => p.parameterType == parameterType,
    );

    if (existingIndex >= 0) {
      updatedProfiles[existingIndex] = updatedProfiles[existingIndex].copyWith(
        preferredUnit: selectedUnit,
      );
      return updatedProfiles;
    }

    if (isCustomSelection) {
      updatedProfiles.add(
        TankParameterProfile(
          parameterType: parameterType,
          preferredUnit: selectedUnit,
          isCustom: true,
        ),
      );
    }

    return updatedProfiles;
  }

  void _saveParameter() {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final WaterParameter parameter;
      final isEditing = widget.existingParameter != null;
      final parameterType = _getParameterType();
      final updatedProfiles = _withUpdatedPreferredUnit(
        widget.tank.parameterProfiles,
        parameterType,
        _selectedUnit,
        isCustomSelection: _selectedParameter == 'custom',
      );

      // Additional safety check: prevent saving with empty parameter type
      if (parameterType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.parameterNameRequired),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (isEditing) {
        // Update existing parameter
        parameter = widget.existingParameter!.copyWith(
          parameterType: parameterType,
          value: double.parse(_valueController.text),
          unit: _selectedUnit,
          dateRecorded: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        // Replace the existing parameter in the list
        final updatedParameters = widget.tank.waterParameters.map((p) {
          return p.id == parameter.id ? parameter : p;
        }).toList();

        final updatedTank = widget.tank.copyWith(
          waterParameters: updatedParameters,
          parameterProfiles: updatedProfiles,
          updatedAt: DateTime.now(),
        );

        ref.read(tankProvider.notifier).updateTank(updatedTank);

        // Log parameter edit event
        AnalyticsService.logFeatureUsed(
          featureName: 'parameter_edited',
          parameters: {
            'parameter_type': parameterType,
            'tank_type': widget.tank.type,
            'value': parameter.value,
            'unit': _selectedUnit,
            'has_notes': parameter.notes != null && parameter.notes!.isNotEmpty
                ? 'true'
                : 'false',
            'is_custom': _selectedParameter == 'custom' ? 'true' : 'false',
          },
        );
      } else {
        // Create new parameter
        parameter = WaterParameter.create(
          parameterType: parameterType,
          value: double.parse(_valueController.text),
          unit: _selectedUnit,
          dateRecorded: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        final updatedParameters = [...widget.tank.waterParameters, parameter];
        final updatedTank = widget.tank.copyWith(
          waterParameters: updatedParameters,
          parameterProfiles: updatedProfiles,
          updatedAt: DateTime.now(),
        );

        ref.read(tankProvider.notifier).updateTank(updatedTank);

        // Log parameter add event
        AnalyticsService.logFeatureUsed(
          featureName: 'parameter_added',
          parameters: {
            'parameter_type': parameterType,
            'tank_type': widget.tank.type,
            'value': parameter.value,
            'unit': _selectedUnit,
            'has_notes': parameter.notes != null && parameter.notes!.isNotEmpty
                ? 'true'
                : 'false',
            'total_parameters': updatedParameters.length,
            'is_custom': _selectedParameter == 'custom' ? 'true' : 'false',
          },
        );
      }

      // Log general parameter action for analytics
      AnalyticsService.logTankAction(
        action: isEditing ? 'parameter_updated' : 'parameter_created',
        tankType: widget.tank.type,
      );

      // Capture messenger, parameterName, and status before popping — the
      // context may be unmounted once Navigator.pop removes the bottom sheet.
      final messenger = ScaffoldMessenger.of(context);
      final parameterName = _parameterLabel(parameterType, context);
      final customBounds = {
        for (final profile in updatedProfiles)
          if (profile.minValue != null || profile.maxValue != null)
            profile.parameterType: ParameterBoundsConfig(
              minValue: profile.minValue,
              maxValue: profile.maxValue,
            ),
      };
      final status = getParameterStatus(
        parameterType,
        parameter.value,
        unit: _selectedUnit,
        customBounds: customBounds,
      );

      Navigator.pop(context);

      // Show out-of-range SnackBar after dismissing the sheet.
      if (status != ParameterStatus.normal) {
        final snackBarColor = switch (status) {
          ParameterStatus.critical => Colors.red.shade700,
          ParameterStatus.warning => Colors.orange.shade700,
          ParameterStatus.caution => Colors.amber.shade800,
          ParameterStatus.normal => Colors.green,
        };
        final statusLabel = switch (status) {
          ParameterStatus.critical => l10n.parameterStatusCritical,
          ParameterStatus.warning => l10n.warning,
          ParameterStatus.caution => l10n.parameterStatusCaution,
          ParameterStatus.normal => '',
        };
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.outOfRangeSnackBar(
                      parameterName,
                      parameter.value.toStringAsFixed(2),
                      _selectedUnit,
                      statusLabel,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

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
              Row(
                children: [
                  Text(
                    widget.existingParameter != null
                        ? 'Edit Parameter Reading'
                        : 'Add Parameter Reading',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedParameter,
                decoration: const InputDecoration(
                  labelText: 'Parameter Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  ..._availableParameterTypes.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_parameterLabel(type, context)),
                    ),
                  ),
                  DropdownMenuItem(value: 'custom', child: Text(l10n.custom)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedParameter = value!;
                    _selectedUnit = _unitsForParameter(value).first;
                    // Clear custom name when switching away from "Custom"
                    if (value != 'custom') {
                      _customParameterNameController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Custom parameter name (shown only when "Custom" is selected)
              if (_selectedParameter == 'custom') ...[
                TextFormField(
                  controller: _customParameterNameController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Parameter Name *',
                    hintText: 'e.g., Iron, Copper, Strontium',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (_selectedParameter == 'custom' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter a parameter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _unitsForParameter(_selectedParameter)
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveParameter,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.existingParameter != null
                        ? 'Update Reading'
                        : 'Save Reading',
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

/// Shows the parameter add/edit bottom sheet.
/// [existingParameter] – pass to edit an existing entry.
void showParameterSheet(
  BuildContext context,
  Tank tank, {
  WaterParameter? existingParameter,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _AddParameterSheet(tank: tank, existingParameter: existingParameter),
  );
}
