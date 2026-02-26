import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../services/remote_config_service.dart';

/// Shows the Remove Ads purchase dialog and, after it closes, the
/// restore-outcome dialog when applicable.
Future<void> showRemoveAdsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const RemoveAdsDialog(),
  );
  if (!context.mounted) return;
  final container = ProviderScope.containerOf(context, listen: false);
  final outcome = container.read(purchaseProvider).restoreOutcome;
  container.read(purchaseProvider.notifier).clearRestoreOutcome();
  _showRestoreOutcomeDialog(context, outcome);
}

void _showRestoreOutcomeDialog(BuildContext context, RestoreOutcome outcome) {
  if (outcome == RestoreOutcome.none) return;
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      if (outcome == RestoreOutcome.success) {
        return AlertDialog(
          icon: const Icon(Icons.favorite, color: Colors.green, size: 36),
          title: Text(l10n.removeAdsThankyouTitle),
          content: Text(l10n.removeAdsThankyouBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      }
      // RestoreOutcome.notFound
      return AlertDialog(
        icon: const Icon(Icons.search_off, size: 36),
        title: Text(l10n.removeAdsNoPurchaseTitle),
        content: Text(l10n.removeAdsNoPurchaseBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// A clean dialog for the "Remove Ads" one-time purchase.
class RemoveAdsDialog extends ConsumerWidget {
  const RemoveAdsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final purchaseState = ref.watch(purchaseProvider);
    final busy = purchaseState.isPurchasing;

    // Auto-close when the purchase completes successfully.
    if (purchaseState.adsRemoved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
    }

    // Auto-close when restore determines there is no previous purchase,
    // so the outcome dialog can be shown by the parent.
    ref.listen<PurchaseState>(purchaseProvider, (prev, next) {
      if (next.restoreOutcome != RestoreOutcome.notFound) return;
      if (prev?.restoreOutcome == RestoreOutcome.notFound) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
    });

    return AlertDialog(
      icon: const Icon(Icons.block, size: 36),
      title: Text(l10n.removeAds),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.earlySupporterPerkTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.earlySupporterPerkBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.removeAdsContentDesc),
          const SizedBox(height: 12),
          Text(
            l10n.removeAdsPurchaseTiedToAccount,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (purchaseState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              purchaseState.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => ref.read(purchaseProvider.notifier).restorePurchases(),
          child: Text(l10n.restore),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        Builder(builder: (context) {
          final price = RemoteConfigService.getEarlySupporterPrice(
                    locale: Localizations.localeOf(context).toString(),
                  );
          if (price.isEmpty) {
            return ElevatedButton(
              onPressed: busy ? null : () => ref.read(purchaseProvider.notifier).buyRemoveAds(),
              child: Text(l10n.removeAds),
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: busy ? null : () => ref.read(purchaseProvider.notifier).buyRemoveAds(),
                child: Text(l10n.removeAds),
              ),
            ],
          );
        }),
      ],
    );
  }
}
