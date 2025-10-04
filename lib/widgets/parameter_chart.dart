import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/parameter_log.dart';

class ParameterChart extends StatelessWidget {
  final List<ParameterLog> logs;
  final String parameter;
  final Color color;

  const ParameterChart({
    super.key,
    required this.logs,
    required this.parameter,
    required this.color,
  });

  List<FlSpot> _getDataPoints() {
    final sortedLogs = List<ParameterLog>.from(logs)
      ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedLogs.length; i++) {
      final log = sortedLogs[i];
      double? value;
      
      switch (parameter) {
        case 'Ammonia':
          value = log.ammonia;
          break;
        case 'Nitrite':
          value = log.nitrite;
          break;
        case 'Nitrate':
          value = log.nitrate;
          break;
        case 'Phosphate':
          value = log.phosphate;
          break;
        case 'pH':
          value = log.pH;
          break;
        case 'Salinity':
          value = log.salinity;
          break;
      }
      
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getDataPoints();
    
    if (spots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No data available for this parameter'),
        ),
      );
    }

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return Padding(
      padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: null,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
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
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= logs.length) {
                    return const Text('');
                  }
                  final sortedLogs = List<ParameterLog>.from(logs)
                    ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
                  final date = sortedLogs[value.toInt()].dateRecorded;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: null,
                reservedSize: 42,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.left,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY - padding < 0 ? 0 : minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final sortedLogs = List<ParameterLog>.from(logs)
                    ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
                  final log = sortedLogs[barSpot.x.toInt()];
                  return LineTooltipItem(
                    '$parameter: ${barSpot.y.toStringAsFixed(2)}\n${log.dateRecorded.month}/${log.dateRecorded.day}/${log.dateRecorded.year}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
