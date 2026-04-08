import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:uuid/uuid.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/subscription.dart';
import '../../company/domain/transaction_record.dart';
import '../../../core/data/server_time_provider.dart';

final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class IAPService {
  final Ref _ref;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();

  IAPService(this._ref) {
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );
  }

  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Handle pending state
        _purchaseController.add(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        // Handle error state
        _purchaseController.add(purchase);
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        // Handle successful purchase or restore
        await _handleSuccessfulPurchase(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      final now = _ref.read(currentServerTimeProvider);
      
      // Map Product ID back to SubscriptionTier
      final tier = SubscriptionTier.values.firstWhere(
        (t) => t.productId == purchase.productID,
        orElse: () => SubscriptionTier.free,
      );

      if (tier == SubscriptionTier.free) return;

      // Extract details from purchase
      final String companyId = _ref.read(authControllerProvider)?.activeCompanyId ?? '';
      if (companyId.isEmpty) return;

      final transaction = TransactionRecord(
        id: const Uuid().v4(),
        companyId: companyId,
        tierName: tier.displayName,
        amount: tier.basePrice,
        currency: 'USD',
        paymentMethod: purchase.verificationData.localVerificationData.contains('apple') ? 'Apple App Store' : 'Google Play',
        timestamp: now,
        status: 'completed',
        rawPayload: {
          'productID': purchase.productID,
          'purchaseID': purchase.purchaseID,
          'transactionDate': purchase.transactionDate,
          'status': purchase.status.toString(),
          'serverVerificationData': purchase.verificationData.serverVerificationData,
        },
      );

      final repo = _ref.read(companyRepositoryProvider);
      
      // Save transaction log
      await repo.saveTransaction(transaction);

      // In a real app we'd verify the receipt on a backend here.
      // For this implementation, we update the database directly upon store success.
      await repo.renewSubscription(
        companyId: companyId,
        tier: tier,
        now: now,
      );

      _purchaseController.add(purchase);
    } catch (e) {
      debugPrint('Error handling success purchase: $e');
    }
  }

  Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) return [];

    final Set<String> ids = SubscriptionTier.values
        .map((t) => t.productId)
        .whereType<String>()
        .toSet();

    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(ids);
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    return response.productDetails;
  }

  Future<void> buySubscription(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // We use subscriptions, so we call buyNonConsumable or buyConsumable depending on platform, 
    // but inAppPurchase handles it via buyNonConsumable for subscriptions usually.
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }
}
