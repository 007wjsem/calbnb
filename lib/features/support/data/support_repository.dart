import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/support_ticket.dart';
import '../../auth/domain/user.dart';
import '../../company/domain/subscription.dart';

class SupportRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── Create Ticket ──────────────────────────────────────────────────────────
  Future<String> createTicket(User user, SubscriptionTier tier) async {
    final ref = _db.ref('support_tickets').push();
    final now = DateTime.now();
    final ticket = SupportTicket(
      id: ref.key!,
      userId: user.id,
      userName: user.username,
      userRole: user.role.displayName,
      companyId: user.activeCompanyId,
      companyTier: tier,
      status: 'open',
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(ticket.toMap());
    return ref.key!;
  }

  // ── Watch User's Tickets ───────────────────────────────────────────────────
  Stream<List<SupportTicket>> watchUserTickets(String userId) {
    return _db
        .ref('support_tickets')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snap = event.snapshot;
      final raw = snap.value;
      if (!snap.exists || raw == null) return [];
      
      Iterable<MapEntry<dynamic, dynamic>> entries;
      if (raw is Map) {
        entries = raw.entries;
      } else if (raw is List) {
        entries = raw.asMap().entries;
      } else {
        return [];
      }

      final tickets = <SupportTicket>[];
      for (final e in entries) {
        if (e.value == null) continue;
        try {
          tickets.add(SupportTicket.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)));
        } catch (err) {
          print('Error parsing ticket ${e.key}: $err');
        }
      }
      tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tickets;
    });
  }

  // ── Watch All Global Tickets (Admin) ───────────────────────────────────────
  Stream<List<SupportTicket>> watchAllTickets() {
    return _db.ref('support_tickets').onValue.map((event) {
      final snap = event.snapshot;
      final raw = snap.value;
      if (!snap.exists || raw == null) return [];
      
      Iterable<MapEntry<dynamic, dynamic>> entries;
      if (raw is Map) {
        entries = raw.entries;
      } else if (raw is List) {
        entries = raw.asMap().entries;
      } else {
        return [];
      }

      final tickets = <SupportTicket>[];
      for (final e in entries) {
        if (e.value == null) continue;
        try {
           tickets.add(SupportTicket.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)));
        } catch (err) {
           print('Error parsing global ticket ${e.key}: $err');
        }
      }

      tickets.sort((a, b) {
        // Priority first (Diamond, Platinum), then recency
        if (a.companyTier != b.companyTier) {
          return b.companyTier.index.compareTo(a.companyTier.index);
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return tickets;
    });
  }

  // ── Watch Ticket Messages ──────────────────────────────────────────────────
  Stream<List<SupportMessage>> watchTicketMessages(String ticketId) {
    return _db.ref('support_tickets/$ticketId/messages').onValue.map((event) {
      final snap = event.snapshot;
      final raw = snap.value;
      if (!snap.exists || raw == null) return [];
      
      final Map<dynamic, dynamic> map;
      if (raw is Map) {
        map = raw as Map;
      } else if (raw is List) {
        map = (raw as List).asMap();
      } else {
        return [];
      }

      final msgs = <SupportMessage>[];
      for (final e in map.entries) {
        if (e.value == null) continue;
        try {
           msgs.add(SupportMessage.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)));
        } catch (err) {
           print('Error parsing message ${e.key}: $err');
        }
      }
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return msgs;
    });
  }

  // ── Add Message ────────────────────────────────────────────────────────────
  Future<void> addMessage(String ticketId, SupportMessage message) async {
    final ref = _db.ref('support_tickets/$ticketId/messages').push();
    await ref.set(message.toMap());
    // Update ticket's updatedAt and set status to open if it was closed
    await _db.ref('support_tickets/$ticketId').update({
      'updatedAt': message.createdAt.toIso8601String(),
      'status': 'open',
    });
  }

  // ── Close/Delete Ticket ────────────────────────────────────────────────────
  Future<void> closeTicket(String ticketId) async {
    await _db.ref('support_tickets/$ticketId').update({'status': 'closed'});
  }

  Future<void> deleteTicket(String ticketId) async {
    await _db.ref('support_tickets/$ticketId').remove();
  }

}

final supportRepositoryProvider = Provider((ref) => SupportRepository());

final allSupportTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportRepositoryProvider).watchAllTickets();
});

final userSupportTicketsProvider = StreamProvider.family<List<SupportTicket>, String>((ref, userId) {
  return ref.watch(supportRepositoryProvider).watchUserTickets(userId);
});

final openTicketsCountProvider = Provider<AsyncValue<int>>((ref) {
  final ticketsAsync = ref.watch(allSupportTicketsProvider);
  return ticketsAsync.whenData((tickets) => tickets.where((t) => t.status == 'open').length);
});

final ticketMessagesProvider = StreamProvider.family<List<SupportMessage>, String>((ref, ticketId) {
  return ref.watch(supportRepositoryProvider).watchTicketMessages(ticketId);
});
