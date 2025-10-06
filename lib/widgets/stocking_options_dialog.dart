import 'package:flutter/material.dart';

/// Dialog to select stocking recommendation options
class StockingOptionsDialog extends StatefulWidget {
  const StockingOptionsDialog({super.key});

  @override
  State<StockingOptionsDialog> createState() => _StockingOptionsDialogState();
}

class _StockingOptionsDialogState extends State<StockingOptionsDialog> {
  bool _useCustomNames = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'AI Stocking Recommendations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Include custom names option
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: cs.outline.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: cs.surfaceVariant.withOpacity(0.3),
                  ),
                  child: CheckboxListTile(
                    value: _useCustomNames,
                    onChanged: (value) {
                      setState(() {
                        _useCustomNames = value ?? false;
                      });
                    },
                    title: Text(
                      'Include Custom Names',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _useCustomNames ? cs.primary : null,
                      ),
                    ),
                    subtitle: const Text(
                      'Fish types are always included. Enable this to also include your custom names for better species-specific results.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Additional notes section
                Text(
                  'Additional Notes (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add any specific instructions or preferences for the AI. For example, what you want to add next or specific requirements.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g., "Looking for colorful bottom dwellers" or "Need schooling fish for the mid-level"',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'useCustomNames': _useCustomNames,
                          'additionalNotes': _notesController.text.trim(),
                        });
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Get Recommendations'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
