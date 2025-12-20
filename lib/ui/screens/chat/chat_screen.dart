import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(otherUserName)),
      body: Column(
        children: [
          /// ─────────── MESSAGE LIST ───────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Say hi 👋',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data() as Map<String, dynamic>;
                    final isMe = m['senderId'] == uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ─────────── INPUT ───────────
          ChatInput(chatId: chatId),
        ],
      ),
    );
  }
}

class ChatInput extends StatefulWidget {
  final String chatId;
  const ChatInput({super.key, required this.chatId});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final controller = TextEditingController();
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type a message',
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          IconButton(
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: sending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    /// Message (use Timestamp.now for first safety)
    await chatRef.collection('messages').add({
      'senderId': uid,
      'text': text,
      'createdAt': Timestamp.now(),
      'type': 'text',
    });

    /// Update chat summary
    await chatRef.update({
      'lastMessage': text,
      'lastSenderId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    controller.clear();
    setState(() => sending = false);
  }
}
