import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/message.dart';
import '../../../repositories/chat_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../groups/application/groups_controller.dart';
import '../application/chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatControllerProvider(widget.groupId).notifier).loadMoreHistory();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    final ok = await ref
        .read(chatControllerProvider(widget.groupId).notifier)
        .sendAttachment(file: File(picked.path), type: MessageAttachmentType.image);
    _handleSendResult(ok);
  }

  void _handleSendResult(bool ok) {
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(chatControllerProvider(widget.groupId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.message ?? 'Could not send message.')),
      );
      ref.read(chatControllerProvider(widget.groupId).notifier).clearError();
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    final ok = await ref
        .read(chatControllerProvider(widget.groupId).notifier)
        .sendText(text);
    _handleSendResult(ok);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider(widget.groupId));
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));
    final myId = ref.read(authControllerProvider.notifier).currentUserIdOrNull;

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.maybeWhen(
          data: (g) => Text(g.name),
          orElse: () => const Text('Chat'),
        ),
      ),
      body: Column(
        children: [
          if (chatState.pinnedMessages.isNotEmpty)
            _PinnedBanner(messages: chatState.pinnedMessages),
          Expanded(
            child: chatState.isLoadingInitial
                ? const LoadingView()
                : chatState.messages.isEmpty
                    ? const EmptyView(
                        icon: Icons.chat_bubble_outline,
                        title: 'No messages yet',
                        subtitle: 'Say hello to your group!',
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: chatState.messages.length +
                            (chatState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final message = chatState.messages[index];
                          return _MessageBubble(
                            message: message,
                            isMine: message.senderId == myId,
                          );
                        },
                      ),
          ),
          _MessageInput(
            controller: _textController,
            onSendText: _sendText,
            onAttachImage: _pickAndSendImage,
            sending: chatState.sending,
          ),
        ],
      ),
    );
  }
}

class _PinnedBanner extends StatelessWidget {
  const _PinnedBanner({required this.messages});
  final List<GroupMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppBrand.secondary.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.push_pin, size: 16, color: AppBrand.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              messages.first.content ?? 'Pinned attachment',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message, required this.isMine});
  final GroupMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine
        ? AppBrand.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.hasAttachment) _AttachmentPreview(message: message),
                if (message.content != null && message.content!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: message.hasAttachment ? AppSpacing.xs : 0),
                    child: Text(message.content!, style: TextStyle(color: textColor)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              DateFormat.jm().format(message.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends ConsumerWidget {
  const _AttachmentPreview({required this.message});
  final GroupMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.attachmentType != MessageAttachmentType.image) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.insert_drive_file_outlined, size: 20),
          SizedBox(width: AppSpacing.xs),
          Text('Attachment'),
        ],
      );
    }

    return FutureBuilder<String>(
      future: ref
          .read(chatRepositoryProvider)
          .getAttachmentUrl(message.attachmentStoragePath!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            width: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: snapshot.data!,
            height: 160,
            width: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
              height: 160,
              width: 200,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => const SizedBox(
              height: 160,
              width: 200,
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        );
      },
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.onSendText,
    required this.onAttachImage,
    required this.sending,
  });

  final TextEditingController controller;
  final VoidCallback onSendText;
  final VoidCallback onAttachImage;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: sending ? null : onAttachImage,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendText(),
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: sending ? null : onSendText,
            ),
          ],
        ),
      ),
    );
  }
}
