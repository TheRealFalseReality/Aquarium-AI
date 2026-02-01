import 'package:fish_ai/widgets/ad_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';
import '../services/analytics_service.dart';

class AutomationScriptScreen extends ConsumerStatefulWidget {
  const AutomationScriptScreen({super.key});

  @override
  AutomationScriptScreenState createState() => AutomationScriptScreenState();
}

class AutomationScriptScreenState
    extends ConsumerState<AutomationScriptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitScriptRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      // Log actual feature usage
      AnalyticsService.logFeatureUsed(
        featureName: 'automation_script',
        parameters: {
          'description_length': _descriptionController.text.length,
          'has_description': _descriptionController.text.isNotEmpty ? 'true' : 'false',
        },
      );
      
      // Start the script generation
      await ref
          .read(chatProvider.notifier)
          .generateAutomationScript(_descriptionController.text);
      
      setState(() => _isSubmitting = false);
          
      // Close the form after submission
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: l10n.automationScript,
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
                      l10n.aiAutomationScriptGenerator,
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
                l10n.automationDescription,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.automationDescriptionLabel,
                  hintText: l10n.automationDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.pleaseEnterDescription
                    : null,
              ),
              const SizedBox(height: 24),
              const BannerAdWidget(),
            const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitScriptRequest,
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
                    : Text(l10n.generateScript),
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
