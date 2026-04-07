import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';

class SubstrateCalculator extends StatefulWidget {
  const SubstrateCalculator({super.key});

  @override
  _SubstrateCalculatorState createState() => _SubstrateCalculatorState();
}

class _SubstrateCalculatorState extends State<SubstrateCalculator> {
  // ── Options ──────────────────────────────────────────────────────────────
  /// Bed depth profile: 'Standard', 'Planted', 'DeepBed', 'BareBottom'
  String _bedType = 'Standard';

  /// Volume unit: 'Gallons' or 'Liters'
  String _volumeUnit = 'Gallons';

  // ── Input ─────────────────────────────────────────────────────────────────
  final _volumeController = TextEditingController();

  // ── Results ───────────────────────────────────────────────────────────────
  int? _minPounds;
  int? _maxPounds;
  int? _minKg;
  int? _maxKg;
  int? _minSubLiters;
  int? _maxSubLiters;
  int? _minSubGallons;
  int? _maxSubGallons;
  int? _recPounds;
  int? _recKg;
  int? _recSubLiters;
  int? _recSubGallons;

  // ── Lbs-per-gallon ranges by bed type ─────────────────────────────────────
  // Based on the standard 1–2 lbs/gal rule, scaled for each bed depth profile.
  static const Map<String, (double, double)> _lbsPerGallon = {
    'Standard': (1.0, 2.0),
    'Planted': (2.0, 3.0),
    'DeepBed': (3.0, 4.0),
    'BareBottom': (0.0, 0.0),
  };

  // ── Approximate depth ranges for display (inches) ─────────────────────────
  static const Map<String, (double, double)> _depthRange = {
    'Standard': (1.0, 2.0),
    'Planted': (2.0, 3.0),
    'DeepBed': (3.0, 4.0),
    'BareBottom': (0.0, 0.0),
  };

  // Substrate bulk density: ~100 lbs/ft³ ≈ 3.532 lbs/L
  static const double _lbsPerLiterSubstrate = 100.0 / 28.3168;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'substrate_calculator');
  }

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  // ── Calculation ───────────────────────────────────────────────────────────
  void _calculate() {
    final volume = double.tryParse(_volumeController.text);

    if (volume == null || volume <= 0) {
      setState(() {
        _minPounds = null;
        _maxPounds = null;
        _minKg = null;
        _maxKg = null;
        _minSubLiters = null;
        _maxSubLiters = null;
        _minSubGallons = null;
        _maxSubGallons = null;
        _recPounds = null;
        _recKg = null;
        _recSubLiters = null;
        _recSubGallons = null;
      });
      return;
    }

    AnalyticsService.logCalculatorUsed(
      calculatorType: 'substrate',
      inputData: {
        'bed_type': _bedType,
        'volume_unit': _volumeUnit,
      },
    );

    if (_bedType == 'BareBottom') {
      setState(() {
        _minPounds = 0;
        _maxPounds = 0;
        _minKg = 0;
        _maxKg = 0;
        _minSubLiters = 0;
        _maxSubLiters = 0;
        _minSubGallons = 0;
        _maxSubGallons = 0;
        _recPounds = 0;
        _recKg = 0;
        _recSubLiters = 0;
        _recSubGallons = 0;
      });
      return;
    }

    // Convert to gallons
    final double gallons =
        _volumeUnit == 'Liters' ? volume / 3.78541 : volume;

    final (double minLbsPerGal, double maxLbsPerGal) =
        _lbsPerGallon[_bedType]!;

    final double minLbs = gallons * minLbsPerGal;
    final double maxLbs = gallons * maxLbsPerGal;
    final double recLbs = gallons * (minLbsPerGal + maxLbsPerGal) / 2.0;

    final double minKg = minLbs * 0.453592;
    final double maxKg = maxLbs * 0.453592;
    final double recKg = recLbs * 0.453592;

    final double minSubLiters = minLbs / _lbsPerLiterSubstrate;
    final double maxSubLiters = maxLbs / _lbsPerLiterSubstrate;
    final double recSubLiters = recLbs / _lbsPerLiterSubstrate;

    // 1 US gallon = 3.78541 L
    const double litersPerGallon = 3.78541;
    final double minSubGallons = minSubLiters / litersPerGallon;
    final double maxSubGallons = maxSubLiters / litersPerGallon;
    final double recSubGallons = recSubLiters / litersPerGallon;

    setState(() {
      _minPounds = minLbs.round();
      _maxPounds = maxLbs.round();
      _minKg = minKg.round();
      _maxKg = maxKg.round();
      _minSubLiters = minSubLiters.round();
      _maxSubLiters = maxSubLiters.round();
      _minSubGallons = minSubGallons.round();
      _maxSubGallons = maxSubGallons.round();
      _recPounds = recLbs.round();
      _recKg = recKg.round();
      _recSubLiters = recSubLiters.round();
      _recSubGallons = recSubGallons.round();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final hasResults = _minPounds != null;

    return MainLayout(
      title: l10n.substrateCalculator,
      bottomNavigationBar: const AdBanner(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Title ────────────────────────────────────────────────────────
          Text(
            l10n.substrateCalculator,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.substrateCalculatorSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.65),
            ),
            textAlign: TextAlign.center,
          ),

          // ── Bed type ─────────────────────────────────────────────────────
          _buildSectionTitle(context, l10n.substrateBedType),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              _bedChip(
                context,
                'Standard',
                l10n.substrateBedStandard,
                Icons.layers_outlined,
              ),
              _bedChip(
                context,
                'Planted',
                l10n.substrateBedPlanted,
                Icons.grass_outlined,
              ),
              _bedChip(
                context,
                'DeepBed',
                l10n.substrateBedDeep,
                Icons.terrain_outlined,
              ),
              _bedChip(
                context,
                'BareBottom',
                l10n.substrateBedBare,
                Icons.crop_square_outlined,
              ),
            ],
          ),

          // ── Volume unit ───────────────────────────────────────────────────
          _buildSectionTitle(context, l10n.units),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ModernSelectableChip(
                label: l10n.substrateUnitGallons,
                selected: _volumeUnit == 'Gallons',
                dense: true,
                selectedColor: cs.secondary,
                selectedTextColor: cs.onSecondary,
                onTap: () => setState(() => _volumeUnit = 'Gallons'),
              ),
              ModernSelectableChip(
                label: l10n.substrateUnitLiters,
                selected: _volumeUnit == 'Liters',
                dense: true,
                selectedColor: cs.secondary,
                selectedTextColor: cs.onSecondary,
                onTap: () => setState(() => _volumeUnit = 'Liters'),
              ),
            ],
          ),

          // ── Volume input ─────────────────────────────────────────────────
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
              child: TextField(
                controller: _volumeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.substrateTankVolume,
                  hintText: _volumeUnit == 'Gallons' ? 'e.g. 55' : 'e.g. 200',
                  suffixText: _volumeUnit == 'Gallons'
                      ? l10n.substrateUnitGallons
                      : l10n.substrateUnitLiters,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.water_outlined),
                ),
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
          if (hasResults) ...[
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

  Widget _bedChip(
    BuildContext context,
    String key,
    String label,
    IconData icon,
  ) {
    return ModernSelectableChip(
      label: label,
      icon: icon,
      selected: _bedType == key,
      onTap: () => setState(() => _bedType = key),
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
    final isBareBottom = _bedType == 'BareBottom';

    if (isBareBottom) {
      return _buildColoredCard(
        context,
        backgroundColor: cs.primaryContainer,
        borderColor: cs.primary,
        child: Text(
          l10n.substrateBareBottomResult,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final (double minDepth, double maxDepth) = _depthRange[_bedType]!;
    final depthLabel =
        '${minDepth.toStringAsFixed(0)}–${maxDepth.toStringAsFixed(0)} in'
        ' / ${(minDepth * 2.54).toStringAsFixed(1)}–${(maxDepth * 2.54).toStringAsFixed(1)} cm';

    return Column(
      children: [
        // ── Recommended card ─────────────────────────────────────────────
        _buildColoredCard(
          context,
          backgroundColor: cs.primaryContainer,
          borderColor: cs.primary,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    l10n.substrateResultRecommended,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.substrateResultDepthLabel(depthLabel),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildValueChip(
                    context,
                    _volumeUnit == 'Gallons'
                        ? '$_recPounds lbs'
                        : '$_recKg kg',
                    l10n.substrateResultWeight,
                    cs.onPrimaryContainer,
                  ),
                  _buildValueChip(
                    context,
                    _volumeUnit == 'Gallons'
                        ? '$_recSubGallons gal'
                        : '$_recSubLiters L',
                    l10n.substrateResultVolume,
                    cs.onPrimaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Estimated range card ──────────────────────────────────────────
        _buildColoredCard(
          context,
          backgroundColor: cs.secondaryContainer,
          borderColor: cs.secondary,
          child: Column(
            children: [
              Text(
                l10n.substrateResultRange,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultColumn(
                    context,
                    l10n.substrateResultWeight,
                    _volumeUnit == 'Gallons'
                        ? '$_minPounds–$_maxPounds lbs'
                        : '$_minKg–$_maxKg kg',
                    '',
                    cs.onSecondaryContainer,
                  ),
                  _buildResultColumn(
                    context,
                    l10n.substrateResultVolume,
                    _volumeUnit == 'Gallons'
                        ? '$_minSubGallons–$_maxSubGallons gal'
                        : '$_minSubLiters–$_maxSubLiters L',
                    '',
                    cs.onSecondaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColoredCard(
    BuildContext context, {
    required Color backgroundColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: child,
      ),
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildResultColumn(
    BuildContext context,
    String label,
    String value1,
    String value2,
    Color textColor,
  ) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.85),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (value2.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              value2,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
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
                    l10n.substrateInfoTitle,
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
              Icons.layers_outlined,
              l10n.substrateInfoStandardTitle,
              l10n.substrateInfoStandardBody,
              cs,
            ),
            _infoTile(
              context,
              Icons.grass_outlined,
              l10n.substrateInfoPlantedTitle,
              l10n.substrateInfoPlantedBody,
              cs,
            ),
            _infoTile(
              context,
              Icons.terrain_outlined,
              l10n.substrateInfoDeepTitle,
              l10n.substrateInfoDeepBody,
              cs,
            ),
            _infoTile(
              context,
              Icons.crop_square_outlined,
              l10n.substrateInfoBareTitle,
              l10n.substrateInfoBareBody,
              cs,
            ),
            const Divider(height: 24),
            _infoTile(
              context,
              Icons.scale_outlined,
              l10n.substrateInfoDensityTitle,
              l10n.substrateInfoDensityBody,
              cs,
            ),
            _infoTile(
              context,
              Icons.warning_amber_outlined,
              l10n.substrateInfoTipTitle,
              l10n.substrateInfoTipBody,
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
