import 'package:equatable/equatable.dart';

enum ResourceType { pdf, image, video, link, document }

ResourceType _typeFromString(String value) {
  return ResourceType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => ResourceType.document,
  );
}

class Resource extends Equatable {
  const Resource({
    required this.id,
    required this.groupId,
    required this.title,
    required this.type,
    this.storagePath,
    this.externalUrl,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String title;
  final ResourceType type;
  final String? storagePath;
  final String? externalUrl;
  final DateTime createdAt;

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      type: _typeFromString(json['type'] as String),
      storagePath: json['storage_path'] as String?,
      externalUrl: json['external_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, groupId, title, type, storagePath, externalUrl, createdAt];
}
