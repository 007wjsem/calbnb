import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../data/company_repository.dart';
import '../domain/subscription.dart';
import '../../../core/theme/app_colors.dart';

class CompanySubscriptionScreen extends ConsumerWidget {
  const CompanySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final activeCompanyId = user?.activeCompanyId;

    if (activeCompanyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing & Plan')),
        body: const Center(child: Text('No active company selected.')),
      );
    }

    final companyAsync = ref.watch(companyProvider(activeCompanyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: companyAsync.when(
        data: (company) {
          if (company == null) return const Center(child: Text('Company data not found.'));
          final tier = company.tier;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CURRENT PLAN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              const SizedBox(height: 8),
                              Text(
                                '${tier.displayName} Plan',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: company.status == SubscriptionStatus.active ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              company.status.displayName,
                              style: TextStyle(
                                color: company.status == SubscriptionStatus.active ? Colors.green.shade700 : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('Limits & Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildUsageBar(
                        label: 'Properties',
                        used: company.propertyCount,
                        max: tier.includedProperties,
                      ),
                      const SizedBox(height: 12),
                      _buildUsageBar(
                        label: 'Major App Updates',
                        used: company.majorReleasesUsed,
                        max: tier == SubscriptionTier.starter ? 0 : null,
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'To upgrade your plan, manage payment methods, or review past invoices, please contact our support team or use the forthcoming self-service portal.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Available Plans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPlanOption(
                title: 'Starter',
                price: '\$49/mo',
                features: ['Up to 3 Properties', 'Basic Calendar Dashboard', 'Email Support'],
                isCurrent: tier == SubscriptionTier.starter,
              ),
              const SizedBox(height: 12),
              _buildPlanOption(
                title: 'Pro',
                price: '\$149/mo',
                features: ['Up to 20 Properties', 'Inspector App Access', 'Cleaner App \u0026 Payroll Calculation', 'Priority Support'],
                isCurrent: tier == SubscriptionTier.growth,
                isRecommended: true,
              ),
              const SizedBox(height: 12),
              _buildPlanOption(
                title: 'Agency',
                price: '\$399/mo',
                features: ['Up to 100 Properties', 'Dedicated Account Manager', 'Custom API Integrations', 'White-labeling Options'],
                isCurrent: tier == SubscriptionTier.agency,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading subscription data: $e')),
      ),
    );
  }

  Widget _buildUsageBar({required String label, required int used, required int? max}) {
    final double percent = (max != null && max > 0) ? (used / max).clamp(0.0, 1.0) : 0.0;
    final bool isNearLimit = max != null && percent > 0.8;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              max == null ? '$used / Unlimited' : '$used / $max',
              style: TextStyle(fontWeight: FontWeight.bold, color: isNearLimit ? Colors.orange.shade800 : Colors.grey.shade700),
            )
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          minHeight: 8,
          backgroundColor: Colors.grey.shade200,
          color: isNearLimit ? Colors.orange : AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPlanOption({required String title, required String price, required List<String> features, bool isCurrent = false, bool isRecommended = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isCurrent ? AppColors.primary : Colors.grey.shade300, width: isCurrent ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
        color: isCurrent ? AppColors.primary.withOpacity(0.05) : Colors.white,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (isRecommended) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text('RECOMMENDED', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
              Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(f),
              ],
            ),
          )),
          if (isCurrent) ...[
            const SizedBox(height: 16),
            const Center(child: Text('Current Plan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
          ]
        ],
      ),
    );
  }
}
