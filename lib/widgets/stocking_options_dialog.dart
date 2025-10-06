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
                
                // Fish name option section
                Text(
                  'Fish Name Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Option 1: Use species names (default)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !_useCustomNames ? cs.primary : cs.outline.withOpacity(0.5),
                      width: !_useCustomNames ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: !_useCustomNames 
                        ? cs.primaryContainer.withOpacity(0.3)
                        : cs.surfaceVariant.withOpacity(0.3),
                  ),
                  child: RadioListTile<bool>(
                    value: false,
                    groupValue: _useCustomNames,
                    onChanged: (value) {
                      setState(() {
                        _useCustomNames = value ?? false;
                      });
                    },
                    title: Text(
                      'Use Fish Species Names',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: !_useCustomNames ? cs.primary : null,
                      ),
                    ),
                    subtitle: const Text(
                      'AI will use the scientific fish species names from the database for recommendations.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Option 2: Use custom names
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _useCustomNames ? cs.primary : cs.outline.withOpacity(0.5),
                      width: _useCustomNames ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _useCustomNames 
                        ? cs.primaryContainer.withOpacity(0.3)
                        : cs.surfaceVariant.withOpacity(0.3),
                  ),
                  child: RadioListTile<bool>(
                    value: true,
                    groupValue: _useCustomNames,
                    onChanged: (value) {
                      setState(() {
                        _useCustomNames = value ?? false;
                      });
                    },
                    title: Text(
                      'Use Custom Names',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _useCustomNames ? cs.primary : null,
                      ),
                    ),
                    subtitle: const Text(
                      'AI will use your custom names. Useful when custom names contain specific fish species for better species-specific results.',
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
