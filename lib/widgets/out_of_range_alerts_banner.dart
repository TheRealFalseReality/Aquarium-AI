import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/parameter_range_alerts.dart';

/// A card banner that lists every out-of-range parameter reading.
///
/// [alerts] must be sorted most-severe first (critical → warning → caution).
/// [parameterLabel] converts a parameter type key (e.g. `'ammonia'`) to its
/// localised display name; pass `_parameterLabel(type, context)` or the
/// equivalent helper from the calling screen.
class OutOfRangeAlertsBanner extends StatelessWidget {
  const OutOfRangeAlertsBanner({
    super.key,
    required this.alerts,
    required this.parameterLabel,
  });

  final List<ParameterRangeAlert> alerts;
  final String Function(String parameterType) parameterLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final hasCritical = alerts.any((a) => a.status == ParameterStatus.critical);

    return Card(
      color: hasCritical
          ? cs.errorContainer.withOpacity(0.55)
          : Colors.orange.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasCritical
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: hasCritical ? cs.error : Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.outOfRangeAlertsTitle(alerts.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasCritical ? cs.error : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...alerts.map((alert) {
              final statusLabel = switch (alert.status) {
                ParameterStatus.critical => l10n.parameterStatusCritical,
                ParameterStatus.warning => l10n.warning,
                ParameterStatus.caution => l10n.parameterStatusCaution,
                ParameterStatus.normal => '',
              };
              final dotColor = switch (alert.status) {
                ParameterStatus.critical => Colors.red,
                ParameterStatus.warning => Colors.orange,
                ParameterStatus.caution => Colors.amber.shade700,
                ParameterStatus.normal => Colors.green,
              };
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.outOfRangeAlertRow(
                          parameterLabel(alert.parameterType),
                          alert.value.toStringAsFixed(2),
                          alert.unit ?? '',
                          statusLabel,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
