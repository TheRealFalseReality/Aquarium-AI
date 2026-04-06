import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';

class SubstrateCalculator extends StatefulWidget {
  const SubstrateCalculator({super.key});

  @override
  SubstrateCalculatorState createState() => SubstrateCalculatorState();
}

class SubstrateCalculatorState extends State<SubstrateCalculator> {
  // ── Options ──────────────────────────────────────────────────────────────
  /// Bed depth profile: 'Standard', 'Planted', 'DeepBed', 'BareBottom'
  String _bedType = 'Standard';

  /// Tank footprint units: 'Inches' or 'cm'
  String _units = 'Inches';

  // ── Inputs ────────────────────────────────────────────────────────────────
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();

  // ── Results ───────────────────────────────────────────────────────────────
  double? _minPounds;
  double? _maxPounds;
  double? _minKg;
  double? _maxKg;
  double? _minLiters;
  double? _maxLiters;
  double? _depthInInches;

  // ── Bed type depth ranges (inches) ────────────────────────────────────────
  static const Map<String, (double, double)> _depthRange = {
    'Standard': (1.0, 2.0),
    'Planted': (2.0, 3.0),
    'DeepBed': (3.0, 4.0),
    'BareBottom': (0.0, 0.0),
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'substrate_calculator');
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  // ── Calculation ───────────────────────────────────────────────────────────
  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);

    if (length == null || width == null || length <= 0 || width <= 0) {
      setState(() {
        _minPounds = null;
        _maxPounds = null;
        _minKg = null;
        _maxKg = null;
        _minLiters = null;
        _maxLiters = null;
        _depthInInches = null;
      });
      return;
    }

    AnalyticsService.logCalculatorUsed(
      calculatorType: 'substrate',
      inputData: {
        'bed_type': _bedType,
        'units': _units,
      },
    );

    // Convert inputs to inches
    final double lengthIn =
        _units == 'cm' ? length / 2.54 : length;
    final double widthIn = _units == 'cm' ? width / 2.54 : width;

    final (double minDepth, double maxDepth) = _depthRange[_bedType]!;

    if (_bedType == 'BareBottom') {
      setState(() {
        _minPounds = 0;
        _maxPounds = 0;
        _minKg = 0;
        _maxKg = 0;
        _minLiters = 0;
        _maxLiters = 0;
        _depthInInches = 0;
      });
      return;
    }

    // Volume in cubic inches = L × W × depth
    final double minVolIn3 = lengthIn * widthIn * minDepth;
    final double maxVolIn3 = lengthIn * widthIn * maxDepth;

    // Substrate density: ~100 lbs/ft³ ≈ 0.0579 lbs/in³ (dry bulk density)
    // 1 ft³ = 1728 in³, 100 lbs / 1728 in³ ≈ 0.0579 lbs/in³
    const double lbsPerIn3 = 100.0 / 1728.0;

    final double minLbs = minVolIn3 * lbsPerIn3;
    final double maxLbs = maxVolIn3 * lbsPerIn3;
    final double minKg = minLbs * 0.453592;
    final double maxKg = maxLbs * 0.453592;

    // Volume in liters (1 in³ = 0.016387 L)
    const double litersPerIn3 = 0.016387;
    final double minLiters = minVolIn3 * litersPerIn3;
    final double maxLiters = maxVolIn3 * litersPerIn3;

    setState(() {
      _minPounds = minLbs;
      _maxPounds = maxLbs;
      _minKg = minKg;
      _maxKg = maxKg;
      _minLiters = minLiters;
      _maxLiters = maxLiters;
      _depthInInches = (minDepth + maxDepth) / 2;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmt(double? v) =>
      v == null ? '' : v.toStringAsFixed(1);

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

          // ── Units ─────────────────────────────────────────────────────────
          _buildSectionTitle(context, l10n.units),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ModernSelectableChip(
                label: l10n.unitInches,
                selected: _units == 'Inches',
                dense: true,
                selectedColor: cs.secondary,
                selectedTextColor: cs.onSecondary,
                onTap: () => setState(() => _units = 'Inches'),
              ),
              ModernSelectableChip(
                label: l10n.unitCm,
                selected: _units == 'cm',
                dense: true,
                selectedColor: cs.secondary,
                selectedTextColor: cs.onSecondary,
                onTap: () => setState(() => _units = 'cm'),
              ),
            ],
          ),

          // ── Inputs ───────────────────────────────────────────────────────
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
                    controller: _lengthController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.substrateLength,
                      hintText: _units == 'Inches' ? 'e.g. 48' : 'e.g. 120',
                      suffixText: _units == 'Inches'
                          ? l10n.unitInches
                          : l10n.unitCm,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.straighten_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _widthController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.substrateWidth,
                      hintText: _units == 'Inches' ? 'e.g. 18' : 'e.g. 45',
                      suffixText: _units == 'Inches'
                          ? l10n.unitInches
                          : l10n.unitCm,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.swap_horiz_outlined),
                    ),
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
          if (hasResults) ...[
            const SizedBox(height: 22),
            _buildResultsCard(context, l10n),
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

  Widget _buildResultsCard(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final isBareBottom = _bedType == 'BareBottom';

    if (isBareBottom) {
      return Card(
        color: cs.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Text(
            l10n.substrateBareBottomResult,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final (double minDepth, double maxDepth) = _depthRange[_bedType]!;
    final depthLabel = _units == 'Inches'
        ? '${minDepth.toStringAsFixed(0)}–${maxDepth.toStringAsFixed(0)} ${l10n.unitInches}'
        : '${(minDepth * 2.54).toStringAsFixed(1)}–${(maxDepth * 2.54).toStringAsFixed(1)} ${l10n.unitCm}';

    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          children: [
            Text(
              l10n.substrateResultTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.substrateResultDepthLabel(depthLabel),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultColumn(
                  context,
                  l10n.substrateResultWeight,
                  '${_fmt(_minPounds)}–${_fmt(_maxPounds)} lbs',
                  '${_fmt(_minKg)}–${_fmt(_maxKg)} kg',
                  cs.primary,
                ),
                _buildResultColumn(
                  context,
                  l10n.substrateResultVolume,
                  '${_fmt(_minLiters)}–${_fmt(_maxLiters)} L',
                  '',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultColumn(
    BuildContext context,
    String label,
    String value1,
    String value2,
    Color color,
  ) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (value2.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              value2,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
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
