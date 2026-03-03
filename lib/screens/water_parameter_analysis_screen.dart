import 'package:fish_ai/widgets/ad_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../providers/chat_provider.dart';
import '../services/analytics_service.dart';
import '../utils/api_key_checker.dart';

class WaterParameterAnalysisScreen extends ConsumerStatefulWidget {
  const WaterParameterAnalysisScreen({super.key});

  @override
  TankVolumeCalculatorState createState() => TankVolumeCalculatorState();
}

class TankVolumeCalculatorState
    extends ConsumerState<WaterParameterAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tankTypeController = TextEditingController();
  final _phController = TextEditingController();
  final _tempController = TextEditingController();
  final _salinityController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  bool _isTempFahrenheit = true;
  bool _isSalinitySg = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tankTypeController.dispose();
    _phController.dispose();
    _tempController.dispose();
    _salinityController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  void _submitAnalysis() async {
    if (!checkApiKey(context, ref)) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Log actual feature usage
      AnalyticsService.logFeatureUsed(
        featureName: 'water_parameter_analysis',
        parameters: {
          'tank_type': _tankTypeController.text,
          'has_ph': _phController.text.isNotEmpty ? 'true' : 'false',
          'has_temp': _tempController.text.isNotEmpty ? 'true' : 'false',
          'has_salinity': _salinityController.text.isNotEmpty
              ? 'true'
              : 'false',
          'temp_unit': _isTempFahrenheit ? 'fahrenheit' : 'celsius',
        },
      );

      final params = {
        'tankType': _tankTypeController.text,
        'ph': _phController.text,
        'temp': _tempController.text,
        'salinity': _salinityController.text,
        'additionalInfo': _additionalInfoController.text,
        'tempUnit': _isTempFahrenheit ? 'F' : 'C',
        'salinityUnit': _isSalinitySg ? 'SG' : 'ppt',
      };

      // Start the analysis
      await ref.read(chatProvider.notifier).analyzeWaterParameters(params);

      setState(() => _isSubmitting = false);

      // Close the form after submission, regardless of success/failure
      // The user will see the result in the chat
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: l10n.waterAnalysis,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.aiWaterParameterAnalysis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.enterParametersForAnalysis,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _tankTypeController,
                    decoration: InputDecoration(labelText: l10n.tankTypeLabel),
                    validator: (value) => (value == null || value.isEmpty)
                        ? l10n.pleaseEnterTankType
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tempController,
                          decoration: InputDecoration(
                            labelText: l10n.temperatureLabel,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? l10n.pleaseEnterTemperature
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToggle(['°C', '°F'], _isTempFahrenheit, (
                        isSelected,
                      ) {
                        setState(() => _isTempFahrenheit = isSelected);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phController,
                    decoration: InputDecoration(labelText: l10n.phOptional),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salinityController,
                          decoration: InputDecoration(
                            labelText: l10n.salinityOptional,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToggle(['ppt', 'SG'], _isSalinitySg, (isSelected) {
                        setState(() => _isSalinitySg = isSelected);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _additionalInfoController,
                    decoration: InputDecoration(
                      labelText: l10n.additionalInfoOptional,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const BannerAdWidget(),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAnalysis,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(l10n.submitForAnalysis),
                  ),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Analyzing parameters…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    List<String> labels,
    bool isSelected,
    ValueChanged<bool> onChanged,
  ) {
    return ToggleButtons(
      isSelected: [!isSelected, isSelected],
      onPressed: (index) => onChanged(index == 1),
      borderRadius: BorderRadius.circular(8.0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(labels[0]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(labels[1]),
        ),
      ],
    );
  }
}
