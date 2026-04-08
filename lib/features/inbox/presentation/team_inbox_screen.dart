import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../data/inbox_repository.dart';
import '../domain/inbox_message.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user.dart';
import '../../admin/data/user_repository.dart';
import '../../company/presentation/subscription_guard.dart';
import '../../company/domain/subscription.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/roles.dart';
import 'package:calbnb/l10n/app_localizations.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String _selectedChannelId = 'general';
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
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider);
    final companyId = user?.activeCompanyId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamInboxTitle), // Now "Inbox"
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SubscriptionGuard(
        requiredTier: SubscriptionTier.silver,
        child: SafeArea(
          child: Column(
            children: [
              // ── Channel Selector ──────────────────────────────────────────
              _ChannelSelector(
                selectedChannelId: _selectedChannelId,
                onChannelChanged: (id) => setState(() => _selectedChannelId = id),
              ),
              
              // ── Chat Body ──────────────────────────────────────────────────
              Expanded(
                child: _InboxBody(
                  channelId: _selectedChannelId,
                  msgCtrl: _msgCtrl,
                  scrollCtrl: _scrollCtrl,
                  sending: _sending,
                  scrollToBottom: _scrollToBottom,
                  onSend: (cid) => _sendMessage(companyId, cid),
                  onMarkAllRead: _markAllRead,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String companyId, String channelId) async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    final user = ref.read(authControllerProvider);
    if (user == null) { setState(() => _sending = false); return; }
    await ref.read(inboxRepositoryProvider).sendMessage(
      companyId: companyId,
      channelId: channelId,
      senderId: user.id,
      senderName: user.username,
      senderRole: user.role.displayName,
      body: body,
    );
    _msgCtrl.clear();
    setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _markAllRead(String companyId, String channelId, List<InboxMessage> messages) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    await ref.read(inboxRepositoryProvider).markAllRead(companyId, channelId, user.id, messages);
  }
}

// ── Channel Selector ──────────────────────────────────────────────────────────

class _ChannelSelector extends ConsumerWidget {
  final String selectedChannelId;
  final ValueChanged<String> onChannelChanged;

  const _ChannelSelector({
    required this.selectedChannelId,
    required this.onChannelChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final companyId = user.activeCompanyId ?? '';
    
    final membersAsync = ref.watch(companyMembersProvider(companyId));
    final members = membersAsync.valueOrNull ?? [];

    final List<_ChannelItem> channels = [
      _ChannelItem(id: 'general', title: l10n.generalChannel, icon: Icons.groups_rounded),
    ];

    if (user.role == AppRole.administrator || user.role == AppRole.superAdmin || user.role == AppRole.manager || user.role == AppRole.cleaner) {
      channels.add(_ChannelItem(id: 'cleaners', title: l10n.cleanersChannel, icon: Icons.cleaning_services_rounded));
    }
    if (user.role == AppRole.administrator || user.role == AppRole.superAdmin || user.role == AppRole.manager || user.role == AppRole.inspector) {
      channels.add(_ChannelItem(id: 'inspectors', title: l10n.inspectorsChannel, icon: Icons.fact_check_rounded));
    }

    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        children: [
          // ── Group Channels ──────────────────────────────────────────
          ...channels.map((c) => _buildChip(c.title, c.id, icon: c.icon)),
          
          const VerticalDivider(width: 24, indent: 8, endIndent: 8),

          // ── Direct Messages ──────────────────────────────────────────
          ...members.where((m) => m.id != user.id).map((m) {
            final threadId = _getDirectThreadId(user.id, m.id);
            return _buildChip(m.username, threadId, isAvatar: true);
          }),
        ],
      ),
    );
  }

  String _getDirectThreadId(String u1, String u2) {
    final ids = [u1, u2]..sort();
    return 'direct_${ids[0]}_${ids[1]}';
  }

  Widget _buildChip(String label, String id, {IconData? icon, bool isAvatar = false}) {
    final isSelected = selectedChannelId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: () => onChannelChanged(id),
        avatar: isAvatar 
          ? CircleAvatar(radius: 12, backgroundColor: isSelected ? Colors.white24 : AppColors.primary.withOpacity(0.1), 
              child: Text(label[0].toUpperCase(), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.primary)))
          : (icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary) : null),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: isSelected ? AppColors.primary : AppColors.background,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _ChannelItem {
  final String id;
  final String title;
  final IconData icon;
  _ChannelItem({required this.id, required this.title, required this.icon});
}

// ── Inbox Body ───────────────────────────────────────────────────────────────

class _InboxBody extends ConsumerWidget {
  final String channelId;
  final TextEditingController msgCtrl;
  final ScrollController scrollCtrl;
  final bool sending;
  final VoidCallback scrollToBottom;
  final Function(String) onSend;
  final Function(String, String, List<InboxMessage>) onMarkAllRead;

  const _InboxBody({
    required this.channelId,
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
    if (companyId.isEmpty) return const SizedBox.shrink();

    final messagesAsync = ref.watch(inboxMessagesProvider((companyId: companyId, channelId: channelId)));

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (messages) {
        // Auto-read logic
        if (messages.any((m) => !m.isReadBy(user?.id ?? ''))) {
          onMarkAllRead(companyId, channelId, messages);
        }
        
        scrollToBottom();

        return Column(
          children: [
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
                        return _MessageBubble(message: m, isMe: m.senderId == user?.id, isUnread: !m.isReadBy(user?.id ?? ''));
                      },
                    ),
            ),

            // ── Compose bar ────────────────────────────────────────────────
            Material(
              color: AppColors.surface,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                                fillColor: AppColors.background.withOpacity(0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onSubmitted: (_) => onSend(channelId),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: sending ? null : () => onSend(channelId),
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
                ),
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
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
                    color: isUnread && !isMe ? AppColors.teal.withValues(alpha: 0.1) : bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
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
