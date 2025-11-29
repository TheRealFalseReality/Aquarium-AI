import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tank.dart';
import '../models/water_parameter.dart';
import '../providers/tank_provider.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';

class ParameterLoggerScreen extends ConsumerStatefulWidget {
  final Tank tank;

  const ParameterLoggerScreen({super.key, required this.tank});

  @override
  ParameterLoggerScreenState createState() => ParameterLoggerScreenState();
}

class ParameterLoggerScreenState extends ConsumerState<ParameterLoggerScreen> {
  String? _expandedParameter;

  Tank _getCurrentTank() {
    // Get the latest tank state from the provider
    final tanks = ref.watch(tankProvider).tanks;
    return tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
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
      builder: (context) => _AddParameterSheet(
        tank: currentTank,
        existingParameter: parameter,
      ),
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

  String _getParameterLabel(String parameterType) {
    switch (parameterType) {
      case 'ammonia':
        return 'Ammonia';
      case 'nitrite':
        return 'Nitrite';
      case 'nitrate':
        return 'Nitrate';
      case 'phosphate':
        return 'Phosphate';
      case 'salinity':
        return 'Salinity';
      case 'calcium':
        return 'Calcium';
      case 'magnesium':
        return 'Magnesium';
      case 'kh':
        return 'KH (Carbonate Hardness)';
      case 'gh':
        return 'GH (General Hardness)';
      case 'alkalinity':
        return 'Alkalinity';
      case 'orp':
        return 'ORP';
      case 'ph':
        return 'pH';
      case 'potassium':
        return 'Potassium';
      case 'tds':
        return 'TDS';
      case 'iodine':
        return 'Iodine';
      case 'temperature':
        return 'Temperature';
      default:
        // For custom parameters, capitalize first letter
        if (parameterType.isEmpty) {
          return 'Custom';
        }
        return parameterType[0].toUpperCase() + (parameterType.length > 1 ? parameterType.substring(1) : '');
    }
  }

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

  Color _getThresholdColor(String parameterType, double value, {String? unit}) {
    switch (parameterType) {
      case 'ammonia':
        if (value == 0) return Colors.green;
        if (value <= 1) return Colors.yellow.shade700;
        if (value < 4) return Colors.orange;
        return Colors.red;
      
      case 'nitrite':
        if (value == 0) return Colors.green;
        if (value <= 1) return Colors.yellow.shade700;
        if (value < 2) return Colors.orange;
        return Colors.red;
      
      case 'nitrate':
        if (value == 0) return Colors.green;
        if (value <= 5) return Colors.green.shade300;
        if (value <= 40) return Colors.blue.shade400;
        return Colors.blue.shade900;
      
      case 'phosphate':
        if (value == 0) return Colors.green;
        if (value < 1) return Colors.yellow.shade700;
        if (value < 5) return Colors.orange;
        return Colors.red;
      
      case 'salinity':
        // Determine if using ppt or SG
        final isSG = unit == 'SG';
        
        if (isSG) {
          // SG thresholds (1.020-1.026 is ideal)
          if (value >= 1.023 && value <= 1.025) return Colors.green;
          if (value >= 1.021 && value <= 1.027) return Colors.yellow.shade700;
          if (value >= 1.019 && value <= 1.029) return Colors.orange;
          return Colors.red;
        } else {
          // ppt thresholds
          if (value >= 32 && value <= 35) return Colors.green;
          if ((value >= 31 && value < 32) || (value > 35 && value <= 36)) return Colors.yellow.shade700;
          if ((value >= 29 && value < 31) || (value > 36 && value <= 38)) return Colors.orange;
          return Colors.red;
        }
      
      case 'calcium':
        // Calcium thresholds for marine tanks (ppm)
        if (value >= 400 && value <= 450) return Colors.green;
        if ((value >= 380 && value < 400) || (value > 450 && value <= 480)) return Colors.yellow.shade700;
        if ((value >= 350 && value < 380) || (value > 480 && value <= 520)) return Colors.orange;
        return Colors.red;
      
      case 'magnesium':
        // Magnesium thresholds for marine tanks (ppm)
        if (value >= 1250 && value <= 1350) return Colors.green;
        if ((value >= 1200 && value < 1250) || (value > 1350 && value <= 1400)) return Colors.yellow.shade700;
        if ((value >= 1100 && value < 1200) || (value > 1400 && value <= 1500)) return Colors.orange;
        return Colors.red;
      
      case 'kh':
        // KH thresholds (dKH)
        if (value >= 4 && value <= 8) return Colors.green;
        if ((value >= 3 && value < 4) || (value > 8 && value <= 10)) return Colors.yellow.shade700;
        if ((value >= 2 && value < 3) || (value > 10 && value <= 12)) return Colors.orange;
        return Colors.red;
      
      case 'gh':
        // GH thresholds (dGH) - general range for freshwater
        if (value >= 4 && value <= 12) return Colors.green;
        if ((value >= 3 && value < 4) || (value > 12 && value <= 15)) return Colors.yellow.shade700;
        if ((value >= 2 && value < 3) || (value > 15 && value <= 18)) return Colors.orange;
        return Colors.red;
      
      case 'alkalinity':
        // Alkalinity thresholds (meq/L or dKH)
        if (value >= 2.5 && value <= 4.0) return Colors.green;
        if ((value >= 2.0 && value < 2.5) || (value > 4.0 && value <= 5.0)) return Colors.yellow.shade700;
        if ((value >= 1.5 && value < 2.0) || (value > 5.0 && value <= 6.0)) return Colors.orange;
        return Colors.red;
      
      case 'orp':
        // ORP thresholds (mV) - higher is better for most aquariums
        if (value >= 300 && value <= 450) return Colors.green;
        if ((value >= 250 && value < 300) || (value > 450 && value <= 500)) return Colors.yellow.shade700;
        if ((value >= 200 && value < 250) || (value > 500 && value <= 550)) return Colors.orange;
        return Colors.red;
      
      case 'ph':
        // pH thresholds - general range (6.5-8.0 is typical)
        if (value >= 6.8 && value <= 7.8) return Colors.green;
        if ((value >= 6.5 && value < 6.8) || (value > 7.8 && value <= 8.2)) return Colors.yellow.shade700;
        if ((value >= 6.0 && value < 6.5) || (value > 8.2 && value <= 8.5)) return Colors.orange;
        return Colors.red;
      
      case 'potassium':
        // Potassium thresholds (ppm) - for planted tanks
        if (value >= 10 && value <= 30) return Colors.green;
        if ((value >= 5 && value < 10) || (value > 30 && value <= 40)) return Colors.yellow.shade700;
        if ((value >= 2 && value < 5) || (value > 40 && value <= 50)) return Colors.orange;
        return Colors.red;
      
      case 'tds':
        // TDS thresholds (ppm) - general freshwater range
        if (value >= 150 && value <= 250) return Colors.green;
        if ((value >= 100 && value < 150) || (value > 250 && value <= 350)) return Colors.yellow.shade700;
        if ((value >= 50 && value < 100) || (value > 350 && value <= 450)) return Colors.orange;
        return Colors.red;
      
      case 'iodine':
        // Iodine thresholds for marine tanks (ppm)
        if (value >= 0.06 && value <= 0.10) return Colors.green;
        if ((value >= 0.04 && value < 0.06) || (value > 0.10 && value <= 0.12)) return Colors.yellow.shade700;
        if ((value >= 0.02 && value < 0.04) || (value > 0.12 && value <= 0.15)) return Colors.orange;
        return Colors.red;
      
      case 'temperature':
        // Temperature thresholds - check unit for °F or °C
        final isFahrenheit = unit == '°F';
        
        if (isFahrenheit) {
          // Fahrenheit thresholds (75-82°F is ideal for most tropical fish)
          if (value >= 76 && value <= 80) return Colors.green;
          if ((value >= 72 && value < 76) || (value > 80 && value <= 84)) return Colors.yellow.shade700;
          if ((value >= 68 && value < 72) || (value > 84 && value <= 88)) return Colors.orange;
          return Colors.red;
        } else {
          // Celsius thresholds (24-28°C is ideal for most tropical fish)
          if (value >= 24 && value <= 27) return Colors.green;
          if ((value >= 22 && value < 24) || (value > 27 && value <= 29)) return Colors.yellow.shade700;
          if ((value >= 20 && value < 22) || (value > 29 && value <= 31)) return Colors.orange;
          return Colors.red;
        }
      
      default:
        return Colors.grey;
    }
  }

  List<WaterParameter> _filterLast30Days(List<WaterParameter> parameters) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return parameters.where((p) => p.dateRecorded.isAfter(thirtyDaysAgo)).toList();
  }

  Widget _buildParameterGraph(List<WaterParameter> parameters, String parameterType) {
    if (parameters.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter to last 30 days
    final filteredParams = _filterLast30Days(parameters);
    
    if (filteredParams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No data in the last 30 days',
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
    final latestColor = _getThresholdColor(parameterType, latestValue, unit: latestUnit);

    // Create data spots with color segments
    final spots = <FlSpot>[];
    final spotColors = <Color>[];
    final oldestDate = sortedParams.first.dateRecorded;
    
    for (var param in sortedParams) {
      final daysDiff = param.dateRecorded.difference(oldestDate).inDays.toDouble();
      spots.add(FlSpot(daysDiff, param.value));
      spotColors.add(_getThresholdColor(parameterType, param.value, unit: param.unit));
    }

    // Use the latest value's threshold color for the line, except for salinity which is always blue
    final lineColor = parameterType == 'salinity' ? Colors.blue : latestColor;
    final maxY = sortedParams.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minY = sortedParams.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final yRange = maxY - minY;
    final yPadding = yRange * 0.1;

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
                'Last 30 Days Trend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final date = oldestDate.add(Duration(days: value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                minX: 0,
                maxX: 30,
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
                        final date = oldestDate.add(Duration(days: spot.x.toInt()));
                        final param = sortedParams.firstWhere(
                          (p) => p.dateRecorded.difference(oldestDate).inDays == spot.x.toInt(),
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
    final cs = Theme.of(context).colorScheme;
    final currentTank = _getCurrentTank();
    final groupedParameters = _groupParametersByType(currentTank);
    
    // Only show salinity, calcium, magnesium, and iodine for marine tanks
    final parameterTypes = currentTank.type == 'marine'
        ? ['temperature', 'ammonia', 'nitrite', 'nitrate', 'phosphate', 'salinity', 'calcium', 'magnesium', 'iodine', 'kh', 'gh', 'alkalinity', 'orp', 'ph', 'potassium', 'tds']
        : ['temperature', 'ammonia', 'nitrite', 'nitrate', 'phosphate', 'kh', 'gh', 'alkalinity', 'orp', 'ph', 'potassium', 'tds'];

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
                  ...parameterTypes.map((paramType) {
                    final parameters = groupedParameters[paramType] ?? [];
                    if (parameters.isEmpty) return const SizedBox.shrink();

                    final isExpanded = _expandedParameter == paramType;
                    final color = _getParameterColor(paramType);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
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
                              _getParameterLabel(paramType),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${parameters.length} readings'),
                            trailing: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                            ),
                            onTap: () {
                              setState(() {
                                _expandedParameter =
                                    isExpanded ? null : paramType;
                              });
                            },
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            _buildParameterGraph(parameters, paramType),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'All Readings',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            ...parameters.map((param) => _buildParameterItem(
                                  context,
                                  param,
                                )),
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
          label: const Text('Add Reading'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
              label: const Text('Add First Reading'),
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

  Widget _buildParameterItem(
    BuildContext context,
    WaterParameter parameter,
  ) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final thresholdColor = _getThresholdColor(parameter.parameterType, parameter.value, unit: parameter.unit);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: thresholdColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${parameter.value}${parameter.unit ?? ''}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: thresholdColor,
          ),
        ),
      ),
      title: Text(
        dateFormat.format(parameter.dateRecorded),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: parameter.notes != null
          ? Text(
              parameter.notes!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          : null,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading'),
        content: const Text('Are you sure you want to delete this parameter reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteParameter(parameter);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddParameterSheet extends ConsumerStatefulWidget {
  final Tank tank;
  final WaterParameter? existingParameter;

  const _AddParameterSheet({
    required this.tank,
    this.existingParameter,
  });

  @override
  _AddParameterSheetState createState() => _AddParameterSheetState();
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
    'custom': ['ppm', 'mg/L', '%', 'dKH', 'meq/L', 'mV', 'pH', 'ppt', 'SG', 'dGH', '°F', '°C'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingParameter != null) {
      // Initialize with existing parameter data
      final existingType = widget.existingParameter!.parameterType;
      // Check if it's a predefined parameter type
      if (_unitOptions.containsKey(existingType) && existingType != 'custom') {
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
      _selectedUnit = '°F';
    }
  }

  @override
  void dispose() {
    _customParameterNameController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
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

  void _saveParameter() {
    if (_formKey.currentState!.validate()) {
      final WaterParameter parameter;
      final isEditing = widget.existingParameter != null;
      final parameterType = _getParameterType();
      
      // Additional safety check: prevent saving with empty parameter type
      if (parameterType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a parameter name'),
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
            'has_notes': parameter.notes != null && parameter.notes!.isNotEmpty ? 'true' : 'false',
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
            'has_notes': parameter.notes != null && parameter.notes!.isNotEmpty ? 'true' : 'false',
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
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
                  const DropdownMenuItem(value: 'ammonia', child: Text('Ammonia')),
                  const DropdownMenuItem(value: 'nitrite', child: Text('Nitrite')),
                  const DropdownMenuItem(value: 'nitrate', child: Text('Nitrate')),
                  const DropdownMenuItem(value: 'phosphate', child: Text('Phosphate')),
                  const DropdownMenuItem(value: 'kh', child: Text('KH (Carbonate Hardness)')),
                  const DropdownMenuItem(value: 'gh', child: Text('GH (General Hardness)')),
                  const DropdownMenuItem(value: 'alkalinity', child: Text('Alkalinity')),
                  const DropdownMenuItem(value: 'orp', child: Text('ORP')),
                  const DropdownMenuItem(value: 'ph', child: Text('pH')),
                  const DropdownMenuItem(value: 'potassium', child: Text('Potassium')),
                  const DropdownMenuItem(value: 'tds', child: Text('TDS')),
                  // Only show salinity, calcium, magnesium, and iodine for marine tanks
                  if (widget.tank.type == 'marine') ...[
                    const DropdownMenuItem(value: 'salinity', child: Text('Salinity')),
                    const DropdownMenuItem(value: 'calcium', child: Text('Calcium')),
                    const DropdownMenuItem(value: 'magnesium', child: Text('Magnesium')),
                    const DropdownMenuItem(value: 'iodine', child: Text('Iodine')),
                  ],
                  const DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedParameter = value!;
                    _selectedUnit = _unitOptions[value]!.first;
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
                      items: _unitOptions[_selectedParameter]!
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
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
                onTap: () => _selectDate(context),
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
                        : 'Save Reading'
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
