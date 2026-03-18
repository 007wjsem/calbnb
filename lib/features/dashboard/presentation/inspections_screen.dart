import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'inspector_dashboard.dart';
import '../../company/presentation/subscription_guard.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import '../../company/domain/subscription.dart';

class InspectionsScreen extends StatelessWidget {
  const InspectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.todaysInspectionsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const SubscriptionGuard(
        requiredTier: SubscriptionTier.gold,
        child: InspectorDashboard(),
      ),
    );
  }
}
