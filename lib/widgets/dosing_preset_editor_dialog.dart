import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/dosing_preset.dart';
import '../providers/dosing_presets_provider.dart';

/// Conversion factor: 1 US gallon = 3.78541 liters.
const double gallonsToLiters = 3.78541;

/// Format a number: strip trailing ".0" for whole numbers.
String dosingFmtNum(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// Shows a dialog to add or edit a dosing product preset.
///
/// When [preset] is non-null the dialog enters edit mode.
/// Returns the ID of the newly created (or edited) preset, or `null`
/// if the user cancels.
Future<String?> showDosingPresetEditorDialog(
  BuildContext parentCtx,
  WidgetRef parentRef, {
  DosingPreset? preset,
}) {
  final l10n = AppLocalizations.of(parentCtx)!;
  final isEditing = preset != null;

  final nameCtrl = TextEditingController(text: preset?.name ?? '');
  String selectedUnit = preset?.unit ?? 'mL';

  // The user picks whether they're entering the dose per gallon or per liter.
  bool inputInGallons = true;

  // Pre-fill from gallon values (the "primary" values in the model).
  final doseAmtCtrl = TextEditingController(
      text: preset != null ? dosingFmtNum(preset.doseAmountGal) : '');
  final perVolCtrl = TextEditingController(
      text: preset != null ? dosingFmtNum(preset.perVolumeGal) : '');

  return showDialog<String>(
    context: parentCtx,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setEditorState) {
        final cs = Theme.of(ctx).colorScheme;
        final volumeLabel = inputInGallons
            ? l10n.dosingGalAbbrev
            : l10n.dosingLAbbrev;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(ctx).size.width,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Title ──────────────────────────────────
                    Text(
                      isEditing ? l10n.editProduct : l10n.addProduct,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // ── Product name ──────────────────────────
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.productName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Dose unit (mL / g / drops) ────────────
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: InputDecoration(
                        labelText: l10n.doseUnit,
                        border: const OutlineInputBorder(),
                        prefixIcon:
                            const Icon(Icons.straighten_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'mL', child: Text('mL')),
                        DropdownMenuItem(
                            value: 'g', child: Text('g')),
                        DropdownMenuItem(
                            value: 'drops', child: Text('drops')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setEditorState(() => selectedUnit = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Gal / Liter toggle ────────────────────
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.dosingInputUnit,
                            style: Theme.of(ctx)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text(l10n.dosingGalAbbrev),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text(l10n.dosingLAbbrev),
                            ),
                          ],
                          selected: {inputInGallons},
                          onSelectionChanged: (sel) {
                            setEditorState(() {
                              inputInGallons = sel.first;
                            });
                          },
                          showSelectedIcon: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Dose amount + per volume ──────────────
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: doseAmtCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.doseAmount,
                              suffixText: selectedUnit,
                              border: const OutlineInputBorder(),
                              prefixIcon:
                                  const Icon(Icons.science_outlined),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                          child: Text(
                            l10n.dosingPer,
                            style: Theme.of(ctx)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: perVolCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.perVolume,
                              suffixText: volumeLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon:
                                  const Icon(Icons.water_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Auto-convert note ─────────────────────
                    Text(
                      l10n.autoConvertedNote,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // ── Actions ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final doseAmt =
                                double.tryParse(doseAmtCtrl.text);
                            final perVol =
                                double.tryParse(perVolCtrl.text);

                            if (name.isEmpty ||
                                doseAmt == null ||
                                perVol == null ||
                                doseAmt <= 0 ||
                                perVol <= 0) {
                              return;
                            }

                            // Auto-convert to the other unit system.
                            final double doseGal;
                            final double perGal;
                            final double doseLiter;
                            final double perLiter;

                            if (inputInGallons) {
                              doseGal = doseAmt;
                              perGal = perVol;
                              doseLiter = doseAmt;
                              perLiter = perVol * gallonsToLiters;
                            } else {
                              doseLiter = doseAmt;
                              perLiter = perVol;
                              doseGal = doseAmt;
                              perGal = perVol / gallonsToLiters;
                            }

                            final notifier = parentRef
                                .read(dosingPresetsProvider.notifier);

                            String resultId;
                            if (isEditing) {
                              notifier.updatePreset(preset.copyWith(
                                name: name,
                                doseAmountGal: doseGal,
                                perVolumeGal: perGal,
                                doseAmountLiter: doseLiter,
                                perVolumeLiter: perLiter,
                                unit: selectedUnit,
                              ));
                              resultId = preset.id;
                            } else {
                              final newPreset = DosingPreset.create(
                                name: name,
                                doseAmountGal: doseGal,
                                perVolumeGal: perGal,
                                doseAmountLiter: doseLiter,
                                perVolumeLiter: perLiter,
                                unit: selectedUnit,
                              );
                              notifier.addPreset(newPreset);
                              resultId = newPreset.id;
                            }
                            Navigator.pop(ctx, resultId);
                          },
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
