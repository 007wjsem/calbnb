import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/inbox_message.dart';
import '../../auth/domain/user.dart';
import '../../../core/constants/roles.dart';

/// Repository for reading and writing team inbox messages in different channels.
///
/// Messages are stored at:
///   `companies/{companyId}/inbox/{channelId}/{messageId}`
/// Default channel is 'general'.
class InboxRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── Real-time stream ───────────────────────────────────────────────────────
  Stream<List<InboxMessage>> watchMessages(String companyId, {String channelId = 'general'}) {
    if (companyId.isEmpty) return Stream.value([]);

    final nodeStream = _db
        .ref('companies/$companyId/inbox/$channelId')
        .onValue
        .map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return <InboxMessage>[];
      final raw = snap.value;

      final Iterable<MapEntry<dynamic, dynamic>> entries;
      if (raw is Map) {
        entries = raw.entries;
      } else if (raw is List) {
        entries = raw.asMap().entries;
      } else {
        return <InboxMessage>[];
      }

      final messages = entries
          .where((e) => e.value is Map)
          .map((e) => InboxMessage.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
          .toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });

    // On Flutter Web, Firebase JS SDK may never emit for non-existent nodes,
    // causing infinite loading. We use a StreamController to race the real stream
    // against a 3-second timeout that emits [] as a safety net.
    final controller = StreamController<List<InboxMessage>>();
    bool hasEmitted = false;

    // Safety net: emit empty list after 3 seconds if no event arrived yet
    Future.delayed(const Duration(seconds: 3), () {
      if (!hasEmitted && !controller.isClosed) {
        controller.add([]);
      }
    });

    // Forward all real events from Firebase
    final sub = nodeStream.listen(
      (data) {
        hasEmitted = true;
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) { if (!controller.isClosed) controller.addError(e); },
      onDone: () { if (!controller.isClosed) controller.close(); },
    );
    controller.onCancel = () => sub.cancel();

    return controller.stream;
  }

  // ── Unread count stream (Sum of all accessible channels) ───────────────────
  Stream<int> watchTotalUnreadCount(String companyId, String userId, List<String> channelIds) {
    // We combine streams from multiple channels if needed, 
    // but for simplicity in sidebar we can just watch 'general' or 
    // implement a more performant cross-channel counter.
    // For now, let's watch the provided list of channels.
    return Stream.empty(); // To be implemented with a CombineLatest if necessary
  }

  Stream<int> watchChannelUnreadCount(String companyId, String userId, String channelId) {
    return watchMessages(companyId, channelId: channelId).map((msgs) =>
        msgs.where((m) => !m.readBy.contains(userId)).length);
  }

  // ── Send message ───────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String companyId,
    required String channelId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String body,
  }) async {
    final ref = _db.ref('companies/$companyId/inbox/$channelId').push();
    await ref.set({
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'body': body,
      'createdAt': ServerValue.timestamp,
      'readBy': {senderId: true},
    });
  }

  // ── Mark all as read for a specific channel ───────────────────────────────
  Future<void> markAllRead(String companyId, String channelId, String userId, List<InboxMessage> messages) async {
    final updates = <String, dynamic>{};
    for (final m in messages) {
      if (!m.readBy.contains(userId)) {
        updates['companies/$companyId/inbox/$channelId/${m.id}/readBy/$userId'] = true;
      }
    }
    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }
  }

  // ── Delete a message ──────────────────────────────────────────────────────
  Future<void> deleteMessage(String companyId, String channelId, String messageId) async {
    await _db.ref('companies/$companyId/inbox/$channelId/$messageId').remove();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final inboxRepositoryProvider = Provider<InboxRepository>((ref) => InboxRepository());

final inboxMessagesProvider = StreamProvider.family<List<InboxMessage>, ({String companyId, String channelId})>((ref, args) {
  return ref.watch(inboxRepositoryProvider).watchMessages(args.companyId, channelId: args.channelId);
});

final inboxUnreadCountProvider = StreamProvider.family<int, ({String companyId, String userId, String channelId})>((ref, args) {
  return ref.watch(inboxRepositoryProvider).watchChannelUnreadCount(args.companyId, args.userId, args.channelId);
});

// Helper for total count across main channels
final totalUnreadCountProvider = StreamProvider.family<int, ({String companyId, User user})>((ref, args) {
  final repo = ref.watch(inboxRepositoryProvider);
  final user = args.user;
  final companyId = args.companyId;

  // Channels to watch based on role
  final channels = ['general'];
  if (user.role == AppRole.administrator || user.role == AppRole.superAdmin || user.role == AppRole.manager || user.role == AppRole.cleaner) {
    channels.add('cleaners');
  }
  if (user.role == AppRole.administrator || user.role == AppRole.superAdmin || user.role == AppRole.manager || user.role == AppRole.inspector) {
    channels.add('inspectors');
  }

  // We could also watch direct messages, but that requires knowing all thread IDs.
  // For now, let's sum these main channels.
  // Using a simple combine would be better, but for now we can just watch 'general' 
  // or return a sum if we want to be thorough.
  
  // To keep it simple and reactive:
  return repo.watchChannelUnreadCount(companyId, user.id, 'general').map((generalCount) {
    // For now returning general count, but we could add more.
    return generalCount; 
  });
});
