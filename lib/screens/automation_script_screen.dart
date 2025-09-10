// lib/screens/automation_script_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';
import 'automation_script_result_screen.dart';

class AutomationScriptScreen extends ConsumerStatefulWidget {
  const AutomationScriptScreen({super.key});

  @override
  _AutomationScriptScreenState createState() => _AutomationScriptScreenState();
}

class _AutomationScriptScreenState
    extends ConsumerState<AutomationScriptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitScriptRequest() async {
    if (_formKey.currentState!.validate()) {
      final script = await ref
          .read(chatProvider.notifier)
          .generateAutomationScript(_descriptionController.text);
      if (mounted && script != null) {
        Navigator.pop(context); // Close the form
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AutomationScriptResultScreen(script: script),
          ),
        );
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
                  Text(
                    'AI Automation Script Generator',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                onPressed: _submitScriptRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Generate Script'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}