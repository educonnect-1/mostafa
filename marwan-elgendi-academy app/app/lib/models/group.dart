import 'package:equatable/equatable.dart';

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.chatEnabled,
    required this.memberCount,
  });

  final String id;
  final String name;
  final String? description;
  final bool chatEnabled;
  final int memberCount;

  /// Expects a row selected with an embedded count, e.g.
  /// `.select('*, group_members(count)')`.
  factory Group.fromJson(Map<String, dynamic> json) {
    int memberCount = 0;
    final embedded = json['group_members'];
    if (embedded is List && embedded.isNotEmpty) {
      final first = embedded.first;
      if (first is Map && first['count'] != null) {
        memberCount = (first['count'] as num).toInt();
      }
    }
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      chatEnabled: (json['chat_enabled'] as bool?) ?? false,
      memberCount: memberCount,
    );
  }

  @override
  List<Object?> get props => [id, name, description, chatEnabled, memberCount];
}
