import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../company/domain/company.dart';
import '../../company/domain/subscription.dart';
import '../../company/data/company_repository.dart';

class SuperAdminCompanyListScreen extends ConsumerStatefulWidget {
  const SuperAdminCompanyListScreen({super.key});

  @override
  ConsumerState<SuperAdminCompanyListScreen> createState() => _SuperAdminCompanyListScreenState();
}

class _SuperAdminCompanyListScreenState extends ConsumerState<SuperAdminCompanyListScreen> {
  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(globalCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Companies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/companies/new'),
            tooltip: 'Create New Company',
          ),
        ],
      ),
      body: companiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (companies) {
          if (companies.isEmpty) {
            return const Center(child: Text('No companies found. Create one to get started.'));
          }
          
          return ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final isActive = company.isActive;
              
              return ListTile(
                title: Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${company.tier.displayName} Tier • ${company.propertyCount} properties'),
                trailing: Chip(
                  label: Text(company.status.displayName),
                  backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
                  labelStyle: TextStyle(color: isActive ? Colors.green.shade800 : Colors.red.shade800),
                ),
                onTap: () => context.push('/admin/companies/${company.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
