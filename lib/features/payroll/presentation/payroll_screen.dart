import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../company/presentation/subscription_guard.dart';
import '../../company/domain/subscription.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../company/presentation/currency_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/data/user_repository.dart';
import '../../company/data/company_repository.dart';
import '../domain/payment_settings.dart';
import '../domain/payroll_payment.dart';
import '../data/payroll_repository.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/server_time_provider.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Use server time for initial selection if available, otherwise fallback to local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverTime = ref.read(currentServerTimeProvider);
      setState(() {
        _selectedDate = serverTime;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDate == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final nowAtMidnight = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    int diffToMonday = nowAtMidnight.weekday - DateTime.monday;
    final startOfWeek = nowAtMidnight.subtract(Duration(days: diffToMonday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    final startStr = DateFormat('MMM d').format(startOfWeek);
    final endStr = DateFormat('MMM d, yyyy').format(endOfWeek);

    final authUser = ref.watch(authControllerProvider);
    final companyId = authUser?.activeCompanyId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.payrollDashboardTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SubscriptionGuard(
        requiredTier: SubscriptionTier.gold,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context)!.weeklyEarningsTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate!.subtract(const Duration(days: 7));
                          });
                        },
                      ),
                      Text(
                        '$startStr - $endStr',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate!.add(const Duration(days: 7));
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ref.watch(allCleaningAssignmentsProvider).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (allAssignments) {
                    final currencySymbol = ref.watch(currencySymbolProvider);
                    final cleanersAsync = ref.watch(companyCleanersProvider(companyId));

                    return cleanersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (allCompanyCleaners) {
                        // Filter to current week (Normalized to capture entire days)
                        final weekAssignments = allAssignments.where((a) {
                          final date = DateTime.tryParse(a.date);
                          if (date == null) return false;
                          // Use the normalized start/end boundaries from the parent scope
                          return !date.isBefore(startOfWeek) && !date.isAfter(endOfWeek);
                        }).toList();

                        // Grouping and sums
                        Map<String, double> payableEarnings = {};
                        Map<String, List<CleaningAssignment>> jobsGroupedByCleaner = {};
                        
                        for (final assign in weekAssignments) {
                          for (final cleaner in assign.cleaners) {
                            final fee = cleaner.fee;
                            final cId = cleaner.id;

                            if (assign.status == CleaningStatus.approved || assign.status == CleaningStatus.pendingInspection) {
                               payableEarnings[cId] = (payableEarnings[cId] ?? 0) + fee;
                            }
                            
                            if (jobsGroupedByCleaner[cId] == null) jobsGroupedByCleaner[cId] = [];
                            jobsGroupedByCleaner[cId]!.add(assign);
                          }
                        }

                        // Ensure ALL registered cleaners are in the list, even with 0 jobs
                        final Set<String> cleanerIds = allCompanyCleaners.map((u) => u.id).toSet();
                        // Add any cleaner who worked but might not be in the company cleaners list (safety/legacy)
                        for (var cId in jobsGroupedByCleaner.keys) {
                          cleanerIds.add(cId);
                        }

                        final sortedCleanerIds = cleanerIds.toList()..sort((a, b) {
                          final nameA = allCompanyCleaners.where((u) => u.id == a).firstOrNull?.username ?? 
                                        jobsGroupedByCleaner[a]?.first.cleaners.where((c) => c.id == a).firstOrNull?.name ?? 'Unknown';
                          final nameB = allCompanyCleaners.where((u) => u.id == b).firstOrNull?.username ?? 
                                        jobsGroupedByCleaner[b]?.first.cleaners.where((c) => c.id == b).firstOrNull?.name ?? 'Unknown';
                          return nameA.compareTo(nameB);
                        });
                        
                        final totalWeekly = payableEarnings.values.fold(0.0, (acc, val) => acc + val);

                        return Column(
                          children: [
                            // TOTAL WEEKLY PAYROLL CARD
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL WEEKLY PAYROLL (Payable)', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                  const SizedBox(height: 8),
                                  Text('$currencySymbol${totalWeekly.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                                  const SizedBox(height: 12),
                                  
                                  // DIAMOND TIER: PAY OPTION
                                  Consumer(builder: (context, ref, _) {
                                    final companyAsync = ref.watch(companyProvider(companyId));
                                    final company = companyAsync.valueOrNull;
                                    if (company?.tier != SubscriptionTier.diamond) return const SizedBox.shrink();
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.diamond_outlined, color: Colors.amber, size: 20),
                                          const SizedBox(width: 8),
                                          const Expanded(child: Text('Diamond Tier: Pay your cleaners below and upload proofs.', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                          const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            
                            Expanded(
                              child: ListView.builder(
                                itemCount: sortedCleanerIds.length,
                                itemBuilder: (context, index) {
                                  final cId = sortedCleanerIds[index];
                                  final cJobs = jobsGroupedByCleaner[cId] ?? [];
                                  final cName = allCompanyCleaners.where((u) => u.id == cId).firstOrNull?.username ?? 
                                                (cJobs.isNotEmpty ? cJobs.first.cleaners.where((cl) => cl.id == cId).firstOrNull?.name ?? 'Unknown' : 'Unknown Cleaner');
                                  final totalP = payableEarnings[cId] ?? 0.0;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.green.withValues(alpha: 0.1),
                                        child: const Icon(Icons.person, color: AppColors.green),
                                      ),
                                      title: Text(cName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      trailing: Text('$currencySymbol${totalP.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.green)),
                                      subtitle: Text('${cJobs.length} cleanings'),
                                      childrenPadding: const EdgeInsets.all(16),
                                      children: [
                                        _AdminPaymentControl(
                                          cleanerId: cId,
                                          companyId: companyId,
                                          amount: totalP,
                                          payPeriod: '$startStr - $endStr',
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const Align(alignment: Alignment.centerLeft, child: Text('JOB BREAKDOWN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                        ...cJobs.map((job) {
                                          final fee = job.cleaners.where((cl) => cl.id == cId).firstOrNull?.fee ?? 0.0;
                                          final isReady = job.status == CleaningStatus.approved || job.status == CleaningStatus.pendingInspection;
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Row(
                                              children: [
                                                Expanded(child: Text(job.propertyId, style: const TextStyle(fontWeight: FontWeight.w600))),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isReady ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    job.status.name.toUpperCase(),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isReady ? Colors.green : Colors.orange),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Text(job.date),
                                            trailing: Text('$currencySymbol${fee.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: isReady ? Colors.black : Colors.grey)),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _AdminPaymentControl extends ConsumerStatefulWidget {
  final String cleanerId;
  final String companyId;
  final double amount;
  final String payPeriod;

  const _AdminPaymentControl({
    required this.cleanerId,
    required this.companyId,
    required this.amount,
    required this.payPeriod,
  });

  @override
  ConsumerState<_AdminPaymentControl> createState() => _AdminPaymentControlState();
}

class _AdminPaymentControlState extends ConsumerState<_AdminPaymentControl> {
  bool _isUploading = false;
  
  Future<void> _uploadProof() async {
     final picker = ImagePicker();
     final file = await picker.pickImage(source: ImageSource.gallery);
     if (file == null) return;
     
     setState(() => _isUploading = true);
     try {
        final bytes = await file.readAsBytes();
        final serverTime = ref.read(currentServerTimeProvider);
        final filename = '${serverTime.millisecondsSinceEpoch}_${file.name}';
        final repo = ref.read(payrollRepositoryProvider);
        final url = await repo.uploadProofOfPayment(widget.companyId, widget.cleanerId, filename, bytes, file.mimeType ?? 'image/jpeg');
        
        final payment = PayrollPayment(
           id: serverTime.millisecondsSinceEpoch.toString(),
           companyId: widget.companyId,
           cleanerId: widget.cleanerId,
           amount: widget.amount,
           proofPhotoUrl: url,
           payPeriodTitle: widget.payPeriod,
           timestamp: serverTime.toIso8601String(),
        );
        
        await repo.savePayrollPayment(payment);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment proof uploaded successfully.')));
     } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
     } finally {
        if (mounted) setState(() => _isUploading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
      final settingsAsync = ref.read(payrollRepositoryProvider).getPaymentSettings(widget.cleanerId);
      
      return FutureBuilder<PaymentSettings?>(
         future: settingsAsync,
         builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final set = snap.data;
            return Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PAYMENT DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.1, color: AppColors.textSecondary)),
                        if (set == null) const Text('No Details Set', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (set != null) ...[
                       Text(set.method == PaymentMethod.transfer ? 'Bank: ${set.bankName}' : (set.method == PaymentMethod.yape ? 'Yape' : 'Plin'), style: const TextStyle(fontWeight: FontWeight.bold)),
                       Text(set.method == PaymentMethod.transfer ? 'Acc: ${set.savingsNumber}\nCCI: ${set.cci}' : 'Phone: ${set.savingsNumber}', style: const TextStyle(fontSize: 13, height: 1.4)),
                    ] else
                       const Text('Ask cleaner to set up payment details in their profile.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: (_isUploading || widget.amount == 0) ? null : _uploadProof,
                      icon: _isUploading ? const SizedBox(width:12, height:12, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.receipt_long_rounded),
                      label: Text(widget.amount == 0 ? 'No Earnings to Pay' : 'UPLOAD PROOF & SEND'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                 ],
               ),
            );
         }
      );
  }
}
