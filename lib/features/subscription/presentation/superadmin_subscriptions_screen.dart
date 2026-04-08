import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/company.dart';
import '../../company/domain/subscription.dart';
import '../../../core/theme/app_colors.dart';

class SuperAdminSubscriptionsScreen extends ConsumerWidget {
  const SuperAdminSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(globalCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Subscriptions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (companies) {
          // Calculate stats
          Map<SubscriptionTier, int> tierCounts = {};
          Map<SubscriptionTier, double> tierRevenue = {};
          double totalMrr = 0.0;
          
          for (final c in companies) {
            // Only count active or trialing
            if (c.isActive) {
               tierCounts[c.tier] = (tierCounts[c.tier] ?? 0) + 1;
               tierRevenue[c.tier] = (tierRevenue[c.tier] ?? 0.0) + c.tier.basePrice;
               totalMrr += c.tier.basePrice;
            }
          }

          // Sort latest subscriptors
          final sortedCompanies = List<Company>.from(companies)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final latestSubs = sortedCompanies.take(10).toList(); // Show top 10 newest

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MRR Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Monthly Recurring Revenue (MRR)', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('\$${totalMrr.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      Text('${companies.where((c) => c.isActive).length} Active Subscriptions', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Tier Breakdown
                const Text('Revenue By Tier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: SubscriptionTier.values.map((tier) {
                    final count = tierCounts[tier] ?? 0;
                    final rev = tierRevenue[tier] ?? 0.0;
                    return Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tier.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Text('$count Active', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('\$${rev.toStringAsFixed(2)} / mo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.green)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),

                // Latest Subscriptors
                const Text('Latest Subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: latestSubs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = latestSubs[index];
                      final dateStr = DateFormat('MMM d, yyyy').format(c.createdAt);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.business_rounded, color: AppColors.primary),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Joined $dateStr'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(c.tier.displayName, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            Text(c.isActive ? 'Active' : 'Inactive', style: TextStyle(color: c.isActive ? AppColors.green : AppColors.error, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
