import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';

/// A dosing calculator that computes the total amount of an aquarium chemical
/// to add based on the dosage per gallon/liter and the tank volume.
///
/// Includes prefilled presets for popular aquarium products.
class DosingCalculator extends StatefulWidget {
  const DosingCalculator({super.key});

  @override
  DosingCalculatorState createState() => DosingCalculatorState();
}

class DosingCalculatorState extends State<DosingCalculator> {
  // ── Options ──────────────────────────────────────────────────────────────
  /// Volume unit: 'Gallons' or 'Liters'
  String _volumeUnit = 'Gallons';

  /// Currently selected preset key, or null for custom.
  String? _selectedPreset;

  // ── Input ─────────────────────────────────────────────────────────────────
  final _tankSizeController = TextEditingController();
  final _doseAmountController = TextEditingController();

  // ── Results ───────────────────────────────────────────────────────────────
  double? _totalDose;
  String _resultUnit = 'mL';

  // ── Prefilled dosing presets ──────────────────────────────────────────────
  // Each preset maps to: (dose per gallon, dose per liter, unit, icon)
  static const Map<String, _DosingPreset> _presets = {
    'seachemPrime': _DosingPreset(
      dosePerGallon: 0.1, // 2 drops ≈ 0.1 mL per gallon
      dosePerLiter: 0.1, // 5 mL per 200 L = 0.025 mL/L, but label says 1 cap (5 mL) per 50 gal
      unit: 'mL',
      icon: Icons.shield_outlined,
    ),
    'seachemStability': _DosingPreset(
      dosePerGallon: 0.1, // 1 capful (5 mL) per 50 gallons ≈ 0.1 mL/gal
      dosePerLiter: 0.025, // 5 mL per 200 L
      unit: 'mL',
      icon: Icons.science_outlined,
    ),
    'seachemFlourish': _DosingPreset(
      dosePerGallon: 0.1, // 1 capful (5 mL) per 50 gallons
      dosePerLiter: 0.025,
      unit: 'mL',
      icon: Icons.grass_outlined,
    ),
    'seachemFlourishExcel': _DosingPreset(
      dosePerGallon: 0.1, // 1 capful (5 mL) per 50 gallons
      dosePerLiter: 0.025,
      unit: 'mL',
      icon: Icons.eco_outlined,
    ),
    'apiStressCoat': _DosingPreset(
      dosePerGallon: 0.2, // 1 mL per 5 gallons = 0.2 mL/gal
      dosePerLiter: 0.05, // 5 mL per 100 L
      unit: 'mL',
      icon: Icons.water_drop_outlined,
    ),
    'apiMelafix': _DosingPreset(
      dosePerGallon: 0.5, // 5 mL per 10 gallons
      dosePerLiter: 0.13,
      unit: 'mL',
      icon: Icons.healing_outlined,
    ),
    'apiPimafix': _DosingPreset(
      dosePerGallon: 0.5, // 5 mL per 10 gallons
      dosePerLiter: 0.13,
      unit: 'mL',
      icon: Icons.local_pharmacy_outlined,
    ),
    'seachemAlkalineBuffer': _DosingPreset(
      dosePerGallon: 0.07, // 1 tsp (~5 g) per 70 gallons
      dosePerLiter: 0.019,
      unit: 'g',
      icon: Icons.balance_outlined,
    ),
    'seachemAcidBuffer': _DosingPreset(
      dosePerGallon: 0.07, // 1 tsp (~5 g) per 70 gallons
      dosePerLiter: 0.019,
      unit: 'g',
      icon: Icons.science_outlined,
    ),
    'fritzsoDechlorinator': _DosingPreset(
      dosePerGallon: 0.2, // 1 mL per 5 gallons
      dosePerLiter: 0.05,
      unit: 'mL',
      icon: Icons.cleaning_services_outlined,
    ),
    'custom': _DosingPreset(
      dosePerGallon: 0,
      dosePerLiter: 0,
      unit: 'mL',
      icon: Icons.edit_outlined,
    ),
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'dosing_calculator');
  }

  @override
  void dispose() {
    _tankSizeController.dispose();
    _doseAmountController.dispose();
    super.dispose();
  }

  // ── Preset selection ─────────────────────────────────────────────────────
  void _selectPreset(String key) {
    final preset = _presets[key]!;
    setState(() {
      _selectedPreset = key;
      if (key != 'custom') {
        final dose = _volumeUnit == 'Gallons'
            ? preset.dosePerGallon
            : preset.dosePerLiter;
        _doseAmountController.text = dose.toString();
        _resultUnit = preset.unit;
      }
      _totalDose = null;
    });
  }

  // ── Calculation ──────────────────────────────────────────────────────────
  void _calculate() {
    final tankSize = double.tryParse(_tankSizeController.text);
    final dosePerUnit = double.tryParse(_doseAmountController.text);

    if (tankSize == null || tankSize <= 0 || dosePerUnit == null || dosePerUnit <= 0) {
      setState(() => _totalDose = null);
      return;
    }

    AnalyticsService.logCalculatorUsed(
      calculatorType: 'dosing',
      inputData: {
        'preset': _selectedPreset ?? 'none',
        'volume_unit': _volumeUnit,
      },
    );

    setState(() {
      _totalDose = tankSize * dosePerUnit;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Localized preset labels
    final Map<String, String> presetLabels = {
      'seachemPrime': l10n.dosingPresetSeachemPrime,
      'seachemStability': l10n.dosingPresetSeachemStability,
      'seachemFlourish': l10n.dosingPresetSeachemFlourish,
      'seachemFlourishExcel': l10n.dosingPresetSeachemFlourishExcel,
      'apiStressCoat': l10n.dosingPresetApiStressCoat,
      'apiMelafix': l10n.dosingPresetApiMelafix,
      'apiPimafix': l10n.dosingPresetApiPimafix,
      'seachemAlkalineBuffer': l10n.dosingPresetSeachemAlkalineBuffer,
      'seachemAcidBuffer': l10n.dosingPresetSeachemAcidBuffer,
      'fritzsoDechlorinator': l10n.dosingPresetFritzsoDechlorinator,
      'custom': l10n.dosingPresetCustom,
    };

    return MainLayout(
      title: l10n.dosingCalculator,
      bottomNavigationBar: const AdBanner(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Title ────────────────────────────────────────────────────────
          Text(
            l10n.dosingCalculator,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dosingCalculatorSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.65),
            ),
            textAlign: TextAlign.center,
          ),

          // ── Volume unit ───────────────────────────────────────────────────
          _buildSectionTitle(context, l10n.units),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ModernSelectableChip(
                label: l10n.gallons,
                selected: _volumeUnit == 'Gallons',
                dense: true,
                selectedColor: cs.secondary,
                selectedTextColor: cs.onSecondary,
                onTap: () {
                  setState(() {
                    _volumeUnit = 'Gallons';
                    _totalDose = null;
                  });
                  if (_selectedPreset != null && _selectedPreset != 'custom') {
                    _selectPreset(_selectedPreset!);
                  }
                },
              ),
              ModernSelectableChip(
                label: l10n.liters,
                selected: _volumeUnit == 'Liters',
                dense: true,
                selectedColor: cs.secondary,
                selectedTextColor: cs.onSecondary,
                onTap: () {
                  setState(() {
                    _volumeUnit = 'Liters';
                    _totalDose = null;
                  });
                  if (_selectedPreset != null && _selectedPreset != 'custom') {
                    _selectPreset(_selectedPreset!);
                  }
                },
              ),
            ],
          ),

          // ── Product presets ───────────────────────────────────────────────
          _buildSectionTitle(context, l10n.dosingPresetTitle),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: _presets.keys.map((key) {
              final preset = _presets[key]!;
              return ModernSelectableChip(
                label: presetLabels[key] ?? key,
                icon: preset.icon,
                selected: _selectedPreset == key,
                onTap: () => _selectPreset(key),
              );
            }).toList(),
          ),

          // ── Tank size input ──────────────────────────────────────────────
          const SizedBox(height: 16),
          const BannerAdWidget(),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 22,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _tankSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.dosingTankSize,
                      hintText: _volumeUnit == 'Gallons'
                          ? 'e.g. 55'
                          : 'e.g. 200',
                      suffixText: _volumeUnit == 'Gallons'
                          ? l10n.gallons
                          : l10n.liters,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.water_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _doseAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.dosingAmountPerUnit(
                        _volumeUnit == 'Gallons'
                            ? l10n.dosingPerGallon
                            : l10n.dosingPerLiter,
                      ),
                      hintText: 'e.g. 0.1',
                      suffixText: _resultUnit,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.science_outlined),
                    ),
                    enabled: _selectedPreset == null ||
                        _selectedPreset == 'custom',
                  ),
                ],
              ),
            ),
          ),

          // ── Calculate button ─────────────────────────────────────────────
          const SizedBox(height: 22),
          Center(
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 28,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              label: Text(l10n.calculate),
            ),
          ),

          // ── Results ──────────────────────────────────────────────────────
          if (_totalDose != null) ...[
            const SizedBox(height: 22),
            _buildResultsSection(context, l10n),
          ],

          // ── Info section ─────────────────────────────────────────────────
          const SizedBox(height: 28),
          _buildInfoSection(context, l10n),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final dose = _totalDose!;
    final tankSize = double.tryParse(_tankSizeController.text) ?? 0;

    // Format the dose nicely
    final String formattedDose =
        dose == dose.roundToDouble()
            ? dose.toStringAsFixed(1)
            : dose.toStringAsFixed(2);

    // If the unit is mL, also show tsp conversion (1 tsp ≈ 5 mL)
    final bool showTsp = _resultUnit == 'mL' && dose >= 1;
    final String tspValue = showTsp ? (dose / 5).toStringAsFixed(2) : '';

    // Show the capful estimate for mL (1 capful ≈ 5 mL for Seachem)
    final bool showCaps = _resultUnit == 'mL' && dose >= 5;
    final String capValue = showCaps ? (dose / 5).toStringAsFixed(1) : '';

    final String presetLabel = _selectedPreset != null &&
            _selectedPreset != 'custom'
        ? _getPresetLabel(context, _selectedPreset!)
        : l10n.dosingPresetCustom;

    return Column(
      children: [
        // ── Total dose card ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.science_rounded, color: cs.primary, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.dosingResultTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dosingResultProduct(presetLabel),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '$formattedDose $_resultUnit',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showTsp) ...[
                  const SizedBox(height: 6),
                  Text(
                    '≈ $tspValue ${l10n.dosingTeaspoons}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onPrimaryContainer.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (showCaps) ...[
                  const SizedBox(height: 4),
                  Text(
                    '≈ $capValue ${l10n.dosingCapfuls}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onPrimaryContainer.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Summary details card ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.secondary, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                Text(
                  l10n.dosingResultSummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildValueChip(
                      context,
                      '${tankSize.toStringAsFixed(1)} ${_volumeUnit == 'Gallons' ? l10n.dosingGalAbbrev : l10n.dosingLAbbrev}',
                      l10n.dosingTankSizeLabel,
                      cs.onSecondaryContainer,
                    ),
                    _buildValueChip(
                      context,
                      '${_doseAmountController.text} $_resultUnit/${_volumeUnit == 'Gallons' ? l10n.dosingGalAbbrev : l10n.dosingLAbbrev}',
                      l10n.dosingDosePerUnitLabel,
                      cs.onSecondaryContainer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueChip(
    BuildContext context,
    String primary,
    String secondary,
    Color textColor,
  ) {
    return Flexible(
      child: Column(
        children: [
          Text(
            primary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            secondary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withOpacity(0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPresetLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'seachemPrime':
        return l10n.dosingPresetSeachemPrime;
      case 'seachemStability':
        return l10n.dosingPresetSeachemStability;
      case 'seachemFlourish':
        return l10n.dosingPresetSeachemFlourish;
      case 'seachemFlourishExcel':
        return l10n.dosingPresetSeachemFlourishExcel;
      case 'apiStressCoat':
        return l10n.dosingPresetApiStressCoat;
      case 'apiMelafix':
        return l10n.dosingPresetApiMelafix;
      case 'apiPimafix':
        return l10n.dosingPresetApiPimafix;
      case 'seachemAlkalineBuffer':
        return l10n.dosingPresetSeachemAlkalineBuffer;
      case 'seachemAcidBuffer':
        return l10n.dosingPresetSeachemAcidBuffer;
      case 'fritzsoDechlorinator':
        return l10n.dosingPresetFritzsoDechlorinator;
      default:
        return l10n.dosingPresetCustom;
    }
  }

  Widget _buildInfoSection(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.dosingInfoTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoTile(
              context,
              Icons.science_outlined,
              l10n.dosingInfoDoseTitle,
              l10n.dosingInfoDoseBody,
              cs,
            ),
            _infoTile(
              context,
              Icons.water_drop_outlined,
              l10n.dosingInfoWaterTitle,
              l10n.dosingInfoWaterBody,
              cs,
            ),
            _infoTile(
              context,
              Icons.warning_amber_outlined,
              l10n.dosingInfoWarningTitle,
              l10n.dosingInfoWarningBody,
              cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    IconData icon,
    String title,
    String body,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for a dosing preset.
class _DosingPreset {
  final double dosePerGallon;
  final double dosePerLiter;
  final String unit;
  final IconData icon;

  const _DosingPreset({
    required this.dosePerGallon,
    required this.dosePerLiter,
    required this.unit,
    required this.icon,
  });
}
