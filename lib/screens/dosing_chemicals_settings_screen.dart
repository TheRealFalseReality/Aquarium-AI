import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/dosing_chemical.dart';
import '../providers/dosing_chemicals_provider.dart';
import '../services/analytics_service.dart';

class DosingChemicalsSettingsScreen extends ConsumerStatefulWidget {
  const DosingChemicalsSettingsScreen({super.key});

  @override
  ConsumerState<DosingChemicalsSettingsScreen> createState() =>
      _DosingChemicalsSettingsScreenState();
}

class _DosingChemicalsSettingsScreenState
    extends ConsumerState<DosingChemicalsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'dosing_chemicals_settings');
  }

  Future<void> _showChemicalEditor({
    DosingChemical? initial,
    required AppLocalizations l10n,
  }) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final amountController = TextEditingController(
      text: initial?.amountPerUnit.toString() ?? '',
    );
    final doseUnitController = TextEditingController(text: initial?.doseUnit ?? 'mL');
    String selectedPerUnit = initial?.perUnit ?? 'gallon';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                initial == null
                    ? l10n.dosingChemicalAddTitle
                    : l10n.dosingChemicalEditTitle,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.dosingChemicalNameLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.dosingAmountPerVolumeLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPerUnit,
                      items: [
                        DropdownMenuItem(
                          value: 'gallon',
                          child: Text(l10n.substrateUnitGallons),
                        ),
                        DropdownMenuItem(
                          value: 'liter',
                          child: Text(l10n.substrateUnitLiters),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedPerUnit = value);
                      },
                      decoration: InputDecoration(labelText: l10n.dosingPerUnitLabel),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: doseUnitController,
                      decoration: InputDecoration(
                        labelText: l10n.dosingDoseUnitLabel,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text.trim());
                    final unit = doseUnitController.text.trim();
                    if (name.isEmpty || amount == null || amount <= 0 || unit.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.dosingChemicalValidationError)),
                      );
                      return;
                    }

                    if (initial == null) {
                      await ref
                          .read(dosingChemicalsProvider.notifier)
                          .addChemical(
                            DosingChemical.create(
                              name: name,
                              amountPerUnit: amount,
                              perUnit: selectedPerUnit,
                              doseUnit: unit,
                            ),
                          );
                      AnalyticsService.logFeatureUsed(
                        featureName: 'dosing_chemical_added',
                        parameters: {'per_unit': selectedPerUnit},
                      );
                    } else {
                      await ref
                          .read(dosingChemicalsProvider.notifier)
                          .updateChemical(
                            initial.copyWith(
                              name: name,
                              amountPerUnit: amount,
                              perUnit: selectedPerUnit,
                              doseUnit: unit,
                            ),
                          );
                      AnalyticsService.logFeatureUsed(
                        featureName: 'dosing_chemical_updated',
                        parameters: {'per_unit': selectedPerUnit},
                      );
                    }

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chemicalsState = ref.watch(dosingChemicalsProvider);

    return MainLayout(
      title: l10n.dosingChemicalsTitle,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showChemicalEditor(l10n: l10n),
          icon: const Icon(Icons.add),
          label: Text(l10n.add),
        ),
        body: chemicalsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : chemicalsState.chemicals.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.dosingChemicalsEmpty,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chemicalsState.chemicals.length,
                onReorder: (oldIndex, newIndex) {
                  ref
                      .read(dosingChemicalsProvider.notifier)
                      .reorderChemicals(oldIndex, newIndex);
                  AnalyticsService.logFeatureUsed(
                    featureName: 'dosing_chemical_reordered',
                  );
                },
                itemBuilder: (context, index) {
                  final chemical = chemicalsState.chemicals[index];
                  final perUnitText = chemical.perUnit == 'gallon'
                      ? l10n.substrateUnitGallons
                      : l10n.substrateUnitLiters;
                  return Card(
                    key: ValueKey(chemical.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.medication_liquid_outlined, size: 28),
                      ),
                      title: Text(chemical.name),
                      subtitle: Text(
                        '${chemical.amountPerUnit} ${chemical.doseUnit} / $perUnitText',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.edit,
                            onPressed: () =>
                                _showChemicalEditor(initial: chemical, l10n: l10n),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: l10n.delete,
                            onPressed: () {
                              ref
                                  .read(dosingChemicalsProvider.notifier)
                                  .removeChemical(chemical.id);
                              AnalyticsService.logFeatureUsed(
                                featureName: 'dosing_chemical_deleted',
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
