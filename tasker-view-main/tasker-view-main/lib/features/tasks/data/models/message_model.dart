class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final bool isSystem;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.isSystem = false,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'image_url': imageUrl,
      'is_system': isSystem,
    };
  }
}

class ConversationModel {
  final String id;
  final String taskId;
  final String clientId;
  final String taskerId;
  final bool isActive;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.taskId,
    required this.clientId,
    required this.taskerId,
    this.isActive = true,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      clientId: json['client_id'] as String,
      taskerId: json['tasker_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
