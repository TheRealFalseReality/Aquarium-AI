import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/dosing_entry.dart';
import '../models/tank.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';

class DosingLoggerScreen extends ConsumerStatefulWidget {
  final Tank tank;
  final bool openAddDialog;

  const DosingLoggerScreen({
    super.key,
    required this.tank,
    this.openAddDialog = false,
  });

  @override
  DosingLoggerScreenState createState() => DosingLoggerScreenState();
}

class DosingLoggerScreenState extends ConsumerState<DosingLoggerScreen> {
  String? _expandedTreatment;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'dosing_logger_screen');
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addDosingEntry(context);
      });
    }
  }

  Tank _getCurrentTank() {
    // Get the latest tank state from the provider
    final tanks = ref.watch(tankProvider).tanks;
    return tanks.firstWhere(
      (t) => t.id == widget.tank.id,
      orElse: () => widget.tank,
    );
  }

  void _addDosingEntry(BuildContext context) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddDosingEntrySheet(tank: currentTank),
    );
  }

  void _editDosingEntry(BuildContext context, DosingEntry entry) {
    final currentTank = _getCurrentTank();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _AddDosingEntrySheet(tank: currentTank, existingEntry: entry),
    );
  }

  void _deleteDosingEntry(DosingEntry entry) {
    final currentTank = _getCurrentTank();
    final updatedEntries = currentTank.dosingEntries
        .where((e) => e.id != entry.id)
        .toList();
    final updatedTank = currentTank.copyWith(
      dosingEntries: updatedEntries,
      updatedAt: DateTime.now(),
    );
    ref.read(tankProvider.notifier).updateTank(updatedTank);

    // Log dosing entry deletion
    AnalyticsService.logFeatureUsed(
      featureName: 'dosing_entry_deleted',
      parameters: {
        'treatment_name': entry.treatmentName,
        'tank_type': currentTank.type,
        'remaining_entries': updatedEntries.length,
      },
    );

    AnalyticsService.logTankAction(
      action: 'dosing_entry_deleted',
      tankType: currentTank.type,
    );
  }

  Map<String, List<DosingEntry>> _groupEntriesByTreatment(Tank tank) {
    final grouped = <String, List<DosingEntry>>{};
    for (var entry in tank.dosingEntries) {
      if (!grouped.containsKey(entry.treatmentName)) {
        grouped[entry.treatmentName] = [];
      }
      grouped[entry.treatmentName]!.add(entry);
    }
    // Sort each group by date (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.dateDosed.compareTo(a.dateDosed));
    });
    return grouped;
  }

  IconData _getTreatmentIcon() {
    return Icons.medication_liquid;
  }

  Color _getTreatmentColor() {
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tank = _getCurrentTank();
    final groupedEntries = _groupEntriesByTreatment(tank);
    final cs = Theme.of(context).colorScheme;

    return MainLayout(
      title: '${tank.name} - Dosing Diary',
      child: Scaffold(
        appBar: AppBar(
          title: Text(tank.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addDosingEntry(context),
              tooltip: l10n.addDose,
            ),
          ],
        ),
        body: tank.dosingEntries.isEmpty
            ? _buildEmptyState(context)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Dosing Diary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track treatments and supplements added to your aquarium',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Summary card
                  _buildSummaryCard(context, tank),
                  const SizedBox(height: 16),

                  // Grouped entries
                  ...groupedEntries.entries.map((entry) {
                    final treatmentName = entry.key;
                    final entries = entry.value;
                    final isExpanded = _expandedTreatment == treatmentName;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getTreatmentColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getTreatmentIcon(),
                                color: _getTreatmentColor(),
                              ),
                            ),
                            title: Text(
                              treatmentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${entries.length} ${entries.length == 1 ? l10n.dose : l10n.doses}',
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  _expandedTreatment = isExpanded
                                      ? null
                                      : treatmentName;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _expandedTreatment = isExpanded
                                    ? null
                                    : treatmentName;
                              });
                            },
                          ),
                          if (isExpanded)
                            Column(
                              children: [
                                const Divider(height: 1),
                                ...entries.map(
                                  (entry) => _buildDosingItem(context, entry),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addDosingEntry(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.addDose),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_liquid_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Dosing Records Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking treatments and supplements\nadded to your aquarium',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _addDosingEntry(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFirstDose),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final uniqueTreatments = tank.dosingEntries
        .map((e) => e.treatmentName)
        .toSet()
        .length;
    final totalDoses = tank.dosingEntries.length;
    final lastDose = tank.dosingEntries.isNotEmpty
        ? tank.dosingEntries.reduce(
            (a, b) => a.dateDosed.isAfter(b.dateDosed) ? a : b,
          )
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.dosingSum,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.totalDoses,
                    totalDoses.toString(),
                    Icons.medication,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.treatments,
                    uniqueTreatments.toString(),
                    Icons.inventory_2,
                  ),
                ),
              ],
            ),
            if (lastDose != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Last dose: ${DateFormat('MMM d, yyyy').format(lastDose.dateDosed)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDosingItem(BuildContext context, DosingEntry entry) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 56,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getTreatmentColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${entry.amount}${entry.unit}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getTreatmentColor(),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      title: Text(
        dateFormat.format(entry.dateDosed),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: entry.notes != null && entry.notes!.isNotEmpty
          ? Text(
              entry.notes!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: cs.primary,
            onPressed: () => _editDosingEntry(context, entry),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _showDeleteDialog(context, entry),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DosingEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDose),
        content: Text(l10n.deleteDoseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              _deleteDosingEntry(entry);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _AddDosingEntrySheet extends ConsumerStatefulWidget {
  final Tank tank;
  final DosingEntry? existingEntry;

  const _AddDosingEntrySheet({required this.tank, this.existingEntry});

  @override
  ConsumerState<_AddDosingEntrySheet> createState() =>
      _AddDosingEntrySheetState();
}

// Volume units for dosing entries
const List<String> kVolumeUnits = [
  'mL',
  'L',
  'oz',
  'tsp',
  'tbsp',
  'drops',
  'gal',
  'cups',
];

// Common aquarium treatments
const List<String> kCommonTreatments = [
  'Prime (Seachem)',
  'Stability (Seachem)',
  'Flourish (Seachem)',
  'Excel (Seachem)',
  'Stress Coat (API)',
  'Quick Start (API)',
  'Stress Zyme (API)',
  'Ich-X',
  'Paraguard (Seachem)',
  'Kanaplex (Seachem)',
  'MetroPlex (Seachem)',
  'Focus (Seachem)',
  'AmGuard (Seachem)',
  'Safe (Seachem)',
  'Purigen (Seachem)',
  'Alkalinity Buffer',
  'pH Buffer',
  'Other (Custom)',
];

class _AddDosingEntrySheetState extends ConsumerState<_AddDosingEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _treatmentNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedUnit;
  String? _selectedTreatment;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      // Initialize with existing entry data
      final existingName = widget.existingEntry!.treatmentName;
      if (kCommonTreatments.contains(existingName)) {
        _selectedTreatment = existingName;
      } else {
        _selectedTreatment = 'Other (Custom)';
        _treatmentNameController.text = existingName;
      }
      _amountController.text = widget.existingEntry!.amount.toString();
      _notesController.text = widget.existingEntry!.notes ?? '';
      _selectedDate = widget.existingEntry!.dateDosed;
      _selectedUnit = widget.existingEntry!.unit;
    } else {
      // Initialize with default values for new entry
      _selectedDate = DateTime.now();
      _selectedUnit = 'mL';
      _selectedTreatment = kCommonTreatments.first;
    }
  }

  @override
  void dispose() {
    _treatmentNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _getTreatmentName() {
    // If "Other (Custom)" is selected, use the text field value
    if (_selectedTreatment == 'Other (Custom)') {
      return _treatmentNameController.text.trim();
    }
    // Otherwise use the selected treatment from dropdown
    return _selectedTreatment ?? _treatmentNameController.text.trim();
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final DosingEntry entry;
      final isEditing = widget.existingEntry != null;
      final treatmentName = _getTreatmentName();

      if (isEditing) {
        // Update existing entry
        entry = widget.existingEntry!.copyWith(
          treatmentName: treatmentName,
          amount: double.parse(_amountController.text),
          unit: _selectedUnit,
          dateDosed: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        // Replace the existing entry in the list
        final updatedEntries = widget.tank.dosingEntries.map((e) {
          return e.id == entry.id ? entry : e;
        }).toList();

        final updatedTank = widget.tank.copyWith(
          dosingEntries: updatedEntries,
          updatedAt: DateTime.now(),
        );

        ref.read(tankProvider.notifier).updateTank(updatedTank);

        // Log dosing entry update
        AnalyticsService.logFeatureUsed(
          featureName: 'dosing_entry_updated',
          parameters: {
            'treatment_name': entry.treatmentName,
            'tank_type': widget.tank.type,
            'unit': entry.unit,
          },
        );
      } else {
        // Create new entry
        entry = DosingEntry.create(
          treatmentName: treatmentName,
          amount: double.parse(_amountController.text),
          unit: _selectedUnit,
          dateDosed: _selectedDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        final updatedEntries = [...widget.tank.dosingEntries, entry];
        final updatedTank = widget.tank.copyWith(
          dosingEntries: updatedEntries,
          updatedAt: DateTime.now(),
        );

        ref.read(tankProvider.notifier).updateTank(updatedTank);

        // Log dosing entry addition
        AnalyticsService.logFeatureUsed(
          featureName: 'dosing_entry_added',
          parameters: {
            'treatment_name': entry.treatmentName,
            'tank_type': widget.tank.type,
            'unit': entry.unit,
            'has_notes': entry.notes != null ? 'true' : 'false',
          },
        );

        AnalyticsService.logTankAction(
          action: 'dosing_entry_added',
          tankType: widget.tank.type,
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existingEntry != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Dose' : 'Add Dose',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Treatment dropdown
              DropdownButtonFormField<String>(
                value: _selectedTreatment,
                decoration: InputDecoration(
                  labelText: 'Treatment Type *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medication_liquid),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                items: kCommonTreatments.map((treatment) {
                  return DropdownMenuItem(
                    value: treatment,
                    child: Text(treatment),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTreatment = value;
                    // Clear custom name when switching away from "Other"
                    if (value != 'Other (Custom)') {
                      _treatmentNameController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a treatment type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom treatment name (shown only when "Other" is selected)
              if (_selectedTreatment == 'Other (Custom)') ...[
                TextFormField(
                  controller: _treatmentNameController,
                  decoration: InputDecoration(
                    labelText: 'Custom Treatment Name *',
                    hintText: 'Enter treatment name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (_selectedTreatment == 'Other (Custom)' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter a treatment name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Amount and unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.science),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                      ),
                      items: kVolumeUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date selection
              InkWell(
                onTap: () => _selectDate(),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date & Time',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy - h:mm a').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional information...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Update Dose' : 'Save Dose'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the dosing add/edit bottom sheet.
/// [existingEntry] – pass to edit an existing entry.
void showDosingSheet(
  BuildContext context,
  Tank tank, {
  DosingEntry? existingEntry,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _AddDosingEntrySheet(tank: tank, existingEntry: existingEntry),
  );
}
