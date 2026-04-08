import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/payment_settings.dart';
import '../domain/payroll_payment.dart';
import '../data/payroll_repository.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';

class CleanerPaymentsScreen extends ConsumerStatefulWidget {
  const CleanerPaymentsScreen({super.key});

  @override
  ConsumerState<CleanerPaymentsScreen> createState() => _CleanerPaymentsScreenState();
}

class _CleanerPaymentsScreenState extends ConsumerState<CleanerPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Settings Form State
  PaymentMethod _selectedMethod = PaymentMethod.transfer;
  final _bankNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _cciCtrl = TextEditingController();
  bool _isLoadingSettings = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(authControllerProvider);
    if (user != null) {
      final settings = await ref.read(payrollRepositoryProvider).getPaymentSettings(user.id);
      if (settings != null && mounted) {
        setState(() {
          _selectedMethod = settings.method;
          _bankNameCtrl.text = settings.bankName ?? '';
          _accountCtrl.text = settings.savingsNumber ?? '';
          _cciCtrl.text = settings.cci ?? '';
        });
      }
    }
    if (mounted) setState(() => _isLoadingSettings = false);
  }

  Future<void> _saveSettings() async {
    final user = ref.read(authControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    if (user == null) return;

    setState(() => _isSaving = true);
    final settings = PaymentSettings(
      userId: user.id,
      method: _selectedMethod,
      bankName: _selectedMethod == PaymentMethod.transfer ? _bankNameCtrl.text.trim() : null,
      savingsNumber: _accountCtrl.text.trim(),
      cci: _selectedMethod == PaymentMethod.transfer ? _cciCtrl.text.trim() : null,
    );

    await ref.read(payrollRepositoryProvider).savePaymentSettings(settings);
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paymentPreferencesSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPaymentsTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: l10n.paymentHistoryTab, icon: const Icon(Icons.history_rounded, size: 20)),
            Tab(text: l10n.payoutSettingsTab, icon: const Icon(Icons.account_balance_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider);
    if (user == null) return Center(child: Text(l10n.noActiveCompanyFound));

    final companyId = user.activeCompanyId ?? (user.companyIds.isNotEmpty ? user.companyIds.first : '');
    final paymentsStream = ref.watch(cleanerPaymentsStreamProvider(companyId, user.id));

    return paymentsStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(l10n.genericError(e.toString()))),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(l10n.noPaymentHistoryDesc, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final dateStr = DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(DateTime.parse(payment.timestamp));
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            payment.payPeriodTitle, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D2E63))
                          ),
                        ),
                        Text(
                          'S/${payment.amount.toStringAsFixed(2)}', 
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 20)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.paidOnLabel(dateStr), 
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.receipt_long_rounded, size: 18),
                          label: Text(l10n.viewProofAction),
                          onPressed: () {
                             showDialog(context: context, builder: (_) => Dialog(
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                               clipBehavior: Clip.antiAlias,
                               child: Stack(
                                 alignment: Alignment.topRight,
                                 children: [
                                   InteractiveViewer(child: Image.network(payment.proofPhotoUrl, fit: BoxFit.contain)),
                                   Padding(
                                     padding: const EdgeInsets.all(8.0),
                                     child: CircleAvatar(
                                       backgroundColor: Colors.black54,
                                       child: IconButton(
                                         icon: const Icon(Icons.close, color: Colors.white), 
                                         onPressed: () => Navigator.pop(context)
                                       ),
                                     ),
                                   )
                                 ]
                               )
                             ));
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingSettings) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.payoutQuestion, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D2E63))
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SegmentedButton<PaymentMethod>(
                    showSelectedIcon: true,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary.withOpacity(0.08),
                      selectedForegroundColor: AppColors.primary,
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    segments: [
                      ButtonSegment(
                        value: PaymentMethod.transfer, 
                        label: Center(child: Text(l10n.bankTransferOption, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))
                      ),
                      const ButtonSegment(
                        value: PaymentMethod.yape, 
                        label: Center(child: Text('Yape', style: TextStyle(fontSize: 12)))
                      ),
                      const ButtonSegment(
                        value: PaymentMethod.plin, 
                        label: Center(child: Text('Plin', style: TextStyle(fontSize: 12)))
                      ),
                    ],
                    selected: {_selectedMethod},
                    onSelectionChanged: (set) {
                       setState(() { _selectedMethod = set.first; });
                    },
                  );
                }
              ),
              const SizedBox(height: 28),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _selectedMethod == PaymentMethod.transfer ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    TextFormField(
                      controller: _bankNameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.bankNameLabel, 
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.savingsAccountLabel,
                        prefixIcon: const Icon(Icons.numbers_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cciCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.cciLabel,
                        prefixIcon: const Icon(Icons.vibration_rounded),
                      ),
                    ),
                  ],
                ),
                secondChild: Column(
                  children: [
                    TextFormField(
                      controller: _accountCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.registeredPhoneLabel(_selectedMethod == PaymentMethod.yape ? 'Yape' : 'Plin'), 
                        prefixIcon: const Icon(Icons.phone_android_rounded),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2E63),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text(l10n.savePaymentInfoAction, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
