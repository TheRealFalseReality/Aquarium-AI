import 'package:fish_ai/widgets/ad_component.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../widgets/modern_chip.dart';
import '../services/analytics_service.dart';
import 'stocking_report_screen.dart'; 

class AquariumStockingScreen extends ConsumerStatefulWidget {
  const AquariumStockingScreen({super.key});

  @override
  AquariumStockingScreenState createState() => AquariumStockingScreenState();
}

class AquariumStockingScreenState extends ConsumerState<AquariumStockingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tankSizeController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'freshwater';
  String _selectedUnit = 'gallons';

  @override
  void dispose() {
    _tankSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _getRecommendations() {
    if (_formKey.currentState!.validate()) {
      // Build tank size string with unit
      final tankSizeWithUnit = '${_tankSizeController.text} $_selectedUnit';
      
      // Log actual feature usage
      AnalyticsService.logFeatureUsed(
        featureName: 'aquarium_stocking_assistant',
        parameters: {
          'tank_size': tankSizeWithUnit,
          'tank_type': _selectedCategory,
          'tank_unit': _selectedUnit,
          'has_notes': _notesController.text.isNotEmpty ? 'true' : 'false',
          'notes_length': _notesController.text.length,
        },
      );
      
      ref.read(aquariumStockingProvider.notifier).getStockingRecommendations(
            tankSize: tankSizeWithUnit,
            tankType: _selectedCategory,
            userNotes: _notesController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    ref.listen<AquariumStockingState>(aquariumStockingProvider, (previous, next) {
      // Show/hide loading overlay
      if (next.isLoading && !(previous?.isLoading ?? false)) {
        _showLoadingOverlay(context);
      } else if (!next.isLoading && (previous?.isLoading ?? false)) {
        _hideLoadingOverlay();
      }

      if (next.recommendations != null && next.recommendations!.isNotEmpty) {
        // Build tank size string with unit
        final tankSizeWithUnit = '${_tankSizeController.text} $_selectedUnit';
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockingReportScreen(
              reports: next.recommendations!,
              tankSize: tankSizeWithUnit,
              tankType: _selectedCategory,
              userNotes: _notesController.text,
            ),
          ),
        );
      }
    });

    final state = ref.watch(aquariumStockingProvider);
    final cs = Theme.of(context).colorScheme;
    final hasLastReport = state.lastRecommendations != null && state.lastRecommendations!.isNotEmpty;

    return MainLayout(
      title: 'Aquarium Stocking Assistant',
      bottomNavigationBar: const AdBanner(),
      floatingActionButton: hasLastReport ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StockingReportScreen(reports: state.lastRecommendations!),
            ),
          );
        },
        label: Text(l10n.lastReport),
        icon: const Icon(Icons.history),
      ) : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'AI Stocking Assistant',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get AI-powered stocking ideas for your aquarium.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  ModernSelectableChip(
                    label: 'Freshwater',
                    emoji: '🐟',
                    selected: _selectedCategory == 'freshwater',
                    onTap: () => setState(() => _selectedCategory = 'freshwater'),
                  ),
                  ModernSelectableChip(
                    label: 'Saltwater',
                    emoji: '🐠',
                    selected: _selectedCategory == 'marine',
                    onTap: () => setState(() => _selectedCategory = 'marine'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _tankSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Tank Size',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a tank size';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'gallons', child: Text(l10n.gallons)),
                        DropdownMenuItem(value: 'liters', child: Text(l10n.liters)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUnit = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (e.g., "I want a peaceful community tank")',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400,
                      Colors.blue.shade500,
                      Colors.cyan.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _getRecommendations,
                  icon: state.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(l10n.getRecommendations),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const NativeAdWidget(),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadingOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Prevent back button during loading
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.gettingStockingRecommendations),
                    const SizedBox(height: 8),
                    const Text(
                      'This may take up to 60 seconds',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ref.read(aquariumStockingProvider.notifier).cancel();
                        Navigator.pop(context);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingOverlay() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
