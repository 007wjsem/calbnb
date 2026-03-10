import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../data/company_repository.dart';
import '../../../core/theme/app_colors.dart';

class CompanySwitcher extends ConsumerWidget {
  const CompanySwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null || user.companyIds.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sidebarMuted.withOpacity(0.3)),
      ),
      child: PopupMenuButton<String>(
        initialValue: user.activeCompanyId,
        offset: const Offset(0, 50),
        onSelected: (companyId) async {
          try {
            await ref.read(authControllerProvider.notifier).switchCompany(companyId);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error switching company: $e')),
              );
            }
          }
        },
        itemBuilder: (context) {
          return user.companyIds.map((id) {
            return PopupMenuItem<String>(
              value: id,
              child: Consumer(
                builder: (context, ref, _) {
                  final companyAsync = ref.watch(companyProvider(id));
                  return companyAsync.when(
                    data: (company) => Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 18,
                          color: id == user.activeCompanyId ? AppColors.amber : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            company?.name ?? 'Unknown Company',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: id == user.activeCompanyId ? FontWeight.bold : FontWeight.normal,
                              color: id == user.activeCompanyId ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (id == user.activeCompanyId)
                          const Icon(Icons.check_circle, size: 16, color: AppColors.green),
                      ],
                    ),
                    loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => Text('Error loading $id'),
                  );
                },
              ),
            );
          }).toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.amber, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final activeId = user.activeCompanyId;
                    if (activeId == null) return const Text('Select Company', style: TextStyle(color: Colors.white));
                    
                    final companyAsync = ref.watch(companyProvider(activeId));
                    return companyAsync.when(
                      data: (company) => Text(
                        company?.name ?? 'Loading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    );
                  },
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.sidebarMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
