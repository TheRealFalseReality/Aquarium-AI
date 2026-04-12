import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/dosing_preset.dart';
import '../providers/custom_chemicals_provider.dart';
import '../services/analytics_service.dart';

/// Screen for managing the user's list of aquarium chemicals.
/// Accessible from Settings → Manage Chemicals.
class ChemicalManagementScreen extends ConsumerStatefulWidget {
  const ChemicalManagementScreen({super.key});

  @override
  ConsumerState<ChemicalManagementScreen> createState() =>
      _ChemicalManagementScreenState();
}

class _ChemicalManagementScreenState
    extends ConsumerState<ChemicalManagementScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'chemical_management_screen');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(customChemicalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageChemicals),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.resetToDefaults),
                    content: Text(l10n.resetChemicalsConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.error,
                        ),
                        child: Text(l10n.reset),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await ref
                      .read(customChemicalsProvider.notifier)
                      .resetToDefaults();
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.restore, size: 18),
                    const SizedBox(width: 8),
                    Flexible(child: Text(l10n.resetToDefaults)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.chemicals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noChemicals,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showAddEditDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addChemical),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.dragToReorder,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: state.chemicals.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(customChemicalsProvider.notifier)
                          .reorderChemical(oldIndex, newIndex);
                    },
                    itemBuilder: (ctx, index) {
                      final chemical = state.chemicals[index];
                      return _buildChemicalTile(ctx, chemical, index);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: state.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addChemical),
            ),
    );
  }

  Widget _buildChemicalTile(
    BuildContext context,
    DosingPreset chemical,
    int index,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final hasRate =
        chemical.doseAmount != null &&
        chemical.doseUnit != null &&
        chemical.perGallons != null;
    final rateText = hasRate
        ? '${chemical.doseAmount} ${chemical.doseUnit} / ${chemical.perGallons} gal'
        : l10n.noStandardRate;

    return Card(
      key: ValueKey('chem_$index'),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.science_outlined,
            color: cs.primary,
            size: 20,
          ),
        ),
        title: Text(
          chemical.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          rateText,
          style: TextStyle(
            fontSize: 12,
            color: hasRate
                ? cs.onSurface.withValues(alpha: 0.7)
                : cs.onSurface.withValues(alpha: 0.4),
            fontStyle: hasRate ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showAddEditDialog(context, index: index),
              tooltip: l10n.editChemical,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
              onPressed: () => _confirmDelete(context, index),
              tooltip: l10n.deleteChemical,
            ),
            const Icon(Icons.drag_indicator, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(
    BuildContext context, {
    int? index,
  }) async {
    final chemicals = ref.read(customChemicalsProvider).chemicals;
    final existing = index != null ? chemicals[index] : null;
    final result = await showDialog<DosingPreset>(
      context: context,
      builder: (ctx) => _ChemicalEditDialog(existing: existing),
    );
    if (result != null && mounted) {
      if (index != null) {
        await ref
            .read(customChemicalsProvider.notifier)
            .updateChemical(index, result);
      } else {
        await ref
            .read(customChemicalsProvider.notifier)
            .addChemical(result);
        AnalyticsService.logFeatureUsed(
          featureName: 'chemical_added',
          parameters: {'has_rate': (result.doseAmount != null).toString()},
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final chemical = ref.read(customChemicalsProvider).chemicals[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteChemical),
        content: Text(l10n.deleteChemicalConfirm(chemical.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(customChemicalsProvider.notifier).removeChemical(index);
    }
  }
}

/// Dialog for adding or editing a chemical entry.
class _ChemicalEditDialog extends StatefulWidget {
  final DosingPreset? existing;
  const _ChemicalEditDialog({this.existing});

  @override
  State<_ChemicalEditDialog> createState() => _ChemicalEditDialogState();
}

class _ChemicalEditDialogState extends State<_ChemicalEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _perGallonsCtrl;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
      text: e?.doseAmount?.toString() ?? '',
    );
    _perGallonsCtrl = TextEditingController(
      text: e?.perGallons?.toString() ?? '',
    );
    _selectedUnit = e?.doseUnit ?? 'mL';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _perGallonsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.editChemical : l10n.addChemical),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.chemicalName} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.science_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.doseRateOptional,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              // Amount + unit row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.amount,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          if (double.tryParse(v) == null) {
                            return l10n.invalidNumber;
                          }
                          if (double.parse(v) <= 0) {
                            return l10n.mustBePositive;
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: l10n.unit,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      items: kDoseUnits
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedUnit = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Per gallons
              TextFormField(
                controller: _perGallonsCtrl,
                decoration: InputDecoration(
                  labelText: l10n.perGallons,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  suffixText: 'gal',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (double.tryParse(v) == null) return l10n.invalidNumber;
                    if (double.parse(v) <= 0) return l10n.mustBePositive;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amountText = _amountCtrl.text.trim();
              final perText = _perGallonsCtrl.text.trim();
              Navigator.pop(
                context,
                DosingPreset(
                  name: _nameCtrl.text.trim(),
                  doseAmount: amountText.isNotEmpty
                      ? double.parse(amountText)
                      : null,
                  doseUnit: amountText.isNotEmpty ? _selectedUnit : null,
                  perGallons: perText.isNotEmpty ? double.parse(perText) : null,
                ),
              );
            }
          },
          child: Text(isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
