import 'package:flutter/material.dart';

class StockingRecommendationOptions {
  final bool includeCustomNames;
  final String additionalNotes;

  StockingRecommendationOptions({
    required this.includeCustomNames,
    required this.additionalNotes,
  });
}

class StockingRecommendationOptionsDialog extends StatefulWidget {
  const StockingRecommendationOptionsDialog({super.key});

  @override
  State<StockingRecommendationOptionsDialog> createState() => _StockingRecommendationOptionsDialogState();
}

class _StockingRecommendationOptionsDialogState extends State<StockingRecommendationOptionsDialog> {
  bool _includeCustomNames = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('AI Stocking Recommendation Options'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Configure how the AI analyzes your tank for stocking recommendations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            
            // Custom names option
            InkWell(
              onTap: () {
                setState(() {
                  _includeCustomNames = !_includeCustomNames;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _includeCustomNames,
                          onChanged: (value) {
                            setState(() {
                              _includeCustomNames = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Include Custom Names',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        _includeCustomNames
                            ? 'The AI will consider both the database fish names AND your custom names. This is useful when you\'ve set custom names to specific species (e.g., "Neon Tetra" instead of just "My Fish") for more precise, species-specific recommendations.'
                            : 'The AI will only use the fish database names from our compatibility database. This ensures recommendations based on known compatibility data.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
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
              'Add specific requests or preferences to guide the AI\'s recommendations.',
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
                includeCustomNames: _includeCustomNames,
                additionalNotes: _notesController.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('Get Recommendations'),
        ),
      ],
    );
  }
}
