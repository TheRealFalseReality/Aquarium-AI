import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';

/// A widget that renders interactive Plotly.js charts using WebView.
/// This provides a more interactive and feature-rich charting experience
/// compared to native Flutter chart libraries.
class PlotlyChartWidget extends StatefulWidget {
  /// The data points to display on the chart.
  /// Each entry should contain:
  /// - 'date': DateTime of the measurement
  /// - 'value': double value of the measurement
  /// - 'color': Color for the data point (optional)
  /// - 'unit': String unit label (optional)
  final List<Map<String, dynamic>> dataPoints;

  /// The color of the line chart.
  final Color lineColor;

  /// The title to display on the chart.
  final String title;

  /// The unit to display on the y-axis.
  final String unit;

  /// Height of the chart widget.
  final double height;

  const PlotlyChartWidget({
    super.key,
    required this.dataPoints,
    required this.lineColor,
    required this.title,
    this.unit = '',
    this.height = 220,
  });

  @override
  State<PlotlyChartWidget> createState() => _PlotlyChartWidgetState();
}

class _PlotlyChartWidgetState extends State<PlotlyChartWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void didUpdateWidget(PlotlyChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload chart when data changes
    if (oldWidget.dataPoints != widget.dataPoints ||
        oldWidget.lineColor != widget.lineColor) {
      _loadPlotlyChart();
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
    _loadPlotlyChart();
  }

  void _loadPlotlyChart() {
    final htmlContent = _generatePlotlyHtml();
    _controller.loadHtmlString(htmlContent);
  }

  String _colorToHex(Color color) {
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.opacity})';
  }

  String _generatePlotlyHtml() {
    // Prepare data for Plotly
    final List<String> xValues = [];
    final List<double> yValues = [];
    final List<String> markerColors = [];
    final List<String> hoverText = [];
    final dateFormat = DateFormat('MMM d');

    for (var point in widget.dataPoints) {
      final date = point['date'] as DateTime;
      final value = point['value'] as double;
      final color = point['color'] as Color? ?? widget.lineColor;
      final unit = point['unit'] as String? ?? widget.unit;

      xValues.add('"${dateFormat.format(date)}"');
      yValues.add(value);
      markerColors.add('"${_colorToHex(color)}"');
      hoverText.add('"${dateFormat.format(date)}: ${value.toStringAsFixed(2)}$unit"');
    }

    // Calculate min/max for better y-axis display
    if (yValues.isEmpty) {
      return _generateEmptyChartHtml();
    }

    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;
    final yPadding = yRange * 0.1;
    final adjustedMinY = minY - yPadding;
    final adjustedMaxY = maxY + yPadding;

    // Get theme colors (use a neutral approach that works in both themes)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? '#ffffff' : '#333333';
    final gridColor = isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)';
    final backgroundColor = isDarkMode ? '#1a1a1a' : '#ffffff';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://cdn.plot.ly/plotly-2.27.0.min.js"></script>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: $backgroundColor;
      overflow: hidden;
    }
    #chart {
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <div id="chart"></div>
  <script>
    var trace = {
      x: [${xValues.join(', ')}],
      y: [${yValues.join(', ')}],
      type: 'scatter',
      mode: 'lines+markers',
      name: '${widget.title}',
      text: [${hoverText.join(', ')}],
      hoverinfo: 'text',
      line: {
        color: '${_colorToHex(widget.lineColor)}',
        width: 3,
        shape: 'spline'
      },
      marker: {
        size: 8,
        color: [${markerColors.join(', ')}],
        line: {
          color: '#ffffff',
          width: 2
        }
      },
      fill: 'tozeroy',
      fillcolor: '${_colorToHex(widget.lineColor.withOpacity(0.1))}'
    };

    var layout = {
      margin: {
        l: 45,
        r: 15,
        t: 10,
        b: 35
      },
      paper_bgcolor: '$backgroundColor',
      plot_bgcolor: '$backgroundColor',
      xaxis: {
        showgrid: true,
        gridcolor: '$gridColor',
        tickfont: {
          color: '$textColor',
          size: 10
        },
        tickangle: -45
      },
      yaxis: {
        showgrid: true,
        gridcolor: '$gridColor',
        tickfont: {
          color: '$textColor',
          size: 10
        },
        range: [$adjustedMinY, $adjustedMaxY],
        title: {
          text: '${widget.unit}',
          font: {
            color: '$textColor',
            size: 11
          }
        }
      },
      showlegend: false,
      hovermode: 'closest',
      dragmode: false
    };

    var config = {
      responsive: true,
      displayModeBar: false,
      staticPlot: false
    };

    Plotly.newPlot('chart', [trace], layout, config);
  </script>
</body>
</html>
''';
  }

  String _generateEmptyChartHtml() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? '#ffffff' : '#333333';
    final backgroundColor = isDarkMode ? '#1a1a1a' : '#ffffff';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100%;
      background-color: $backgroundColor;
      color: $textColor;
      font-family: sans-serif;
    }
  </style>
</head>
<body>
  <p>No data available</p>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: widget.lineColor,
              ),
            ),
        ],
      ),
    );
  }
}
