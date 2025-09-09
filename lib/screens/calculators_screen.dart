// lib/screens/calculators_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../main_layout.dart';

// Main Calculators Screen
class CalculatorsScreen extends StatefulWidget {
  @override
  _CalculatorsScreenState createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  String _activeCalculator = 'CO2'; // Default calculator

  // Method to render the correct calculator widget based on the selection
  Widget _renderCalculator() {
    switch (_activeCalculator) {
      case 'CO2':
        return CarbonDioxideCalculator();
      case 'Alkalinity':
        return AlkalinityConverter();
      case 'Temperature':
        return TemperatureConverter();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Calculators',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Screen Header
              Text(
                'Aquarium Calculators',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Essential tools for your aquarium.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Main content card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Calculator Selector
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'CO2', label: Text('CO₂')),
                          ButtonSegment(
                              value: 'Alkalinity', label: Text('Alkalinity')),
                          ButtonSegment(
                              value: 'Temperature',
                              label: Text('Temperature')),
                        ],
                        selected: {_activeCalculator},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _activeCalculator = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Render the selected calculator widget
                      _renderCalculator(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CarbonDioxideCalculator Widget ---
class CarbonDioxideCalculator extends StatefulWidget {
  @override
  _CarbonDioxideCalculatorState createState() =>
      _CarbonDioxideCalculatorState();
}

class _CarbonDioxideCalculatorState extends State<CarbonDioxideCalculator> {
  final _phController = TextEditingController();
  final _dkhController = TextEditingController();
  String _result = '';

  void _calculateCO2() {
    final phValue = double.tryParse(_phController.text) ?? 0;
    final dkhValue = double.tryParse(_dkhController.text) ?? 0;
    if (phValue > 0 && dkhValue > 0) {
      final phSolution = pow(10.0, 6.37 - phValue);
      final carbonDioxide = (12.839 * dkhValue) * phSolution;
      setState(() {
        _result = carbonDioxide.toStringAsFixed(2);
      });
    } else {
      setState(() {
        _result = '';
      });
    }
  }

  @override
  void dispose() {
    _phController.dispose();
    _dkhController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phController,
          decoration: InputDecoration(
            labelText: 'Enter pH',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dkhController,
          decoration: InputDecoration(
            labelText: 'Enter dKH',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _calculateCO2,
          child: const Text('Calculate CO₂ (ppm)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        if (_result.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Estimated CO₂ Level',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('$_result ppm',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }
}

// --- AlkalinityConverter Widget ---
class AlkalinityConverter extends StatefulWidget {
  @override
  _AlkalinityConverterState createState() => _AlkalinityConverterState();
}

class _AlkalinityConverterState extends State<AlkalinityConverter> {
  final _inputValueController = TextEditingController();
  String _fromUnit = 'dKH';
  Map<String, String> _results = {'dkh': '', 'ppm': '', 'meq': ''};

  void _convertAlkalinity() {
    final value = double.tryParse(_inputValueController.text) ?? 0;
    double dkh = 0, ppm = 0, meq = 0;

    if (value > 0) {
      switch (_fromUnit) {
        case 'dKH':
          dkh = value;
          ppm = value * 17.857;
          meq = value * 0.357;
          break;
        case 'ppm':
          ppm = value;
          dkh = value * 0.056;
          meq = value * 0.02;
          break;
        case 'meq/L':
          meq = value;
          dkh = value * 2.8;
          ppm = value * 50.0;
          break;
      }
      setState(() {
        _results = {
          'dkh': dkh.toStringAsFixed(2),
          'ppm': ppm.toStringAsFixed(2),
          'meq': meq.toStringAsFixed(2),
        };
      });
    } else {
      setState(() {
        _results = {'dkh': '', 'ppm': '', 'meq': ''};
      });
    }
  }

  @override
  void dispose() {
    _inputValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'dKH', label: Text('dKH')),
            ButtonSegment(value: 'ppm', label: Text('ppm')),
            ButtonSegment(value: 'meq/L', label: Text('meq/L')),
          ],
          selected: {_fromUnit},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _fromUnit = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _inputValueController,
          decoration: InputDecoration(
            labelText: 'Enter value in $_fromUnit',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _convertAlkalinity,
          child: const Text('Convert Alkalinity'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        if (_results['dkh']!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultColumn('dKH', _results['dkh']!,
                        Theme.of(context).colorScheme.primary),
                    _buildResultColumn('ppm', _results['ppm']!,
                        Theme.of(context).colorScheme.secondary),
                    _buildResultColumn(
                        'meq/L', _results['meq']!, Colors.green),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildResultColumn(String label, String value, Color color) {
    return Flexible(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// --- TemperatureConverter Widget ---
class TemperatureConverter extends StatefulWidget {
  @override
  _TemperatureConverterState createState() => _TemperatureConverterState();
}

class _TemperatureConverterState extends State<TemperatureConverter> {
  final _inputValueController = TextEditingController();
  String _fromUnit = 'Fahrenheit';
  Map<String, String> _results = {'toValue': '', 'kelvin': ''};

  void _convertTemp() {
    final temp = double.tryParse(_inputValueController.text);
    if (temp == null) {
       setState(() {
        _results = {'toValue': '', 'kelvin': ''};
      });
      return;
    }

    double convertedTemp = 0, kelvin = 0;

    if (_fromUnit == 'Fahrenheit') {
      convertedTemp = (temp - 32) * (5.0 / 9.0);
      kelvin = convertedTemp + 273.15;
    } else {
      // Celsius
      convertedTemp = (temp * (9.0 / 5.0) + 32);
      kelvin = temp + 273.15;
    }
    setState(() {
      _results = {
        'toValue': convertedTemp.toStringAsFixed(2),
        'kelvin': kelvin.toStringAsFixed(2),
      };
    });
  }

   @override
  void dispose() {
    _inputValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Fahrenheit', label: Text('Fahrenheit')),
            ButtonSegment(value: 'Celsius', label: Text('Celsius')),
          ],
          selected: {_fromUnit},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _fromUnit = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _inputValueController,
          decoration: InputDecoration(
            labelText:
                'Enter temperature in °${_fromUnit == 'Fahrenheit' ? 'F' : 'C'}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _convertTemp,
          child: const Text('Convert Temperature'),
           style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        if (_results['toValue']!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultColumn(
                        _fromUnit == 'Fahrenheit' ? 'Celsius' : 'Fahrenheit',
                        '${_results['toValue']}°',
                        Theme.of(context).colorScheme.primary),
                    _buildResultColumn('Kelvin', '${_results['kelvin']} K',
                        Theme.of(context).colorScheme.secondary),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }

   Widget _buildResultColumn(String label, String value, Color color) {
    return Flexible(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}