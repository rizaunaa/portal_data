class GlobalChatMessage {
  const GlobalChatMessage({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String senderUserId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  factory GlobalChatMessage.fromMap(Map<String, dynamic> map) {
    return GlobalChatMessage(
      id: map['id'] as String? ?? '',
      senderUserId: map['sender_user_id'] as String? ?? '',
      senderName: map['sender_name'] as String? ?? 'User',
      message: map['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'sender_user_id': senderUserId,
      'sender_name': senderName,
      'message': message,
    };
  }
}
