import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';

class WaterParameterAnalysisScreen extends ConsumerStatefulWidget {
  const WaterParameterAnalysisScreen({super.key});

  @override
  TankVolumeCalculatorState createState() =>
      TankVolumeCalculatorState();
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
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
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
      final result = await ref.read(chatProvider.notifier).analyzeWaterParameters(params);

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
    return MainLayout(
      title: 'Water Analysis',
      child: SingleChildScrollView(
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
                      'AI Water Parameter Analysis',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your aquarium\'s parameters below for an expert AI analysis.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tankTypeController,
                decoration: const InputDecoration(
                    labelText: 'Tank Type (e.g., Reef, Freshwater)'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter a tank type' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempController,
                      decoration:
                          const InputDecoration(labelText: 'Temperature'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter a temperature'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildToggle(['°C', '°F'], _isTempFahrenheit, (isSelected) {
                    setState(() => _isTempFahrenheit = isSelected);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phController,
                decoration: const InputDecoration(labelText: 'pH (Optional)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salinityController,
                      decoration:
                          const InputDecoration(labelText: 'Salinity (Optional)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                decoration:
                    const InputDecoration(labelText: 'Additional Info (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnalysis,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit for Analysis'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(
      List<String> labels, bool isSelected, ValueChanged<bool> onChanged) {
    return ToggleButtons(
      isSelected: [!isSelected, isSelected],
      onPressed: (index) => onChanged(index == 1),
      borderRadius: BorderRadius.circular(8.0),
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(labels[0])),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(labels[1])),
      ],
    );
  }
}