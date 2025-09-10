// lib/models/automation_script.dart

class AutomationScript {
  final String title;
  final String explanation;
  final String code;

  AutomationScript({
    required this.title,
    required this.explanation,
    required this.code,
  });

  factory AutomationScript.fromJson(Map<String, dynamic> json) {
    return AutomationScript(
      title: json['title'] ?? 'Automation Script',
      explanation: json['explanation'] ?? 'No explanation provided.',
      code: json['code'] ?? '# No code generated',
    );
  }
}