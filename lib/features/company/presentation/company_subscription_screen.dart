import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../data/company_repository.dart';
import '../domain/subscription.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'plan_carousel_screen.dart';

class CompanySubscriptionScreen extends ConsumerStatefulWidget {
  const CompanySubscriptionScreen({super.key});

  @override
  ConsumerState<CompanySubscriptionScreen> createState() => _CompanySubscriptionScreenState();
}

class _CompanySubscriptionScreenState extends ConsumerState<CompanySubscriptionScreen> {
  bool _isUpdating = false;

  // Action methods handled by the Carousel mostly now


  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final activeCompanyId = user?.activeCompanyId;
    final isSuperAdmin = user?.role.displayName == 'Super Admin';

    if (activeCompanyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.billingAndPlan),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(child: Text(AppLocalizations.of(context)!.noActiveCompanySelected)),
      );
    }

    final companyAsync = ref.watch(companyProvider(activeCompanyId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.billingAndPlan),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: companyAsync.when(
        data: (company) {
          if (company == null) return Center(child: Text(AppLocalizations.of(context)!.companyDataNotFound));
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.currentPlanLabel,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${tier.displayName} ${AppLocalizations.of(context)!.planSuffix}',
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.visible,
                                  ),
                                  if (!isSuperAdmin && company.subscriptionEndDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Valid until: ${DateFormat.yMMMd().format(company.subscriptionEndDate!)}',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                label: AppLocalizations.of(context)!.properties,
                                used: company.propertyCount,
                                max: tier.includedProperties,
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildHeroUsageMetric(
                                label: AppLocalizations.of(context)!.activeUsersLabel,
                                used: 1, // Placeholder
                                max: tier.maxUsers,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  Text(AppLocalizations.of(context)!.currentPlanLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _getCurrentTierFeatures(tier, context).map((f) => Padding(
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
                      )).toList(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlanCarouselScreen(company: company),
                          ),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Change Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
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
              child: Text(max == null ? AppLocalizations.of(context)!.unlimitedCount : '/ $max', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
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

  List<String> _getCurrentTierFeatures(SubscriptionTier tier, BuildContext context) {
    switch (tier) {
      case SubscriptionTier.free:
        return [
          AppLocalizations.of(context)!.planFeatureFree1,
          AppLocalizations.of(context)!.planFeatureFree2,
          AppLocalizations.of(context)!.planFeatureFree3,
          AppLocalizations.of(context)!.planFeatureFree4,
          AppLocalizations.of(context)!.planFeatureFree5,
        ];
      case SubscriptionTier.bronze:
        return [
          AppLocalizations.of(context)!.planFeatureBronze1,
          AppLocalizations.of(context)!.planFeatureBronze2,
          AppLocalizations.of(context)!.planFeatureBronze3,
          AppLocalizations.of(context)!.planFeatureBronze4,
          AppLocalizations.of(context)!.planFeatureBronze5,
        ];
      case SubscriptionTier.silver:
        return [
          AppLocalizations.of(context)!.planFeatureSilver1,
          AppLocalizations.of(context)!.planFeatureSilver2,
          AppLocalizations.of(context)!.planFeatureSilver3,
        ];
      case SubscriptionTier.gold:
        return [
          AppLocalizations.of(context)!.planFeatureGold1,
          AppLocalizations.of(context)!.planFeatureGold2,
          AppLocalizations.of(context)!.planFeatureGold3,
          AppLocalizations.of(context)!.planFeatureGold4,
          AppLocalizations.of(context)!.planFeatureGold5,
        ];
      case SubscriptionTier.platinum:
        return [
          AppLocalizations.of(context)!.planFeaturePlatinum1,
          AppLocalizations.of(context)!.planFeaturePlatinum2,
          AppLocalizations.of(context)!.planFeaturePlatinum3,
        ];
      case SubscriptionTier.diamond:
        return [
          AppLocalizations.of(context)!.planFeatureDiamond1,
          AppLocalizations.of(context)!.planFeatureDiamond2,
          AppLocalizations.of(context)!.planFeatureDiamond3,
          AppLocalizations.of(context)!.planFeatureDiamond4,
          AppLocalizations.of(context)!.planFeatureDiamond5,
        ];
    }
  }
}

