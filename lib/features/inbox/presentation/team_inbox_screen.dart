import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../data/inbox_repository.dart';
import '../domain/inbox_message.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/presentation/subscription_guard.dart';
import '../../company/domain/subscription.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';

class TeamInboxScreen extends ConsumerStatefulWidget {
  const TeamInboxScreen({super.key});

  @override
  ConsumerState<TeamInboxScreen> createState() => _TeamInboxScreenState();
}

class _TeamInboxScreenState extends ConsumerState<TeamInboxScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.teamInboxTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          _UnreadCountBadge(),
        ],
      ),
      body: SubscriptionGuard(
        requiredTier: SubscriptionTier.silver,
        child: _InboxBody(
          msgCtrl: _msgCtrl,
          scrollCtrl: _scrollCtrl,
          sending: _sending,
          scrollToBottom: _scrollToBottom,
          onSend: _sendMessage,
          onMarkAllRead: _markAllRead,
        ),
      ),
    );
  }

  Future<void> _sendMessage(String companyId) async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    final user = ref.read(authControllerProvider);
    if (user == null) { setState(() => _sending = false); return; }
    await ref.read(inboxRepositoryProvider).sendMessage(
      companyId: companyId,
      senderId: user.id,
      senderName: user.username,
      senderRole: user.role.displayName,
      body: body,
    );
    _msgCtrl.clear();
    setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _markAllRead(String companyId, List<InboxMessage> messages) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    await ref.read(inboxRepositoryProvider).markAllRead(companyId, user.id, messages);
  }
}

// ── Inner body (given companyId from auth) ────────────────────────────────────

class _InboxBody extends ConsumerWidget {
  final TextEditingController msgCtrl;
  final ScrollController scrollCtrl;
  final bool sending;
  final VoidCallback scrollToBottom;
  final Future<void> Function(String) onSend;
  final Future<void> Function(String, List<InboxMessage>) onMarkAllRead;

  const _InboxBody({
    required this.msgCtrl,
    required this.scrollCtrl,
    required this.sending,
    required this.scrollToBottom,
    required this.onSend,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final companyId = user?.activeCompanyId ?? '';
    if (companyId.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noActiveCompanyFound));
    }

    final messagesAsync = ref.watch(inboxMessagesProvider(companyId));

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace _) => Center(child: Text(AppLocalizations.of(context)!.genericError(e.toString()))),
      data: (messages) {
        // Auto-scroll when new messages arrive
        scrollToBottom();

        return Column(
          children: [
            // ── Mark All Read bar ────────────────────────────────────────
            if (messages.any((m) => !m.isReadBy(user?.id ?? '')))
              Material(
                color: AppColors.teal.withOpacity(0.08),
                child: InkWell(
                  onTap: () => onMarkAllRead(companyId, messages),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.done_all, size: 16, color: AppColors.teal),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.markAllAsReadAction, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Message list ──────────────────────────────────────────────
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.border),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.of(context)!.noMessagesYetDesc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        final isMe = m.senderId == user?.id;
                        final isUnread = !m.isReadBy(user?.id ?? '');
                        return _MessageBubble(message: m, isMe: isMe, isUnread: isUnread);
                      },
                    ),
            ),

            // ── Compose bar ────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgCtrl,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeMessageHint,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => onSend(companyId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: sending ? null : () => onSend(companyId),
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      backgroundColor: AppColors.primary,
                    ),
                    child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final InboxMessage message;
  final bool isMe;
  final bool isUnread;

  const _MessageBubble({required this.message, required this.isMe, required this.isUnread});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColors.primary : Colors.white;
    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final timeStr = DateFormat.jm().format(message.createdAt);
    final dateStr = DateFormat.MMMd().format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Row(
                      children: [
                        Text(message.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const SizedBox(width: 4),
                        Text('· ${message.senderRole}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUnread && !isMe ? AppColors.teal.withOpacity(0.1) : bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(message.body, style: TextStyle(color: textColor, fontSize: 14, height: 1.4)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text('$dateStr $timeStr', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unread count badge shown in AppBar ────────────────────────────────────────

class _UnreadCountBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final companyId = user?.activeCompanyId ?? '';
    if (companyId.isEmpty || user == null) return const SizedBox.shrink();

    final countAsync = ref.watch(inboxUnreadCountProvider((companyId: companyId, userId: user.id)));
    final count = countAsync.valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Badge(
        label: Text('$count'),
        child: const Icon(Icons.mark_email_unread_outlined),
      ),
    );
  }
}
