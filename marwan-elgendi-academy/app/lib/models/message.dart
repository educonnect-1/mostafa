import 'package:equatable/equatable.dart';

enum MessageAttachmentType { none, image, file }

MessageAttachmentType _attachmentTypeFromString(String? value) {
  return MessageAttachmentType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => MessageAttachmentType.none,
  );
}

class GroupMessage extends Equatable {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.content,
    this.attachmentStoragePath,
    required this.attachmentType,
    required this.pinned,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String? content;
  final String? attachmentStoragePath;
  final MessageAttachmentType attachmentType;
  final bool pinned;
  final DateTime createdAt;

  bool get hasAttachment => attachmentStoragePath != null;

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      attachmentStoragePath: json['attachment_storage_path'] as String?,
      attachmentType: _attachmentTypeFromString(json['attachment_type'] as String?),
      pinned: (json['pinned'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        senderId,
        content,
        attachmentStoragePath,
        attachmentType,
        pinned,
        createdAt,
      ];
}
