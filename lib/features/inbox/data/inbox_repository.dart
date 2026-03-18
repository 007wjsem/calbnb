import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/inbox_message.dart';

/// Repository for reading and writing team inbox messages.
///
/// Messages are stored at:
///   `companies/{companyId}/inbox/{messageId}`
class InboxRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── Real-time stream ───────────────────────────────────────────────────────
  Stream<List<InboxMessage>> watchMessages(String companyId) {
    return _db
        .ref('companies/$companyId/inbox')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final raw = event.snapshot.value;
      final Iterable<MapEntry<dynamic, dynamic>> entries;
      if (raw is Map) {
        entries = raw.entries;
      } else if (raw is List) {
        entries = raw.asMap().entries;
      } else {
        return [];
      }
      final messages = entries
          .where((e) => e.value is Map)
          .map((e) => InboxMessage.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
          .toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  // ── Unread count stream ────────────────────────────────────────────────────
  Stream<int> watchUnreadCount(String companyId, String userId) {
    return watchMessages(companyId).map((msgs) =>
        msgs.where((m) => !m.readBy.contains(userId)).length);
  }

  // ── Send message ───────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String companyId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String body,
  }) async {
    final ref = _db.ref('companies/$companyId/inbox').push();
    await ref.set({
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'body': body,
      'createdAt': ServerValue.timestamp,
      'readBy': {senderId: true},
    });
  }

  // ── Mark as read ───────────────────────────────────────────────────────────
  Future<void> markRead(String companyId, String messageId, String userId) async {
    await _db.ref('companies/$companyId/inbox/$messageId/readBy/$userId').set(true);
  }

  // ── Mark all as read ──────────────────────────────────────────────────────
  Future<void> markAllRead(String companyId, String userId, List<InboxMessage> messages) async {
    final updates = <String, dynamic>{};
    for (final m in messages) {
      if (!m.readBy.contains(userId)) {
        updates['companies/$companyId/inbox/${m.id}/readBy/$userId'] = true;
      }
    }
    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }
  }

  // ── Delete a message (admin/superAdmin only) ───────────────────────────────
  Future<void> deleteMessage(String companyId, String messageId) async {
    await _db.ref('companies/$companyId/inbox/$messageId').remove();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final inboxRepositoryProvider = Provider<InboxRepository>((ref) => InboxRepository());

final inboxMessagesProvider = StreamProvider.family<List<InboxMessage>, String>((ref, companyId) {
  return ref.watch(inboxRepositoryProvider).watchMessages(companyId);
});

final inboxUnreadCountProvider = StreamProvider.family<int, ({String companyId, String userId})>((ref, args) {
  return ref.watch(inboxRepositoryProvider).watchUnreadCount(args.companyId, args.userId);
});
