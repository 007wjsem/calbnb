class InboxMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String body;
  final DateTime createdAt;
  final Set<String> readBy;

  const InboxMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    required this.readBy,
  });

  factory InboxMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    final readByRaw = map['readBy'] as Map<dynamic, dynamic>? ?? {};
    return InboxMessage(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? 'Unknown',
      senderRole: map['senderRole']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      readBy: readByRaw.keys.map((k) => k.toString()).toSet(),
    );
  }

  bool isReadBy(String userId) => readBy.contains(userId);
}
