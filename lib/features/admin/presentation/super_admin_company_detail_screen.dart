import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../company/domain/company.dart';
import '../../company/domain/subscription.dart';
import '../../company/data/company_repository.dart';

class SuperAdminCompanyDetailScreen extends ConsumerStatefulWidget {
  final String companyId;
  const SuperAdminCompanyDetailScreen({super.key, required this.companyId});

  @override
  ConsumerState<SuperAdminCompanyDetailScreen> createState() => _SuperAdminCompanyDetailScreenState();
}

class _SuperAdminCompanyDetailScreenState extends ConsumerState<SuperAdminCompanyDetailScreen> {
  Future<void> _updateStatus(Company company, SubscriptionStatus newStatus) async {
    try {
      await ref.read(companyRepositoryProvider).updateSubscription(
        companyId: company.id,
        status: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Company marked as ${newStatus.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider(widget.companyId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading company: $err')),
        data: (company) {
          if (company == null) return const Center(child: Text('Company not found'));
          
          final isActive = company.isActive;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            company.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(company.status.displayName),
                            backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
                            labelStyle: TextStyle(color: isActive ? Colors.green.shade800 : Colors.red.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Created: ${company.createdAt.toLocal().toString().split(' ')[0]}'),
                      const Divider(height: 32),
                      _buildInfoRow('Tier', company.tier.displayName),
                      _buildInfoRow('Properties', company.propertyCount.toString()),
                      if (company.tier == SubscriptionTier.enterprise && company.supportExpiresAt != null)
                        _buildInfoRow('Support Expires', company.supportExpiresAt!.toLocal().toString().split(' ')[0]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (isActive)
                FilledButton.icon(
                  onPressed: () => _updateStatus(company, SubscriptionStatus.canceled),
                  icon: const Icon(Icons.block),
                  label: const Text('Suspend Company'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                )
              else
                FilledButton.icon(
                  onPressed: () => _updateStatus(company, SubscriptionStatus.active),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Re-activate Company'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
