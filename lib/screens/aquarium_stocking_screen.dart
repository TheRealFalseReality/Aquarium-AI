import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../widgets/modern_chip.dart';
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

  @override
  void dispose() {
    _tankSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _getRecommendations() {
    if (_formKey.currentState!.validate()) {
      ref.read(aquariumStockingProvider.notifier).getStockingRecommendations(
            tankSize: _tankSizeController.text,
            tankType: _selectedCategory,
            userNotes: _notesController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AquariumStockingState>(aquariumStockingProvider, (previous, next) {
      if (next.recommendations != null && next.recommendations!.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockingReportScreen(reports: next.recommendations!),
          ),
        );
      }
    });

    final state = ref.watch(aquariumStockingProvider);
    final hasLastReport = state.lastRecommendations != null && state.lastRecommendations!.isNotEmpty;

    return MainLayout(
      title: 'Aquarium Stocking Assistant',
      floatingActionButton: hasLastReport ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StockingReportScreen(reports: state.lastRecommendations!),
            ),
          );
        },
        label: const Text('Last Report'),
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
              TextFormField(
                controller: _tankSizeController,
                decoration: const InputDecoration(
                  labelText: 'Tank Size (e.g., "55" or "200 liters")',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a tank size';
                  }
                  return null;
                },
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
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : _getRecommendations,
                icon: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
                    : const Icon(Icons.auto_awesome),
                label: const Text('Get Recommendations'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}