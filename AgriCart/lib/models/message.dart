class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final bool read;
  final String? createdAt;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.read,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['message_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'read': read,
      'created_at': createdAt,
    };
  }
}

