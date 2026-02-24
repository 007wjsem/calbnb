import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/company_providers.dart';
import '../data/company_repository.dart';
import '../domain/subscription.dart';

/// Wraps a child widget and only displays it if the company's subscription
/// tier meets or exceeds [requiredTier]. Otherwise shows [fallback] or a
/// generic "upgrade required" card.
class SubscriptionGuard extends ConsumerWidget {
  final SubscriptionTier requiredTier;
  final Widget child;
  final Widget? fallback;

  const SubscriptionGuard({
    super.key,
    required this.requiredTier,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = ref.watch(companyIdProvider);

    if (companyId == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final companyAsync = ref.watch(companyProvider(companyId));

    return companyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
      data: (company) {
        if (company == null || !company.isActive) {
          return _UpgradeCard(requiredTier: requiredTier);
        }

        final tierIndex = SubscriptionTier.values.indexOf(company.tier);
        final requiredIndex = SubscriptionTier.values.indexOf(requiredTier);

        if (tierIndex >= requiredIndex) {
          return child;
        }

        return fallback ?? _UpgradeCard(requiredTier: requiredTier);
      },
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final SubscriptionTier requiredTier;
  const _UpgradeCard({required this.requiredTier});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              '${requiredTier.displayName} Plan Required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to the ${requiredTier.displayName} plan to unlock this feature.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/subscribe'),
              child: const Text('Upgrade Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
