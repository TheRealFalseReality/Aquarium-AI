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
  final _dosePerVolumeController = TextEditingController();

  // ── Results ───────────────────────────────────────────────────────────────
  double? _totalDose;
  String _resultUnit = 'mL';

  // ── Prefilled dosing presets ──────────────────────────────────────────────
  // Each preset stores the bottle-readable dose: amount per volume.
  // E.g. Seachem Prime = 5 mL per 50 gallons (as printed on the bottle).
  static const Map<String, _DosingPreset> _presets = {
    'seachemPrime': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 50,     // 5 mL per 50 gallons
      doseAmountLiter: 5, perVolumeLiter: 200, // 5 mL per 200 L
      unit: 'mL',
      icon: Icons.shield_outlined,
    ),
    'seachemStability': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 50,     // 5 mL per 50 gallons
      doseAmountLiter: 5, perVolumeLiter: 200, // 5 mL per 200 L
      unit: 'mL',
      icon: Icons.science_outlined,
    ),
    'seachemFlourish': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 50,     // 5 mL per 50 gallons
      doseAmountLiter: 5, perVolumeLiter: 200,
      unit: 'mL',
      icon: Icons.grass_outlined,
    ),
    'seachemFlourishExcel': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 50,     // 5 mL per 50 gallons
      doseAmountLiter: 5, perVolumeLiter: 200,
      unit: 'mL',
      icon: Icons.eco_outlined,
    ),
    'apiStressCoat': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 25,     // 5 mL per 25 gallons
      doseAmountLiter: 5, perVolumeLiter: 100, // 5 mL per 100 L
      unit: 'mL',
      icon: Icons.water_drop_outlined,
    ),
    'apiMelafix': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 10,     // 5 mL per 10 gallons
      doseAmountLiter: 5, perVolumeLiter: 38,  // 5 mL per 38 L
      unit: 'mL',
      icon: Icons.healing_outlined,
    ),
    'apiPimafix': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 10,     // 5 mL per 10 gallons
      doseAmountLiter: 5, perVolumeLiter: 38,  // 5 mL per 38 L
      unit: 'mL',
      icon: Icons.local_pharmacy_outlined,
    ),
    'seachemAlkalineBuffer': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 70,     // 1 tsp (~5 g) per 70 gallons
      doseAmountLiter: 5, perVolumeLiter: 265,
      unit: 'g',
      icon: Icons.balance_outlined,
    ),
    'seachemAcidBuffer': _DosingPreset(
      doseAmountGal: 5, perVolumeGal: 70,     // 1 tsp (~5 g) per 70 gallons
      doseAmountLiter: 5, perVolumeLiter: 265,
      unit: 'g',
      icon: Icons.science_outlined,
    ),
    'fritzsoDechlorinator': _DosingPreset(
      doseAmountGal: 1, perVolumeGal: 5,      // 1 mL per 5 gallons
      doseAmountLiter: 5, perVolumeLiter: 95,
      unit: 'mL',
      icon: Icons.cleaning_services_outlined,
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
    _dosePerVolumeController.dispose();
    super.dispose();
  }

  // ── Preset selection ─────────────────────────────────────────────────────
  void _selectPreset(String? key) {
    setState(() {
      _selectedPreset = key;
      if (key != null && key != 'custom') {
        final preset = _presets[key]!;
        if (_volumeUnit == 'Gallons') {
          _doseAmountController.text = _formatNumber(preset.doseAmountGal);
          _dosePerVolumeController.text = _formatNumber(preset.perVolumeGal);
        } else {
          _doseAmountController.text = _formatNumber(preset.doseAmountLiter);
          _dosePerVolumeController.text =
              _formatNumber(preset.perVolumeLiter);
        }
        _resultUnit = preset.unit;
      } else if (key == 'custom') {
        _doseAmountController.clear();
        _dosePerVolumeController.clear();
        _resultUnit = 'mL';
      }
      _totalDose = null;
    });
  }

  /// Format a number for display – drop ".0" for whole numbers.
  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  // ── Calculation ──────────────────────────────────────────────────────────
  void _calculate() {
    final tankSize = double.tryParse(_tankSizeController.text);
    final doseAmount = double.tryParse(_doseAmountController.text);
    final perVolume = double.tryParse(_dosePerVolumeController.text);

    if (tankSize == null ||
        tankSize <= 0 ||
        doseAmount == null ||
        doseAmount <= 0 ||
        perVolume == null ||
        perVolume <= 0) {
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
      _totalDose = (doseAmount / perVolume) * tankSize;
    });
  }

  // ── Preset bottom sheet ──────────────────────────────────────────────────
  void _showPresetPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

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
    };

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.science_outlined, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.dosingPresetTitle,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      // Product presets
                      ..._presets.keys.map((key) {
                        final preset = _presets[key]!;
                        final label = presetLabels[key] ?? key;
                        final isSelected = _selectedPreset == key;
                        final unitAbbrev = _volumeUnit == 'Gallons'
                            ? l10n.dosingGalAbbrev
                            : l10n.dosingLAbbrev;
                        final doseAmt = _volumeUnit == 'Gallons'
                            ? preset.doseAmountGal
                            : preset.doseAmountLiter;
                        final perVol = _volumeUnit == 'Gallons'
                            ? preset.perVolumeGal
                            : preset.perVolumeLiter;
                        final subtitle =
                            '${_formatNumber(doseAmt)} ${preset.unit} per ${_formatNumber(perVol)} $unitAbbrev';

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              preset.icon,
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: Theme.of(ctx)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: cs.primary, size: 22)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => Navigator.pop(ctx, key),
                        );
                      }),
                      // Custom entry option
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedPreset == 'custom'
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: _selectedPreset == 'custom'
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          l10n.dosingPresetCustom,
                          style: TextStyle(
                            fontWeight: _selectedPreset == 'custom'
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _selectedPreset == 'custom'
                                ? cs.primary
                                : cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          l10n.dosingCustomSubtitle,
                          style: Theme.of(ctx)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        trailing: _selectedPreset == 'custom'
                            ? Icon(Icons.check_circle,
                                color: cs.primary, size: 22)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => Navigator.pop(ctx, 'custom'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
        _selectPreset(selected);
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Build the current preset display label
    final String presetDisplayLabel;
    if (_selectedPreset == null) {
      presetDisplayLabel = l10n.dosingSelectProduct;
    } else if (_selectedPreset == 'custom') {
      presetDisplayLabel = l10n.dosingPresetCustom;
    } else {
      presetDisplayLabel = _getPresetLabel(context, _selectedPreset!);
    }

    final bool isCustom = _selectedPreset == null ||
        _selectedPreset == 'custom';

    // Dose description for the selected preset
    String? presetDoseDescription;
    if (_selectedPreset != null &&
        _selectedPreset != 'custom' &&
        _presets.containsKey(_selectedPreset)) {
      final preset = _presets[_selectedPreset]!;
      final unitAbbrev = _volumeUnit == 'Gallons'
          ? l10n.dosingGalAbbrev
          : l10n.dosingLAbbrev;
      final doseAmt = _volumeUnit == 'Gallons'
          ? preset.doseAmountGal
          : preset.doseAmountLiter;
      final perVol = _volumeUnit == 'Gallons'
          ? preset.perVolumeGal
          : preset.perVolumeLiter;
      presetDoseDescription =
          '${_formatNumber(doseAmt)} ${preset.unit} per ${_formatNumber(perVol)} $unitAbbrev';
    }

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

          // ── Product preset selector ───────────────────────────────────────
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _showPresetPicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: _selectedPreset != null && _selectedPreset != 'custom'
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPreset != null && _selectedPreset != 'custom'
                      ? cs.primary.withOpacity(0.5)
                      : cs.outline.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedPreset != null &&
                            _selectedPreset != 'custom' &&
                            _presets.containsKey(_selectedPreset)
                        ? _presets[_selectedPreset]!.icon
                        : Icons.science_outlined,
                    color: _selectedPreset != null &&
                            _selectedPreset != 'custom'
                        ? cs.primary
                        : cs.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          presetDisplayLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedPreset != null &&
                                        _selectedPreset != 'custom'
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface,
                              ),
                        ),
                        if (presetDoseDescription != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            presetDoseDescription,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onPrimaryContainer.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _selectedPreset != null &&
                            _selectedPreset != 'custom'
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Tank size + dose inputs ──────────────────────────────────────
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _doseAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.dosingDoseAmountLabel,
                            hintText: 'e.g. 5',
                            suffixText: _resultUnit,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.science_outlined),
                          ),
                          enabled: isCustom,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l10n.dosingPer,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _dosePerVolumeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: _volumeUnit == 'Gallons'
                                ? l10n.gallons
                                : l10n.liters,
                            hintText: 'e.g. 50',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.straighten_outlined),
                          ),
                          enabled: isCustom,
                        ),
                      ),
                    ],
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

    // Build the dose rate display in bottle-readable format
    final String doseRateDisplay;
    final doseAmt = _doseAmountController.text;
    final perVol = _dosePerVolumeController.text;
    final unitAbbrev = _volumeUnit == 'Gallons'
        ? l10n.dosingGalAbbrev
        : l10n.dosingLAbbrev;
    doseRateDisplay = '$doseAmt $_resultUnit / $perVol $unitAbbrev';

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
                      '${tankSize.toStringAsFixed(1)} $unitAbbrev',
                      l10n.dosingTankSizeLabel,
                      cs.onSecondaryContainer,
                    ),
                    _buildValueChip(
                      context,
                      doseRateDisplay,
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
/// Stores bottle-readable doses: doseAmount per perVolume in both gallon and
/// liter formats. E.g. "5 mL per 50 gallons" → doseAmountGal=5, perVolumeGal=50.
class _DosingPreset {
  final double doseAmountGal;
  final double perVolumeGal;
  final double doseAmountLiter;
  final double perVolumeLiter;
  final String unit;
  final IconData icon;

  const _DosingPreset({
    required this.doseAmountGal,
    required this.perVolumeGal,
    required this.doseAmountLiter,
    required this.perVolumeLiter,
    required this.unit,
    required this.icon,
  });
}
