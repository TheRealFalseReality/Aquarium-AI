import 'package:flutter/material.dart';
import '../models/parameter_log.dart';

class AddParameterLogScreen extends StatefulWidget {
  final bool isSaltwater;

  const AddParameterLogScreen({
    super.key,
    required this.isSaltwater,
  });

  @override
  State<AddParameterLogScreen> createState() => _AddParameterLogScreenState();
}

class _AddParameterLogScreenState extends State<AddParameterLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ammoniaController = TextEditingController();
  final _nitriteController = TextEditingController();
  final _nitrateController = TextEditingController();
  final _phosphateController = TextEditingController();
  final _phController = TextEditingController();
  final _salinityController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSalinitySg = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _ammoniaController.dispose();
    _nitriteController.dispose();
    _nitrateController.dispose();
    _phosphateController.dispose();
    _phController.dispose();
    _salinityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveLog() {
    if (_formKey.currentState!.validate()) {
      // Check if at least one parameter is filled
      if (_ammoniaController.text.isEmpty &&
          _nitriteController.text.isEmpty &&
          _nitrateController.text.isEmpty &&
          _phosphateController.text.isEmpty &&
          _phController.text.isEmpty &&
          _salinityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one parameter value'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final log = ParameterLog.create(
        dateRecorded: _selectedDate,
        ammonia: _ammoniaController.text.isNotEmpty
            ? double.tryParse(_ammoniaController.text)
            : null,
        nitrite: _nitriteController.text.isNotEmpty
            ? double.tryParse(_nitriteController.text)
            : null,
        nitrate: _nitrateController.text.isNotEmpty
            ? double.tryParse(_nitrateController.text)
            : null,
        phosphate: _phosphateController.text.isNotEmpty
            ? double.tryParse(_phosphateController.text)
            : null,
        pH: _phController.text.isNotEmpty
            ? double.tryParse(_phController.text)
            : null,
        salinity: _salinityController.text.isNotEmpty
            ? double.tryParse(_salinityController.text)
            : null,
        isSalinitySg: _isSalinitySg,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      Navigator.of(context).pop(log);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Parameter Log'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date picker
            Card(
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: cs.primary),
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(height: 16),

            // Parameter fields
            Text(
              'Water Parameters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _ammoniaController,
              decoration: InputDecoration(
                labelText: 'Ammonia (ppm)',
                hintText: 'e.g., 0.0',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.science),
                suffixText: 'ppm',
                helperText: 'Ideal: 0 ppm',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Please enter a valid non-negative number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nitriteController,
              decoration: InputDecoration(
                labelText: 'Nitrite (ppm)',
                hintText: 'e.g., 0.0',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.science),
                suffixText: 'ppm',
                helperText: 'Ideal: 0 ppm',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Please enter a valid non-negative number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nitrateController,
              decoration: InputDecoration(
                labelText: 'Nitrate (ppm)',
                hintText: 'e.g., 5.0',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.science),
                suffixText: 'ppm',
                helperText: widget.isSaltwater ? 'Ideal: < 10 ppm' : 'Ideal: < 40 ppm',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Please enter a valid non-negative number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phosphateController,
              decoration: InputDecoration(
                labelText: 'Phosphate (ppm)',
                hintText: 'e.g., 0.03',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.science),
                suffixText: 'ppm',
                helperText: widget.isSaltwater ? 'Ideal: < 0.03 ppm' : 'Ideal: < 1.0 ppm',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Please enter a valid non-negative number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phController,
              decoration: InputDecoration(
                labelText: 'pH',
                hintText: 'e.g., 7.5',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.water_drop),
                helperText: widget.isSaltwater
                    ? 'Ideal: 8.0 - 8.4'
                    : 'Ideal: 6.5 - 7.5 (varies by species)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 14) {
                    return 'Please enter a valid pH value (0-14)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Salinity field (only for saltwater)
            if (widget.isSaltwater) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salinityController,
                      decoration: InputDecoration(
                        labelText: 'Salinity',
                        hintText: _isSalinitySg ? 'e.g., 1.025' : 'e.g., 35',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.water),
                        suffixText: _isSalinitySg ? 'SG' : 'ppt',
                        helperText: _isSalinitySg
                            ? 'Ideal: 1.020 - 1.025 SG'
                            : 'Ideal: 32 - 35 ppt',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final num = double.tryParse(value);
                          if (num == null || num < 0) {
                            return 'Please enter a valid non-negative number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('ppt'),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('SG'),
                          ),
                        ],
                        selected: {_isSalinitySg},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isSalinitySg = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any observations or comments...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _saveLog,
              icon: const Icon(Icons.save),
              label: const Text('Save Log'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
