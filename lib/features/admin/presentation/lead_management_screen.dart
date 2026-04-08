import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../onboarding/data/lead_repository.dart';
import '../../onboarding/domain/lead.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LeadManagementScreen extends ConsumerWidget {
  const LeadManagementScreen({super.key});

  Future<void> _contactLead(BuildContext context, Lead lead, AppLocalizations l10n) async {
    final name = lead.name;
    final message = l10n.leadContactTemplateWhatsApp(name);
    
    if (lead.contactPreference == 'whatsapp') {
      final phone = (lead.countryCode ?? '') + lead.contactInfo.replaceAll(RegExp(r'\D'), '');
      // Strip any '+' sign for the wa.me format
      final cleanPhone = phone.replaceAll('+', '');
      final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
      
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback or show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
        }
      }
    } else {
      final emailUrl = Uri.parse('mailto:${lead.contactInfo}?subject=${Uri.encodeComponent(l10n.leadContactTemplateEmailTitle)}&body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
      } else {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch Email app')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final leadsAsync = ref.watch(allLeadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.superAdminLeadsMenu),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: leadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (leads) {
          if (leads.isEmpty) {
            return Center(child: Text(l10n.noTicketsMessage));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leads.length,
            itemBuilder: (context, index) {
              final lead = leads[index];
              final isNew = lead.status == 'new';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isNew ? AppColors.primary.withOpacity(0.3) : Colors.transparent),
                ),
                elevation: isNew ? 4 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lead.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(
                                  DateFormat.yMMMd().add_jm().format(lead.timestamp),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isNew ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              lead.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                color: isNew ? AppColors.primary : AppColors.textSecondary
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            lead.contactPreference == 'whatsapp' ? Icons.chat_rounded : Icons.email_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lead.contactPreference == 'whatsapp' 
                                ? (lead.countryCode ?? '') + ' ' + lead.contactInfo 
                                : lead.contactInfo,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ref.read(leadRepositoryProvider).updateLeadStatus(
                                lead.id, 
                                lead.status == 'new' ? 'contacted' : 'registered'
                              ),
                              icon: const Icon(Icons.sync_alt, size: 18),
                              label: Text(lead.status == 'new' ? 'Mark Contacted' : 'Mark Registered'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _contactLead(context, lead, l10n),
                              icon: Icon(lead.contactPreference == 'whatsapp' ? Icons.chat : Icons.send),
                              label: Text(lead.contactPreference == 'whatsapp' ? 'WhatsApp' : 'Email'),
                              style: FilledButton.styleFrom(
                                backgroundColor: lead.contactPreference == 'whatsapp' ? const Color(0xFF25D366) : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Lead?'),
                                  content: const Text('Are you sure you want to remove this lead?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(leadRepositoryProvider).deleteLead(lead.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
