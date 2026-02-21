import 'package:flutter/material.dart';

class StockingRecommendationOptions {
  final String additionalNotes;

  StockingRecommendationOptions({
    required this.additionalNotes,
  });
}

class StockingRecommendationOptionsDialog extends StatefulWidget {
  final bool isCompatibilityAnalysis;
  
  const StockingRecommendationOptionsDialog({
    super.key,
    this.isCompatibilityAnalysis = false,
  });

  @override
  State<StockingRecommendationOptionsDialog> createState() => _StockingRecommendationOptionsDialogState();
}

class _StockingRecommendationOptionsDialogState extends State<StockingRecommendationOptionsDialog> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompatibility = widget.isCompatibilityAnalysis;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isCompatibility ? Icons.biotech : Icons.auto_awesome,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(isCompatibility 
              ? 'AI Compatibility Analysis Options' 
              : 'AI Stocking Recommendation Options'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCompatibility
                ? 'Configure how the AI analyzes your tank\'s compatibility.'
                : 'Configure how the AI analyzes your tank for stocking recommendations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            
            // Additional notes field
            Text(
              'Additional Notes (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., "I want to add bottom dwellers" or "Looking for colorful schooling fish"',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompatibility
                ? 'Add specific requests or preferences to guide the AI\'s analysis.'
                : 'Add specific requests or preferences to guide the AI\'s recommendations.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(
              StockingRecommendationOptions(
                additionalNotes: _notesController.text.trim(),
              ),
            );
          },
          icon: Icon(isCompatibility ? Icons.biotech : Icons.auto_awesome, size: 18),
          label: Text(isCompatibility ? 'Analyze Compatibility' : 'Get Recommendations'),
        ),
      ],
    );
  }
}

