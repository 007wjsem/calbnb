import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay/pay.dart';
import 'package:uuid/uuid.dart';
import '../data/company_repository.dart';
import '../domain/company.dart';
import '../domain/subscription.dart';
import '../domain/transaction_record.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';

class PlanCarouselScreen extends ConsumerStatefulWidget {
  final Company company;
  const PlanCarouselScreen({super.key, required this.company});

  @override
  ConsumerState<PlanCarouselScreen> createState() => _PlanCarouselScreenState();
}

class _PlanCarouselScreenState extends ConsumerState<PlanCarouselScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Start at current tier index
    _pageController = PageController(viewportFraction: 0.85, initialPage: widget.company.tier.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPaymentResult(Map<String, dynamic> result, SubscriptionTier tier) async {
    try {
      final now = DateTime.now();
      final transaction = TransactionRecord(
        id: const Uuid().v4(),
        companyId: widget.company.id,
        tierName: tier.displayName,
        amount: tier.basePrice,
        currency: 'USD',
        paymentMethod: result.containsKey('apple_pay') ? 'Apple Pay' : (result.containsKey('google_pay') ? 'Google Pay' : 'Other'),
        timestamp: now,
        status: 'completed',
        rawPayload: result,
      );

      final repo = ref.read(companyRepositoryProvider);
      
      // Save the raw monetary transaction log
      await repo.saveTransaction(transaction);

      // In a real app we'd send the token to our backend (Stripe) here.
      // For demo execution we simulate success and update the firestore database directly.
      await repo.renewSubscription(
        companyId: widget.company.id,
        tier: tier,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.successfullyUpdatedPlan(tier.displayName))),
        );
        Navigator.pop(context);
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingPlan(e.toString()))),
        );
      }
    }
  }

  List<String> _getTierFeatures(SubscriptionTier tier) {
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

  @override
  Widget build(BuildContext context) {
    final tiers = SubscriptionTier.values;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.availablePlansTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.availablePlansDesc, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 30),
          Expanded(
            child: Stack(
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: tiers.length,
                    itemBuilder: (context, index) {
                      final tier = tiers[index];
                      return _buildCarouselCard(tier);
                    },
                  ),
                ),
                
                // Left Arrow Indicator
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) {
                        final bool canGoLeft = _pageController.hasClients && (_pageController.page ?? _pageController.initialPage) > 0.1;
                        return MouseRegion(
                          cursor: canGoLeft ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: canGoLeft ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                            child: AnimatedOpacity(
                              opacity: canGoLeft ? 0.7 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                                ),
                                child: const Icon(Icons.chevron_left, size: 32, color: AppColors.primary),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Right Arrow Indicator
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) {
                        final bool canGoRight = _pageController.hasClients && (_pageController.page ?? _pageController.initialPage) < tiers.length - 1.1;
                        return MouseRegion(
                          cursor: canGoRight ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: canGoRight ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                            child: AnimatedOpacity(
                              opacity: canGoRight ? 0.7 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                                ),
                                child: const Icon(Icons.chevron_right, size: 32, color: AppColors.primary),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Dot Indicators
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              final double page = _pageController.hasClients ? (_pageController.page ?? _pageController.initialPage.toDouble()) : _pageController.initialPage.toDouble();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(tiers.length, (index) {
                  final bool isActive = (page.round() == index);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            },
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(SubscriptionTier tier) {
    final bool isCurrent = widget.company.tier == tier;
    final features = _getTierFeatures(tier);
    final isRecommended = tier == SubscriptionTier.gold;

    final payItems = [
      PaymentItem(
        label: '${tier.displayName} Subscription',
        amount: tier.basePrice.toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      )
    ];

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - tier.index;
          value = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * 600,
            width: Curves.easeOut.transform(value) * 400,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary.withValues(alpha: 0.03) : Colors.white,
          border: Border.all(color: isCurrent ? AppColors.primary : Colors.grey.shade200, width: isCurrent ? 2 : 1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tier.displayName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${tier.basePrice.toStringAsFixed(tier.basePrice == 0 ? 0 : 2)}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    AppLocalizations.of(context)!.perMonthLabel,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: features.map((f) => Padding(
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
                            Expanded(child: Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.3))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!.currentPlanButton,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    )
                  else if (tier.basePrice == 0)
                     ElevatedButton(
                        onPressed: () => _onPaymentResult({}, tier),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context)!.downgradeAction),
                      )
                  else 
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showConfirmationDialog(context, tier, payItems),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Select Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            if (isRecommended)
              Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.mostPopularBadge, 
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, SubscriptionTier tier, List<PaymentItem> payItems) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const Text(
                'Confirm Subscription',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'You are about to subscribe to the ${tier.displayName} plan for \$${tier.basePrice.toStringAsFixed(2)} per month.',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Apple Pay Button
              ApplePayButton(
                paymentConfiguration: PaymentConfiguration.fromJsonString('''
{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.yourcompany.calbnb",
    "displayName": "Calbnb ${tier.displayName} Subscription",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
    "countryCode": "US",
    "currencyCode": "USD"
  }
}
'''),
                paymentItems: payItems,
                type: ApplePayButtonType.subscribe,
                margin: const EdgeInsets.only(top: 8.0),
                onPaymentResult: (res) {
                  Navigator.pop(context);
                  _onPaymentResult(res, tier);
                },
                loadingIndicator: const Center(child: CircularProgressIndicator()),
                childOnError: const SizedBox.shrink(),
                onError: (error) {
                  debugPrint("Apple Pay error: \$error");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("There was an issue with the payment method."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              
              // Google Pay Button
              SizedBox(
                width: 250,
                height: 50,
                child: GooglePayButton(
                  paymentConfiguration: PaymentConfiguration.fromJsonString('''
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "exampleGatewayMerchantId"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": true
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "01234567890123456789",
      "merchantName": "Calbnb"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}
'''),
                paymentItems: payItems,
                type: GooglePayButtonType.subscribe,
                theme: GooglePayButtonTheme.dark,
                margin: const EdgeInsets.only(top: 8.0),
                  onPaymentResult: (res) {
                    Navigator.pop(context);
                    _onPaymentResult(res, tier);
                  },
                  loadingIndicator: const Center(child: CircularProgressIndicator()),
                  childOnError: const SizedBox.shrink(),
                  onError: (error) {
                    debugPrint("Google Pay error: \$error");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("There was an issue with the payment method."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
