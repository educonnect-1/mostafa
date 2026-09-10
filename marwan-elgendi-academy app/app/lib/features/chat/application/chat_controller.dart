import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/message.dart';
import '../../../repositories/chat_repository.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.pinnedMessages = const [],
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.hasMoreHistory = true,
    this.sending = false,
    this.error,
  });

  /// Newest-first, matching how the chat ListView (reverse: true) wants them.
  final List<GroupMessage> messages;
  final List<GroupMessage> pinnedMessages;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMoreHistory;
  final bool sending;
  final AppException? error;

  ChatState copyWith({
    List<GroupMessage>? messages,
    List<GroupMessage>? pinnedMessages,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMoreHistory,
    bool? sending,
    AppException? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repository, this._groupId) : super(const ChatState()) {
    _init();
  }

  final ChatRepository _repository;
  final String _groupId;
  StreamSubscription<List<GroupMessage>>? _liveSub;

  Future<void> _init() async {
    try {
      final history = await _repository.fetchOlderMessages(_groupId);
      final pinned = await _repository.fetchPinnedMessages(_groupId);
      state = state.copyWith(
        messages: history,
        pinnedMessages: pinned,
        isLoadingInitial: false,
        hasMoreHistory: history.length >= ChatRepository.pageSize,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoadingInitial: false, error: e);
    }

    _liveSub = _repository.watchLiveMessages(_groupId).listen(_mergeLive);
  }

  void _mergeLive(List<GroupMessage> liveTail) {
    final byId = {for (final m in state.messages) m.id: m};
    for (final m in liveTail) {
      byId[m.id] = m;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final pinned = merged.where((m) => m.pinned).toList();

    state = state.copyWith(messages: merged, pinnedMessages: pinned);
  }

  Future<void> loadMoreHistory() async {
    if (state.isLoadingMore || !state.hasMoreHistory || state.messages.isEmpty) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final oldest = state.messages.last;
      final older = await _repository.fetchOlderMessages(
        _groupId,
        before: oldest.createdAt,
      );
      final byId = {for (final m in state.messages) m.id: m};
      for (final m in older) {
        byId[m.id] = m;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        messages: merged,
        isLoadingMore: false,
        hasMoreHistory: older.length >= ChatRepository.pageSize,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<bool> sendText(String content) async {
    if (content.trim().isEmpty) return false;
    state = state.copyWith(sending: true, clearError: true);
    try {
      await _repository.sendTextMessage(groupId: _groupId, content: content);
      state = state.copyWith(sending: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(sending: false, error: e);
      return false;
    }
  }

  Future<bool> sendAttachment({
    required File file,
    required MessageAttachmentType type,
    String? caption,
  }) async {
    state = state.copyWith(sending: true, clearError: true);
    try {
      await _repository.sendAttachmentMessage(
        groupId: _groupId,
        file: file,
        type: type,
        caption: caption,
      );
      state = state.copyWith(sending: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(sending: false, error: e);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatController, ChatState, String>((ref, groupId) {
  return ChatController(ref.read(chatRepositoryProvider), groupId);
});
