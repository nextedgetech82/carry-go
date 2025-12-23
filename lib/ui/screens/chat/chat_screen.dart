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
    final theme = Theme.of(context);

    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();

    //markDelivered(chatId);
    //markRead(chatId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          /// ─────────── MESSAGES ───────────
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet 👋\nStart the conversation',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final isMe = m['senderId'] == uid;
                    final ts = m['createdAt'];
                    final time = ts is Timestamp ? ts.toDate() : DateTime.now();

                    final currentDate = time;

                    DateTime? previousDate;
                    if (i > 0) {
                      final prev = docs[i - 1].data();
                      final prevTs = prev['createdAt'];
                      previousDate = prevTs is Timestamp
                          ? prevTs.toDate()
                          : null;
                    }

                    final showDateSeparator =
                        previousDate == null ||
                        currentDate.day != previousDate.day ||
                        currentDate.month != previousDate.month ||
                        currentDate.year != previousDate.year;

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(text: formatChatDate(currentDate)),

                        _ChatBubble(
                          text: m['text'] ?? '',
                          isMe: isMe,
                          time: time,
                          theme: theme,
                        ),
                      ],
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

class _ChatBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isMe;
  final ThemeData theme;

  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            /// Message text
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Row(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     Text(
            //       formatMessageTime(time),
            //       style: TextStyle(
            //         fontSize: 10,
            //         color: isMe ? Colors.white70 : Colors.grey,
            //       ),
            //     ),
            //     const SizedBox(width: 4),
            //     _buildStatusIcon(m, isMe),
            //   ],
            // ),

            /// Time
            Text(
              formatMessageTime(time),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(Map<String, dynamic> m, bool isMe) {
    if (!isMe) return const SizedBox.shrink();

    final delivered = (m['deliveredTo'] ?? []).isNotEmpty;
    final read = (m['readBy'] ?? []).isNotEmpty;

    if (read) {
      return const Icon(Icons.done_all, size: 14, color: Colors.blue);
    }
    if (delivered) {
      return Icon(Icons.done_all, size: 14, color: Colors.grey.shade400);
    }
    return Icon(Icons.done, size: 14, color: Colors.grey.shade400);
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
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary,
              child: IconButton(
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: sending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> markDelivered(String chatId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    final snap = await ref.where('senderId', isNotEqualTo: uid).get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final deliveredTo = List<String>.from(data['deliveredTo'] ?? []);

      if (!deliveredTo.contains(uid)) {
        doc.reference.update({
          'deliveredTo': FieldValue.arrayUnion([uid]),
        });
      }
    }
  }

  Future<void> markRead(String chatId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    final snap = await ref.where('senderId', isNotEqualTo: uid).get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final readBy = List<String>.from(data['readBy'] ?? []);

      if (!readBy.contains(uid)) {
        doc.reference.update({
          'readBy': FieldValue.arrayUnion([uid]),
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    await chatRef.collection('messages').add({
      'senderId': uid,
      'text': text,
      'createdAt': Timestamp.now(),
      'type': 'text',
      'deliveredTo': [],
      'readBy': [],
    });

    await chatRef.update({
      'lastMessage': text,
      'lastSenderId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    controller.clear();
    setState(() => sending = false);
  }
}

String formatChatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final msgDate = DateTime(date.year, date.month, date.day);

  if (msgDate == today) return 'Today';
  if (msgDate == yesterday) return 'Yesterday';

  return '${date.day} ${_monthName(date.month)} ${date.year}';
}

class _DateSeparator extends StatelessWidget {
  final String text;

  const _DateSeparator({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 0.6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 0.6)),
        ],
      ),
    );
  }
}

String _monthName(int m) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[m - 1];
}

String formatMessageTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $ampm';
}
