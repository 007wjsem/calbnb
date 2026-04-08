import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../support/data/support_repository.dart';
import '../../support/domain/support_ticket.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/domain/subscription.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AdminSupportDashboard extends ConsumerWidget {
  const AdminSupportDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ticketsAsync = ref.watch(allSupportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.superAdminSupportMenu),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(child: Text(l10n.noTicketsMessage));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final isPriority = ticket.companyTier == SubscriptionTier.diamond || 
                                 ticket.companyTier == SubscriptionTier.platinum;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isPriority ? Colors.amber.withOpacity(0.5) : Colors.transparent,
                    width: isPriority ? 2 : 1,
                  ),
                ),
                elevation: isPriority ? 4 : 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: _getTierColor(ticket.companyTier).withValues(alpha: 0.1),
                    child: Icon(Icons.support_agent, color: _getTierColor(ticket.companyTier)),
                  ),
                  title: Row(
                    children: [
                      Text(ticket.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isPriority) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(l10n.priorityTicketLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ticket.userRole} • ${ticket.id.substring(0, 8)}'),
                      Text(
                        'Last update: ${DateFormat.yMMMd().add_jm().format(ticket.updatedAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ticket.status == 'open' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ticket.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold, 
                            color: ticket.status == 'open' ? Colors.green : Colors.grey
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/admin/support/${ticket.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.diamond: return Colors.amber.shade700;
      case SubscriptionTier.platinum: return Colors.blueGrey;
      case SubscriptionTier.gold: return Colors.orange;
      case SubscriptionTier.silver: return Colors.blue;
      case SubscriptionTier.bronze: return Colors.brown;
      case SubscriptionTier.free: return Colors.grey;
    }
  }
}

class AdminSupportDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const AdminSupportDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<AdminSupportDetailScreen> createState() => _AdminSupportDetailScreenState();
}

class _AdminSupportDetailScreenState extends ConsumerState<AdminSupportDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;

    final user = ref.read(authControllerProvider)!;
    final msg = SupportMessage(
      id: '',
      senderId: user.id,
      senderName: 'Admin Support',
      senderRole: 'superadmin',
      body: body,
      createdAt: DateTime.now(),
    );

    await ref.read(supportRepositoryProvider).addMessage(widget.ticketId, msg);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => ref.read(supportRepositoryProvider).closeTicket(widget.ticketId),
            tooltip: 'Close Ticket',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Ticket?'),
                  content: Text(l10n.deleteTicketConfirm),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true) {
                 await ref.read(supportRepositoryProvider).deleteTicket(widget.ticketId);
                 if (mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAdmin = msg.senderRole == 'superadmin';

                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppColors.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isAdmin ? Radius.zero : const Radius.circular(16),
                            bottomLeft: isAdmin ? const Radius.circular(16) : Radius.zero,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(msg.body, style: TextStyle(color: isAdmin ? Colors.white : Colors.black)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.jm().format(msg.createdAt),
                              style: TextStyle(fontSize: 10, color: isAdmin ? Colors.white70 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
