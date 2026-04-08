import 'package:flutter/foundation.dart';
import '../../company/domain/subscription.dart';

@immutable
class SupportMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SupportMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    return SupportMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? '',
      body: map['body'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

@immutable
class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String? companyId;
  final SubscriptionTier companyTier;
  final String status; // 'open', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SupportMessage> messages;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.companyId,
    required this.companyTier,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'companyId': companyId,
      'companyTier': companyTier.name,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SupportTicket.fromMap(String id, Map<dynamic, dynamic> map, {List<SupportMessage> messages = const []}) {
    return SupportTicket(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      companyId: map['companyId'],
      companyTier: SubscriptionTier.values.firstWhere(
        (t) => t.name == map['companyTier'],
        orElse: () => SubscriptionTier.free,
      ),
      status: map['status'] ?? 'open',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      messages: messages,
    );
  }

  SupportTicket copyWith({
    String? status,
    DateTime? updatedAt,
    List<SupportMessage>? messages,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      companyId: companyId,
      companyTier: companyTier,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
