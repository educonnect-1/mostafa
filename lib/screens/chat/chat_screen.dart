import 'package:flutter/material.dart';
import '../../repositories/message_repository.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({required this.conversationId, super.key});
  @override State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final repo = MessageRepository();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat')),
    body: Column(children: [
      Expanded(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: repo.watchMessages(widget.conversationId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(rows[i]['body'] as String? ?? ''),
                ),
              ),
            );
          },
        ),
      ),
      SafeArea(child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Expanded(child: TextField(controller: input, decoration: const InputDecoration(hintText: 'Message'))),
          IconButton(
            onPressed: () async {
              final text = input.text.trim();
              if (text.isEmpty) return;
              await repo.send(widget.conversationId, text);
              input.clear();
            },
            icon: const Icon(Icons.send),
          ),
        ]),
      )),
    ]),
  );
}
