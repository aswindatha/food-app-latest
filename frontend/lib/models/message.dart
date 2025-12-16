import 'user.dart';

class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String messageText;
  final bool isRead;
  final DateTime createdAt;
  final User sender;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageText,
    required this.isRead,
    required this.createdAt,
    required this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      sender: User.fromJson(json['sender']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_text': messageText,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender': sender.toJson(),
    };
  }

  String get timeDisplay {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
