import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/exception_mapper.dart';
import '../models/message.dart';
import '../services/storage_service.dart';

/// Chat is realtime (spec §8) but must never load an entire group's
/// history at once (spec §38). The pattern here is:
///   1. `fetchOlderMessages` — keyset-paginated history, newest-first,
///      called on initial load and on "load more" scroll-up.
///   2. `watchLiveMessages` — a Supabase Realtime stream of just the
///      most recent page, which the controller merges with history and
///      dedupes by id so new messages appear without a manual refresh.
class ChatRepository {
  ChatRepository(this._client, this._storageService);

  final SupabaseClient _client;
  final StorageService _storageService;

  static const pageSize = 30;
  static const liveTailSize = 50;

  Future<List<GroupMessage>> fetchOlderMessages(
    String groupId, {
    DateTime? before,
  }) {
    return runGuarded(() async {
      var query = _client.from('group_messages').select().eq('group_id', groupId);
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }
      final rows =
          await query.order('created_at', ascending: false).limit(pageSize);
      return (rows as List)
          .map((r) => GroupMessage.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<GroupMessage>> fetchPinnedMessages(String groupId) {
    return runGuarded(() async {
      final rows = await _client
          .from('group_messages')
          .select()
          .eq('group_id', groupId)
          .eq('pinned', true)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => GroupMessage.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }

  /// Realtime tail of the most recent messages in this group. The
  /// controller diffs this against already-loaded history to append
  /// only genuinely new rows.
  Stream<List<GroupMessage>> watchLiveMessages(String groupId) {
    return _client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(liveTailSize)
        .map(
          (rows) => rows.map((r) => GroupMessage.fromJson(r)).toList(),
        );
  }

  Future<void> sendTextMessage({
    required String groupId,
    required String content,
  }) {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();
      final trimmed = content.trim();
      if (trimmed.isEmpty) {
        throw const ValidationAppException('Message cannot be empty.');
      }
      await _client.from('group_messages').insert({
        'group_id': groupId,
        'sender_id': uid,
        'content': trimmed,
      });
    });
  }

  Future<void> sendAttachmentMessage({
    required String groupId,
    required File file,
    required MessageAttachmentType type,
    String? caption,
  }) {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();

      final path = await _storageService.uploadChatAttachment(
        groupId: groupId,
        file: file,
      );

      await _client.from('group_messages').insert({
        'group_id': groupId,
        'sender_id': uid,
        'content': caption,
        'attachment_storage_path': path,
        'attachment_type': type.name,
      });
    });
  }

  Future<String> getAttachmentUrl(String storagePath) {
    return _storageService.getSignedUrl(
      bucket: 'chat-attachments',
      path: storagePath,
    );
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    SupabaseConfig.client,
    ref.read(storageServiceProvider),
  );
});
