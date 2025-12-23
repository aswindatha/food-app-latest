import 'user.dart';

class Conversation {
  final int id;
  final int participant1Id;
  final int participant2Id;
  final String participant2Type;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final User participant1;
  final User participant2;

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.participant2Type,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.participant1,
    required this.participant2,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participant1Id: json['participant1_id'],
      participant2Id: json['participant2_id'],
      participant2Type: json['participant2_type'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      participant1: User.fromJson(json['participant1']),
      participant2: User.fromJson(json['participant2']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant1_id': participant1Id,
      'participant2_id': participant2Id,
      'participant2_type': participant2Type,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'participant1': participant1.toJson(),
      'participant2': participant2.toJson(),
    };
  }

  String get participant2TypeDisplay {
    switch (participant2Type) {
      case 'volunteer':
        return 'Volunteer';
      case 'organization':
        return 'Organization';
      default:
        return participant2Type;
    }
  }

  String get displayName {
    return '${participant2.firstName} ${participant2.lastName}';
  }

  String get lastMessageDisplay {
    if (lastMessage == null || lastMessage!.isEmpty) {
      return 'No messages yet';
    }
    if (lastMessage!.length > 50) {
      return '${lastMessage!.substring(0, 50)}...';
    }
    return lastMessage!;
  }
}
