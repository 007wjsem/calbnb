import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../data/company_repository.dart';
import '../domain/subscription.dart';
import '../../../core/theme/app_colors.dart';

class CompanySubscriptionScreen extends ConsumerStatefulWidget {
  const CompanySubscriptionScreen({super.key});

  @override
  ConsumerState<CompanySubscriptionScreen> createState() => _CompanySubscriptionScreenState();
}

class _CompanySubscriptionScreenState extends ConsumerState<CompanySubscriptionScreen> {
  bool _isUpdating = false;

  Future<void> _changePlan(String companyId, SubscriptionTier newTier) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Plan Change'),
        content: Text('Are you sure you want to change your subscription to the ${newTier.displayName} plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    ) ?? false;

    if (!confirm || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(companyRepositoryProvider).updateSubscription(
        companyId: companyId,
        tier: newTier,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully updated plan to ${newTier.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final activeCompanyId = user?.activeCompanyId;
    final isSuperAdmin = user?.role.displayName == 'Super Admin';

    if (activeCompanyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing & Plan')),
        body: const Center(child: Text('No active company selected.')),
      );
    }

    final companyAsync = ref.watch(companyProvider(activeCompanyId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Billing & Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: companyAsync.when(
        data: (company) {
          if (company == null) return const Center(child: Text('Company data not found.'));
          final tier = company.tier;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 40),
                children: [
                  // Premium Hero Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT PLAN',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${tier.displayName} Plan',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                company.status.displayName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: _buildHeroUsageMetric(
                                label: 'Properties',
                                used: company.propertyCount,
                                max: tier.includedProperties,
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildHeroUsageMetric(
                                label: 'Active Users',
                                used: 1, // Placeholder
                                max: tier.maxUsers,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  const Text('Available Plans', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Choose the perfect plan for your business needs. Upgrade or downgrade at any time.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),

                  // Plans List
                  _buildPlanOption(
                    companyId: company.id,
                    currentTier: tier,
                    planTier: SubscriptionTier.free,
                    features: ['Up to 2 Properties', '1 User Only (Admin)', 'Basic Calendar View', 'Standard Checklists', 'Manual Status Updates'],
                  ),
                  const SizedBox(height: 16),
                  _buildPlanOption(
                    companyId: company.id,
                    currentTier: tier,
                    planTier: SubscriptionTier.bronze,
                    features: ['Up to 5 Properties', 'Up to 4 Users (1 Admin, 3 Cleaners)', 'Mobile App Access', 'Photo Evidence (3/clean)', 'Basic Property Data'],
                  ),
                  const SizedBox(height: 16),
                  _buildPlanOption(
                    companyId: company.id,
                    currentTier: tier,
                    planTier: SubscriptionTier.silver,
                    features: ['Up to 15 Properties', 'Up to 10 Users', 'Team Roles (Cleaner vs Manager)'],
                  ),
                  const SizedBox(height: 16),
                  _buildPlanOption(
                    companyId: company.id,
                    currentTier: tier,
                    planTier: SubscriptionTier.gold,
                    features: ['Up to 30 Properties', 'Up to 18 Users', 'Payroll Module & Reports', 'Owner Portal', 'Inspector Role'],
                    isRecommended: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanOption(
                    companyId: company.id,
                    currentTier: tier,
                    planTier: SubscriptionTier.platinum,
                    features: ['Up to 60 Properties', 'Up to 39 Users', 'Multi-Currency Billing'],
                  ),
                  const SizedBox(height: 16),
                  _buildPlanOption(
                    companyId: company.id,
                    currentTier: tier,
                    planTier: SubscriptionTier.diamond,
                    features: ['Up to 100 Properties', 'Up to 106 Users', 'White Labeling', 'Advanced Analytics', 'Priority WhatsApp Support'],
                  ),
                ],
              ),
              if (_isUpdating)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading subscription data: $e')),
      ),
    );
  }

  Widget _buildHeroUsageMetric({required String label, required int used, required int? max}) {
    final double percent = (max != null && max > 0) ? (used / max).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(used.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(max == null ? '/ Unlimited' : '/ $max', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required String companyId,
    required SubscriptionTier currentTier,
    required SubscriptionTier planTier,
    required List<String> features,
    bool isRecommended = false,
  }) {
    final bool isCurrent = currentTier == planTier;
    final bool isUpgrade = planTier.index > currentTier.index;

    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primary.withValues(alpha: 0.03) : Colors.white,
        border: Border.all(color: isCurrent ? AppColors.primary : Colors.grey.shade200, width: isCurrent ? 2 : 1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isCurrent ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(planTier.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${planTier.basePrice.toStringAsFixed(planTier.basePrice == 0 ? 0 : 2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                        const Text('/ month', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 14, color: AppColors.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.3))),
                    ],
                  ),
                )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () => _changePlan(companyId, planTier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey.shade200 : (isUpgrade ? AppColors.primary : Colors.white),
                      foregroundColor: isCurrent ? Colors.grey.shade500 : (isUpgrade ? Colors.white : AppColors.primary),
                      side: BorderSide(color: isCurrent ? Colors.transparent : (isUpgrade ? Colors.transparent : AppColors.primary)),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isCurrent ? 'Current Plan' : (isUpgrade ? 'Upgrade' : 'Downgrade'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: -12,
              left: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Text('MOST POPULAR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
        ],
      ),
    );
  }
}

