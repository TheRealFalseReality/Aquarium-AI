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
  String _activeCalculator = 'Salinity';

  Widget _renderCalculator() {
    switch (_activeCalculator) {
      case 'Salinity':
        return SalinityConverter();
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> calculatorTypes = [
      'Salinity',
      'CO2',
      'Alkalinity',
      'Temperature'
    ];

    return MainLayout(
      title: 'Calculators',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSectionTitle(context, 'Calculator Type'),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: calculatorTypes.map((typeName) {
                          final bool isSelected = _activeCalculator == typeName;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeCalculator = typeName;
                              });
                            },
                            child: Chip(
                              label: Text(typeName == 'CO2' ? 'CO₂' : typeName),
                              backgroundColor: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
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

// Helper widget for section titles inside calculators
Widget _buildSubSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
      textAlign: TextAlign.center,
    ),
  );
}

// --- SalinityConverter Widget ---
class SalinityConverter extends StatefulWidget {
  @override
  _SalinityConverterState createState() => _SalinityConverterState();
}

class _SalinityConverterState extends State<SalinityConverter> {
  final _valueController = TextEditingController();
  final _tempController = TextEditingController(text: '25');
  String _fromUnit = 'Salinity (ppt)';
  Map<String, String> _results = {};

  // UPDATED: Getter for unit abbreviation
  String get _unitAbbreviation {
    switch (_fromUnit) {
      case 'Salinity (ppt)':
        return 'ppt';
      case 'Specific Gravity':
        return 'SG';
      case 'Density (kg/L)':
        return 'kg/L';
      case 'Conductivity (mS/cm)':
        return 'mS/cm';
      default:
        return '';
    }
  }

  void _calculate() {
    final double inputValue = double.tryParse(_valueController.text) ?? 0.0;
    final double temp = double.tryParse(_tempController.text) ?? 25.0;
    if (inputValue <= 0) {
      setState(() => _results = {});
      return;
    }
    final logic = SalinityMethods(
        fromUnit: _fromUnit, inputValue: inputValue, temperature: temp);
    setState(() => _results = logic.calculate());
  }

  @override
  void dispose() {
    _valueController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Map<String, String> units = {
      'Salinity (ppt)': 'Salinity',
      'Specific Gravity': 'SG',
      'Density (kg/L)': 'Density',
      'Conductivity (mS/cm)': 'Conduct.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubSectionTitle(context, 'Convert From Unit'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: units.entries.map((entry) {
            final bool isSelected = _fromUnit == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _fromUnit = entry.key),
              child: Chip(
                label: Text(entry.value),
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            SizedBox(
              width: 180,
              child: TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  // UPDATED LABEL
                  labelText: 'Enter value ($_unitAbbreviation)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _tempController,
                decoration: InputDecoration(
                  labelText: 'Temp (°C)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _calculate,
          child: const Text('Convert Salinity'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildResultColumn('Salinity', '${_results['salinity']} ppt',
                        Theme.of(context).colorScheme.primary),
                    _buildResultColumn('Specific Gravity',
                        '${_results['specificGravity']}', Colors.orange),
                    _buildResultColumn('Density', '${_results['density']} kg/L',
                        Theme.of(context).colorScheme.secondary),
                    _buildResultColumn('Conductivity',
                        '${_results['conductivity']} mS/cm', Colors.green),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultColumn(String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
          ),
        ),
      ],
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
      setState(() => _result = carbonDioxide.toStringAsFixed(2));
    } else {
      setState(() => _result = '');
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _phController,
                decoration: InputDecoration(
                  labelText: 'Enter pH',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _dkhController,
                decoration: InputDecoration(
                  labelText: 'Enter dKH',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
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
    const List<String> units = ['dKH', 'ppm', 'meq/L'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubSectionTitle(context, 'Convert From Unit'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: units.map((unitName) {
            final bool isSelected = _fromUnit == unitName;
            return GestureDetector(
              onTap: () => setState(() => _fromUnit = unitName),
              child: Chip(
                label: Text(unitName),
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 250,
            child: TextField(
              controller: _inputValueController,
              decoration: InputDecoration(
                labelText: 'Enter value in $_fromUnit',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
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
      setState(() => _results = {'toValue': '', 'kelvin': ''});
      return;
    }
    double convertedTemp = 0, kelvin = 0;
    if (_fromUnit == 'Fahrenheit') {
      convertedTemp = (temp - 32) * (5.0 / 9.0);
      kelvin = convertedTemp + 273.15;
    } else {
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
    const List<String> units = ['Fahrenheit', 'Celsius'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubSectionTitle(context, 'Convert From Unit'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          children: units.map((unitName) {
            final bool isSelected = _fromUnit == unitName;
            return GestureDetector(
              onTap: () => setState(() => _fromUnit = unitName),
              child: Chip(
                label: Text(unitName),
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 250,
            child: TextField(
              controller: _inputValueController,
              decoration: InputDecoration(
                labelText:
                    'Enter temp in °${_fromUnit == 'Fahrenheit' ? 'F' : 'C'}',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
            ),
          ),
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
                        '${_results['toValue']} ${_fromUnit == 'Fahrenheit' ? '°C' : '°F'}',
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

// --- Dart Translation of SalinityMethods ---
class SalinityMethods {
  final String fromUnit;
  final double inputValue;
  final double temperature;

  SalinityMethods({
    required this.fromUnit,
    required this.inputValue,
    this.temperature = 25.0,
  });

  Map<String, String> calculate() {
    try {
      double baseSalinity = _convertToBaseSalinity();
      if (baseSalinity < 0) return {};
      double density = _calculateDensityFromSalinity(baseSalinity);
      double specificGravity = density / _getPureWaterDensity(temperature);
      double conductivity =
          _calculateConductivityFromSalinity(baseSalinity);
      return {
        'salinity': baseSalinity.toStringAsFixed(2),
        'specificGravity': specificGravity.toStringAsFixed(3),
        'density': density.toStringAsFixed(2),
        'conductivity': conductivity.toStringAsFixed(2),
      };
    } catch (e) {
      return {};
    }
  }

  double _getA() =>
      8.24493e-1 -
      4.0899e-3 * temperature +
      7.6438e-5 * pow(temperature, 2) -
      8.2467e-7 * pow(temperature, 3) +
      5.3875e-9 * pow(temperature, 4);
  double _getB() =>
      -5.72466e-3 +
      1.0227e-4 * temperature -
      1.6546e-6 * pow(temperature, 2);
  final double _c = 4.8314e-4;

  double _getPureWaterDensity(double temp) =>
      999.842594 +
      6.793952e-2 * temp -
      9.095290e-3 * pow(temp, 2) +
      1.001685e-4 * pow(temp, 3) -
      1.120083e-6 * pow(temp, 4) +
      6.536332e-9 * pow(temp, 5);

  double _convertToBaseSalinity() {
    final rROoTD = _getPureWaterDensity(temperature);
    switch (fromUnit) {
      case 'Salinity (ppt)':
        return inputValue;
      case 'Specific Gravity':
        return _solveForSalinityFromDensity(inputValue * rROoTD);
      case 'Density (kg/L)':
        return _solveForSalinityFromDensity(inputValue);
      case 'Conductivity (mS/cm)':
        return _salinityFromConductivity(inputValue);
      default:
        return 0;
    }
  }

  double _solveForSalinityFromDensity(double targetDensity) {
    double s2 = 0, ro = 0, j = 0;
    final rROo = _getPureWaterDensity(temperature);
    final a = _getA(), b = _getB();
    do {
      s2 = j / 1000.0;
      ro = rROo + a * s2 + b * pow(s2, 1.5) + _c * pow(s2, 2);
      j++;
      if (j > 100000) return -1;
    } while (ro <= targetDensity);
    return s2;
  }

  double _calculateDensityFromSalinity(double sal) {
    final rROo = _getPureWaterDensity(temperature);
    return rROo + _getA() * sal + _getB() * pow(sal, 1.5) + _c * pow(sal, 2);
  }

  double _calculateConductivityFromSalinity(double targetSalinity) {
    double cond = 0, sal = 0, i = 0;
    do {
      cond = i / 1000.0;
      sal = _salinityFromConductivity(cond);
      i++;
      if (i > 100000) return -1;
    } while (sal <= targetSalinity);
    return cond;
  }

  double _salinityFromConductivity(double cond) {
    final double r = cond / 42.914;
    final double p = 0.0;
    final c0 = 0.6766097;
    final c1 = 0.0200564;
    final c2 = 0.0001104259;
    final c3 = -0.00000069698;
    final c4 = 0.0000000010031;
    final gt = c0 +
        c1 * temperature +
        c2 * pow(temperature, 2) +
        c3 * pow(temperature, 3) +
        c4 * pow(temperature, 4);
    final rp = 1.0 +
        (2.07e-5 * p - 6.37e-10 * p + 3.989e-15 * p) /
            (1.0 +
                (3.426e-2 * temperature +
                    4.464e-4 * pow(temperature, 2) +
                    4.215e-1 * r -
                    3.107e-3 * temperature * r));
    final rt = r / (gt * rp);
    final salCorrection =
        ((temperature - 15) / (1 + 0.0162 * (temperature - 15))) *
            (0.0005 -
                0.0056 * sqrt(rt) -
                0.0066 * rt -
                0.0375 * pow(rt, 1.5) +
                0.0636 * pow(rt, 2) -
                0.0144 * pow(rt, 2.5));
    return 0.008 -
        0.1692 * sqrt(rt) +
        25.3851 * rt +
        14.0941 * pow(rt, 1.5) -
        7.0261 * pow(rt, 2) +
        2.7081 * pow(rt, 2.5) +
        salCorrection;
  }
}