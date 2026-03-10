import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/subscription.dart';
import '../data/company_repository.dart';

class SubscriptionGuard extends ConsumerWidget {
  final Widget child;
  final SubscriptionTier requiredTier;
  final Widget? fallback;

  const SubscriptionGuard({
    super.key,
    required this.child,
    required this.requiredTier,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    
    // Super admins bypass subscription checks
    if (user?.role.displayName == 'Super Admin') {
      return child;
    }

    final activeCompanyId = user?.activeCompanyId;

    if (activeCompanyId == null) {
      return _DefaultFallback(requiredTier: requiredTier);
    }

    final companyAsync = ref.watch(companyProvider(activeCompanyId));

    return companyAsync.when(
      data: (company) {
        if (company == null) return _DefaultFallback(requiredTier: requiredTier);

        // Check if company's tier is high enough
        if (company.tier.index >= requiredTier.index && 
            company.status == SubscriptionStatus.active) {
          return child;
        }

        return fallback ?? _DefaultFallback(requiredTier: requiredTier);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => fallback ?? _DefaultFallback(requiredTier: requiredTier),
    );
  }
}

class _DefaultFallback extends StatelessWidget {
  final SubscriptionTier requiredTier;

  const _DefaultFallback({required this.requiredTier});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              onPressed: () => context.go('/admin/subscription'),
              child: const Text('Upgrade Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
