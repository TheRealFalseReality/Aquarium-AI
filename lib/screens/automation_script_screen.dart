import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';

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
      
      // Start the script generation
      final result = await ref
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
    return MainLayout(
      title: 'Script Generator',
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
                      'AI Automation Script Generator',
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
                'Describe the automation you want to create for Home Assistant or ESPHome.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Automation Description',
                  hintText:
                      'e.g., "turn on a pump for 30 seconds every 24 hours"',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 24),
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
                    : const Text('Generate Script'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}