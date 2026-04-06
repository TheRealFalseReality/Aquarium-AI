import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  CalculatorsScreenState createState() => CalculatorsScreenState();
}

class CalculatorsScreenState extends State<CalculatorsScreen> {
  String _activeCalculator = 'Salinity';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'calculators_screen');
  }

  Widget _renderCalculator() {
    switch (_activeCalculator) {
      case 'Salinity':
        return const SalinityConverter();
      case 'CO2':
        return const CarbonDioxideCalculator();
      case 'Alkalinity':
        return const AlkalinityConverter();
      case 'Temperature':
        return const TemperatureConverter();
      case 'Dosing':
        return const DosingCalculator();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const List<String> calculatorTypes = [
      'Salinity',
      'CO2',
      'Alkalinity',
      'Temperature',
      'Dosing',
    ];
    final Map<String, String> calcTypeLabels = {
      'Salinity': l10n.salinity,
      'CO2': l10n.co2Label,
      'Alkalinity': l10n.alkalinity,
      'Temperature': l10n.temperature,
      'Dosing': l10n.dosingCalculator,
    };

    return MainLayout(
      title: l10n.calculators,
      bottomNavigationBar: const AdBanner(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                l10n.aquariumCalculators,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.essentialToolsDescription,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                  child: Column(
                    children: [
                      _buildSectionTitle(context, l10n.calculatorType),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14.0,
                        runSpacing: 12.0,
                        children: calculatorTypes.map((typeName) {
                          final bool isSelected = _activeCalculator == typeName;
                          return ModernSelectableChip(
                            label: calcTypeLabels[typeName]!,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _activeCalculator = typeName;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutBack,
                        child: _renderCalculator(),
                      ),
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

// Helper widget for sub section titles inside calculators
Widget _buildSubSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0, top: 6),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      textAlign: TextAlign.center,
    ),
  );
}

/* ===================== Salinity Converter ====================== */
class SalinityConverter extends StatefulWidget {
  const SalinityConverter({super.key});

  @override
  SalinityConverterState createState() => SalinityConverterState();
}

class SalinityConverterState extends State<SalinityConverter> {
  final _valueController = TextEditingController();
  final _tempController = TextEditingController(text: '25');
  String _fromUnit = 'Salinity (ppt)';
  Map<String, String> _results = {};

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
    // Log calculator usage analytics
    AnalyticsService.logFeatureUsed(
      featureName: 'aquarium_calculator',
      parameters: {
        'calculator_type': 'salinity',
        'from_unit': _fromUnit,
        'has_value': _valueController.text.isNotEmpty ? 'true' : 'false',
        'has_temperature': _tempController.text.isNotEmpty ? 'true' : 'false',
      },
    );

    final double inputValue = double.tryParse(_valueController.text) ?? 0.0;
    final double temp = double.tryParse(_tempController.text) ?? 25.0;
    if (inputValue <= 0) {
      setState(() => _results = {});
      return;
    }
    final logic = SalinityMethods(
      fromUnit: _fromUnit,
      inputValue: inputValue,
      temperature: temp,
    );
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
    final l10n = AppLocalizations.of(context)!;
    // Map from internal state key to localized chip display label
    final Map<String, String> units = {
      'Salinity (ppt)': l10n.salinity,
      'Specific Gravity': l10n.specificGravityAbbr,
      'Density (kg/L)': l10n.density,
      'Conductivity (mS/cm)': l10n.conductivityAbbr,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BannerAdWidget(),
        _buildSubSectionTitle(context, l10n.convertFrom),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 10.0,
          children: units.entries.map((entry) {
            final bool isSelected = _fromUnit == entry.key;
            return ModernSelectableChip(
              label: entry.value,
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.onSecondary,
              dense: true,
              onTap: () => setState(() => _fromUnit = entry.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14.0,
          runSpacing: 14.0,
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: l10n.valueWithUnit(_unitAbbreviation),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _tempController,
                decoration: InputDecoration(
                  labelText: l10n.tempInCelsius,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: _calculate,
          icon: const Icon(Icons.science_outlined),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          label: Text(l10n.convertSalinity),
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 22.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 14,
                  children: [
                    _buildResultColumn(
                      l10n.salinity,
                      '${_results['salinity']} ppt',
                      Colors.teal,
                    ),
                    _buildResultColumn(
                      l10n.specificGravity,
                      '${_results['specificGravity']}',
                      Colors.orange,
                    ),
                    _buildResultColumn(
                      l10n.density,
                      '${_results['density']} kg/L',
                      Colors.purple,
                    ),
                    _buildResultColumn(
                      l10n.conductivity,
                      '${_results['conductivity']} mS/cm',
                      Colors.green,
                    ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
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

/* ===================== CO2 Calculator ====================== */
class CarbonDioxideCalculator extends StatefulWidget {
  const CarbonDioxideCalculator({super.key});

  @override
  CarbonDioxideCalculatorState createState() => CarbonDioxideCalculatorState();
}

class CarbonDioxideCalculatorState extends State<CarbonDioxideCalculator> {
  final _phController = TextEditingController();
  final _dkhController = TextEditingController();
  String _result = '';

  void _calculateCO2() {
    // Log calculator usage analytics
    AnalyticsService.logFeatureUsed(
      featureName: 'aquarium_calculator',
      parameters: {
        'calculator_type': 'co2',
        'has_ph_value': _phController.text.isNotEmpty ? 'true' : 'false',
        'has_dkh_value': _dkhController.text.isNotEmpty ? 'true' : 'false',
      },
    );

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
    final l10n = AppLocalizations.of(context)!;
    const fieldWidth = 200.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          runSpacing: 14.0,
          children: [
            SizedBox(
              width: fieldWidth,
              child: TextField(
                controller: _phController,
                decoration: InputDecoration(
                  labelText: l10n.labelPH,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: TextField(
                controller: _dkhController,
                decoration: InputDecoration(
                  labelText: l10n.labelDKH,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: _calculateCO2,
          icon: const Icon(Icons.bubble_chart_outlined),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          label: Text(l10n.calculateCO2),
        ),
        if (_result.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 22.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 26.0,
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.estimatedCO2Level,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_result ppm',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/* ===================== Alkalinity Converter ====================== */
class AlkalinityConverter extends StatefulWidget {
  const AlkalinityConverter({super.key});

  @override
  AlkalinityConverterState createState() => AlkalinityConverterState();
}

class AlkalinityConverterState extends State<AlkalinityConverter> {
  final _inputValueController = TextEditingController();
  String _fromUnit = 'dKH';
  Map<String, String> _results = {'dkh': '', 'ppm': '', 'meq': ''};

  void _convertAlkalinity() {
    // Log calculator usage analytics
    AnalyticsService.logFeatureUsed(
      featureName: 'aquarium_calculator',
      parameters: {
        'calculator_type': 'alkalinity',
        'from_unit': _fromUnit,
        'has_value': _inputValueController.text.isNotEmpty ? 'true' : 'false',
      },
    );

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
    final l10n = AppLocalizations.of(context)!;
    const List<String> units = ['dKH', 'ppm', 'meq/L'];
    final Map<String, String> unitLabels = {
      'dKH': l10n.labelDKH,
      'ppm': l10n.labelPPM,
      'meq/L': l10n.labelMeqL,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubSectionTitle(context, l10n.convertFrom),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 10.0,
          children: units.map((unitName) {
            final bool isSelected = _fromUnit == unitName;
            return ModernSelectableChip(
              label: unitLabels[unitName]!,
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.onSecondary,
              dense: true,
              onTap: () => setState(() => _fromUnit = unitName),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 260,
            child: TextField(
              controller: _inputValueController,
              decoration: InputDecoration(
                labelText: l10n.valueWithUnit(_fromUnit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: _convertAlkalinity,
          icon: const Icon(Icons.auto_fix_high_outlined),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          label: Text(l10n.convertAlkalinity),
        ),
        if (_results['dkh']!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 22.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultColumn(
                      l10n.labelDKH,
                      _results['dkh']!,
                      Theme.of(context).colorScheme.primary,
                    ),
                    _buildResultColumn(
                      l10n.labelPPM,
                      _results['ppm']!,
                      Theme.of(context).colorScheme.secondary,
                    ),
                    _buildResultColumn(
                      l10n.labelMeqL,
                      _results['meq']!,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultColumn(String label, String value, Color color) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

/* ===================== Temperature Converter ====================== */
class TemperatureConverter extends StatefulWidget {
  const TemperatureConverter({super.key});

  @override
  TemperatureConverterState createState() => TemperatureConverterState();
}

class TemperatureConverterState extends State<TemperatureConverter> {
  final _inputValueController = TextEditingController();
  String _fromUnit = 'Fahrenheit';
  Map<String, String> _results = {'toValue': '', 'kelvin': ''};

  void _convertTemp() {
    // Log calculator usage analytics
    AnalyticsService.logFeatureUsed(
      featureName: 'aquarium_calculator',
      parameters: {
        'calculator_type': 'temperature',
        'from_unit': _fromUnit,
        'has_value': _inputValueController.text.isNotEmpty ? 'true' : 'false',
      },
    );

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
    final l10n = AppLocalizations.of(context)!;
    const List<String> units = ['Fahrenheit', 'Celsius'];
    final Map<String, String> unitLabels = {
      'Fahrenheit': l10n.fahrenheit,
      'Celsius': l10n.celsius,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubSectionTitle(context, l10n.convertFrom),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 10.0,
          children: units.map((unitName) {
            final bool isSelected = _fromUnit == unitName;
            return ModernSelectableChip(
              label: unitLabels[unitName]!,
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.onSecondary,
              dense: true,
              onTap: () => setState(() => _fromUnit = unitName),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 260,
            child: TextField(
              controller: _inputValueController,
              decoration: InputDecoration(
                labelText: l10n.tempFieldLabel(
                  _fromUnit == 'Fahrenheit' ? 'F' : 'C',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: _convertTemp,
          icon: const Icon(Icons.thermostat_auto_outlined),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          label: Text(l10n.convertTemperature),
        ),
        if (_results['toValue']!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 22.0),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultColumn(
                      _fromUnit == 'Fahrenheit'
                          ? l10n.celsius
                          : l10n.fahrenheit,
                      '${_results['toValue']} ${_fromUnit == 'Fahrenheit' ? '°C' : '°F'}',
                      Theme.of(context).colorScheme.primary,
                    ),
                    _buildResultColumn(
                      l10n.kelvin,
                      '${_results['kelvin']} K',
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultColumn(String label, String value, Color color) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

/* ===================== Dosing Calculator ====================== */

/// Data class for pre-filled aquarium chemical dosing presets.
class DosingPreset {
  final String name;
  final double doseAmount;
  final String doseUnit;

  /// Reference volume in gallons this dose applies to.
  final double perGallons;

  const DosingPreset({
    required this.name,
    required this.doseAmount,
    required this.doseUnit,
    required this.perGallons,
  });
}

/// Popular aquarium chemicals with typical maintenance dosing rates.
/// Users should always verify against the product label.
const List<DosingPreset> kDosingPresets = [
  DosingPreset(
    name: 'Prime (Seachem)',
    doseAmount: 1,
    doseUnit: 'mL',
    perGallons: 10,
  ),
  DosingPreset(
    name: 'Stability (Seachem)',
    doseAmount: 5,
    doseUnit: 'mL',
    perGallons: 10,
  ),
  DosingPreset(
    name: 'Flourish (Seachem)',
    doseAmount: 5,
    doseUnit: 'mL',
    perGallons: 60,
  ),
  DosingPreset(
    name: 'Excel (Seachem)',
    doseAmount: 5,
    doseUnit: 'mL',
    perGallons: 50,
  ),
  DosingPreset(
    name: 'Stress Coat (API)',
    doseAmount: 5,
    doseUnit: 'mL',
    perGallons: 10,
  ),
  DosingPreset(
    name: 'Quick Start (API)',
    doseAmount: 10,
    doseUnit: 'mL',
    perGallons: 10,
  ),
  DosingPreset(
    name: 'Stress Zyme (API)',
    doseAmount: 10,
    doseUnit: 'mL',
    perGallons: 10,
  ),
  DosingPreset(
    name: 'Ich-X',
    doseAmount: 5,
    doseUnit: 'mL',
    perGallons: 10,
  ),
  DosingPreset(
    name: 'Paraguard (Seachem)',
    doseAmount: 5,
    doseUnit: 'mL',
    perGallons: 10,
  ),
  DosingPreset(
    name: 'AmGuard (Seachem)',
    doseAmount: 1,
    doseUnit: 'mL',
    perGallons: 20,
  ),
  DosingPreset(
    name: 'Fritz Complete',
    doseAmount: 1,
    doseUnit: 'mL',
    perGallons: 10,
  ),
];

const List<String> _kDoseUnits = [
  'mL',
  'L',
  'oz',
  'tsp',
  'tbsp',
  'drops',
  'gal',
  'cups',
];

class DosingCalculator extends StatefulWidget {
  /// Optional pre-filled tank volume in gallons (e.g. from a saved tank).
  final double? initialTankGallons;

  const DosingCalculator({super.key, this.initialTankGallons});

  @override
  DosingCalculatorState createState() => DosingCalculatorState();
}

class DosingCalculatorState extends State<DosingCalculator> {
  final _doseAmountController = TextEditingController();
  final _perVolumeController = TextEditingController();
  final _tankSizeController = TextEditingController();

  String _selectedChemical = kDosingPresets.first.name;
  String _selectedDoseUnit = kDosingPresets.first.doseUnit;
  String _tankUnit = 'Gallons';
  String? _result;

  @override
  void initState() {
    super.initState();
    _applyPreset(kDosingPresets.first);
    if (widget.initialTankGallons != null) {
      final gallons = widget.initialTankGallons!;
      _tankSizeController.text = gallons.toStringAsFixed(
        gallons == gallons.roundToDouble() ? 0 : 1,
      );
    }
  }

  @override
  void dispose() {
    _doseAmountController.dispose();
    _perVolumeController.dispose();
    _tankSizeController.dispose();
    super.dispose();
  }

  void _applyPreset(DosingPreset preset) {
    _doseAmountController.text = preset.doseAmount.toString();
    _selectedDoseUnit = preset.doseUnit;
    _perVolumeController.text = preset.perGallons.toString();
  }

  void _onChemicalSelected(String? name) {
    if (name == null) return;
    final preset = kDosingPresets.firstWhere(
      (p) => p.name == name,
      orElse: () => kDosingPresets.first,
    );
    setState(() {
      _selectedChemical = name;
      _applyPreset(preset);
      _result = null;
    });
  }

  void _calculate() {
    final doseAmount = double.tryParse(_doseAmountController.text) ?? 0;
    final perVolume = double.tryParse(_perVolumeController.text) ?? 0;
    final tankSize = double.tryParse(_tankSizeController.text) ?? 0;

    if (doseAmount <= 0 || perVolume <= 0 || tankSize <= 0) {
      setState(() => _result = null);
      return;
    }

    // Convert tank size to gallons for unified calculation
    final tankGallons =
        _tankUnit == 'Gallons' ? tankSize : tankSize * 0.264172;

    final totalDose = (tankGallons / perVolume) * doseAmount;
    setState(
      () => _result =
          '${totalDose.toStringAsFixed(2)} $_selectedDoseUnit',
    );

    AnalyticsService.logCalculatorUsed(
      calculatorType: 'dosing',
      inputData: {
        'chemical': _selectedChemical,
        'dose_unit': _selectedDoseUnit,
        'tank_unit': _tankUnit,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chemical selector
        _buildSubSectionTitle(context, l10n.selectChemical),
        DropdownButtonFormField<String>(
          value: _selectedChemical,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: kDosingPresets.map((preset) {
            return DropdownMenuItem(
              value: preset.name,
              child: Text(preset.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: _onChemicalSelected,
        ),
        const SizedBox(height: 24),

        // Dose rate inputs
        _buildSubSectionTitle(context, l10n.doseRate),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14.0,
          runSpacing: 14.0,
          children: [
            SizedBox(
              width: 130,
              child: TextField(
                controller: _doseAmountController,
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() => _result = null),
              ),
            ),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: _selectedDoseUnit,
                decoration: InputDecoration(
                  labelText: l10n.units,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: _kDoseUnits.map((u) {
                  return DropdownMenuItem(value: u, child: Text(u));
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedDoseUnit = v;
                      _result = null;
                    });
                  }
                },
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _perVolumeController,
                decoration: InputDecoration(
                  labelText: '${l10n.perVolumeLabel} (gal)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() => _result = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tank size input
        _buildSubSectionTitle(context, l10n.tankSizeLabel),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14.0,
          runSpacing: 14.0,
          children: [
            SizedBox(
              width: 170,
              child: TextField(
                controller: _tankSizeController,
                decoration: InputDecoration(
                  labelText: l10n.tankSizeLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() => _result = null),
              ),
            ),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String>(
                value: _tankUnit,
                decoration: InputDecoration(
                  labelText: l10n.units,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Gallons',
                    child: Text(l10n.gallons),
                  ),
                  DropdownMenuItem(
                    value: 'Liters',
                    child: Text(l10n.liters),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _tankUnit = v;
                      _result = null;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        ElevatedButton.icon(
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_outlined),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          label: Text(l10n.calculateDose),
        ),

        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 22.0),
            child: Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 26.0,
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.requiredDose,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _result!,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            l10n.dosingCalculatorNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// --- Dart Translation of SalinityMethods (unchanged logic) ---
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
      double conductivity = _calculateConductivityFromSalinity(baseSalinity);
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
      -5.72466e-3 + 1.0227e-4 * temperature - 1.6546e-6 * pow(temperature, 2);
  final double _c = 4.8314e-4;

  double _getPureWaterDensity(double temp) =>
      999.842594 +
      6.793952e-2 * temp -
      9.095290e-3 * pow(temp, 2) +
      1.001685e-4 * pow(temp, 3) -
      1.120083e-6 * pow(temp, 4) +
      6.536332e-9 * pow(temp, 5);

  double _convertToBaseSalinity() {
    switch (fromUnit) {
      case 'Salinity (ppt)':
        return inputValue;
      case 'Specific Gravity':
        return _solveForSalinityFromDensity(
          inputValue * _getPureWaterDensity(temperature),
        );
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
    final gt =
        c0 +
        c1 * temperature +
        c2 * pow(temperature, 2) +
        c3 * pow(temperature, 3) +
        c4 * pow(temperature, 4);
    final rp =
        1.0 +
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
