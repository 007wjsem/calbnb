import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/support_repository.dart';
import '../domain/support_ticket.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/subscription.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class UserSupportScreen extends ConsumerStatefulWidget {
  const UserSupportScreen({super.key});

  @override
  ConsumerState<UserSupportScreen> createState() => _UserSupportScreenState();
}

class _UserSupportScreenState extends ConsumerState<UserSupportScreen> {
  Future<void> _createNewTicket() async {
    final user = ref.read(authControllerProvider)!;
    final companyId = user.activeCompanyId;
    SubscriptionTier tier = SubscriptionTier.free;

    if (companyId != null && companyId.isNotEmpty) {
      final companyAsync = ref.read(companyProvider(companyId));
      tier = companyAsync.valueOrNull?.tier ?? SubscriptionTier.free;
    }

    final ticketId = await ref.read(supportRepositoryProvider).createTicket(user, tier);
    if (mounted) {
      context.push('/support/$ticketId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider)!;
    final ticketsAsync = ref.watch(userSupportTicketsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportTitle),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.support_agent_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(l10n.noTicketsMessage),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createNewTicket,
                    child: Text(l10n.newTicketButton),
                  ),
                ],
              ),
            );
          }

          final openTicket = tickets.where((t) => t.status == 'open').firstOrNull;

          return Column(
            children: [
              if (openTicket != null)
                ListTile(
                  tileColor: AppColors.primary.withValues(alpha: 0.05),
                  leading: const Icon(Icons.mark_chat_unread_outlined, color: AppColors.primary),
                  title: const Text('Active Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Last update: ${DateFormat.yMMMd().add_jm().format(openTicket.updatedAt)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/support/${openTicket.id}'),
                ),
              if (openTicket == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _createNewTicket,
                    child: Text(l10n.newTicketButton),
                  ),
                ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Past Tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tickets.where((t) => t.status == 'closed').length,
                  itemBuilder: (context, index) {
                    final ticket = tickets.where((t) => t.status == 'closed').toList()[index];
                    return ListTile(
                      title: Text('Ticket ${ticket.id.substring(0, 8)}'),
                      subtitle: Text('Resolved on ${DateFormat.yMMMd().format(ticket.updatedAt)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => ref.read(supportRepositoryProvider).deleteTicket(ticket.id),
                      ),
                      onTap: () => context.push('/support/${ticket.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class UserSupportDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const UserSupportDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<UserSupportDetailScreen> createState() => _UserSupportDetailScreenState();
}

class _UserSupportDetailScreenState extends ConsumerState<UserSupportDetailScreen> {
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
      senderName: user.username,
      senderRole: user.role.displayName.toLowerCase(),
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
        title: Text(l10n.supportTitle),
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
                    final isMe = msg.senderRole != 'superadmin';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(msg.body, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.jm().format(msg.createdAt),
                              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
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
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue...',
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
