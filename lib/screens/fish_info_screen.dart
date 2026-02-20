import 'package:fish_ai/widgets/ad_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';

class FishInfoScreen extends ConsumerStatefulWidget {
  const FishInfoScreen({super.key});

  @override
  FishInfoScreenState createState() => FishInfoScreenState();
}

class FishInfoScreenState extends ConsumerState<FishInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fishNamesController = TextEditingController();
  final _tankSizeController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fishNamesController.dispose();
    _tankSizeController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  void _submitFishInfoRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      AnalyticsService.logFeatureUsed(
        featureName: 'fish_info_lookup',
        parameters: {
          'fish_names': _fishNamesController.text.length > 100
              ? _fishNamesController.text.substring(0, 100)
              : _fishNamesController.text,
          'has_tank_size': _tankSizeController.text.isNotEmpty ? 'true' : 'false',
          'has_notes': _additionalNotesController.text.isNotEmpty ? 'true' : 'false',
        },
      );

      await ref.read(chatProvider.notifier).getFishInfo(
            fishNames: _fishNamesController.text,
            tankSize: _tankSizeController.text.trim().isEmpty
                ? null
                : _tankSizeController.text.trim(),
            additionalNotes: _additionalNotesController.text.trim().isEmpty
                ? null
                : _additionalNotesController.text.trim(),
          );

      setState(() => _isSubmitting = false);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: l10n.fishInfo,
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
                      l10n.aiFishInfoLookup,
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
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.fishInfoDescription,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fishNamesController,
                decoration: InputDecoration(
                  labelText: l10n.fishNamesLabel,
                  hintText: l10n.fishNamesHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.manage_search_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.pleaseEnterFishName
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tankSizeController,
                decoration: InputDecoration(
                  labelText: l10n.tankSizeOptional,
                  hintText: l10n.tankSizeHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.water_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _additionalNotesController,
                decoration: InputDecoration(
                  labelText: l10n.additionalInfoOptional,
                  hintText: l10n.fishInfoAdditionalNotesHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const BannerAdWidget(),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFishInfoRequest,
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
                    : Text(l10n.lookUpFishInfo),
              ),
              const SizedBox(height: 14),
              const NativeAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
