import 'dart:convert';

import 'package:carrygo/ui/screens/buyer/my_requests/my_requests_provider.dart';
import 'package:carrygo/ui/screens/buyer/request_timeline/request_status.dart';
import 'package:carrygo/ui/screens/chat/dispute_evidance_screen.dart';
import 'package:carrygo/ui/screens/chat/traveler_chatstream_provider.dart';
import 'package:carrygo/ui/screens/dashboard/accept_trip_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends ConsumerWidget {
  final String chatId;
  final String otherUserName;
  final String requestId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    final requestAsync = ref.watch(requestByIdProvider(requestId));
    String reqStatus = "";
    // final otherUserProfileAsync =
    // ref.watch(userProfileByIdProvider(otherUserId));

    //final otherUserIdAsync = ref.watch(chatOtherUserIdProvider(chatId));

    //final requestAsync = ref.watch(requestByIdProvider(chatId));

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

        /// 🔥 ACTION BUTTON IN HEADER
        // actions: [
        //   requestAsync.when(
        //     loading: () => const SizedBox.shrink(),
        //     error: (_, __) => const SizedBox.shrink(),
        //     data: (reqSnap) {
        //       if (!reqSnap.exists) return const SizedBox.shrink();

        //       final r = reqSnap.data()!;
        //       final status = r['status'] as String;
        //       final isTraveller = r['travellerId'] == uid;

        //       return _ChatStatusAction(
        //         requestId: requestId,
        //         status: status,
        //         isTraveller: isTraveller,
        //         chatId: chatId,
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          requestAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (reqSnap) {
              if (!reqSnap.exists) return const SizedBox.shrink();

              final r = reqSnap.data()!;
              final status = r['status'] as String;
              final isTraveller = r['travellerId'] == uid;
              reqStatus = status;

              return _ChatActionBar(
                requestId: requestId,
                status: status,
                isTraveller: isTraveller,
                chatId: chatId,
              );
            },
          ),

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
          //ChatInput(chatId: chatId),
          if (reqStatus != RequestStatus.completed)
            ChatInput(chatId: chatId)
          else
            const _ChatLockedBanner(),
        ],
      ),
    );
  }
}

Widget infoChip({
  required String text,
  IconData? icon,
  Color color = const Color(0xFF2E86DE),
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.12),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
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

class _ChatStatusAction extends ConsumerWidget {
  final String requestId;
  final String status;
  final String chatId;
  final bool isTraveller;

  const _ChatStatusAction({
    required this.requestId,
    required this.status,
    required this.isTraveller,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Future<void> update(String newStatus) async {
    //   await updateRequestStatus(
    //     requestId: requestId,
    //     newStatus: newStatus,
    //     chatId: chatId,
    //   );

    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text('Status updated')));
    // }
    Future<void> update2(String newStatus) async {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      print(
        FirebaseFunctions.instance.httpsCallable('updateTransactionStatus'),
      );

      final callable = functions.httpsCallable('updateTransactionStatus');

      await callable.call({'tripRequestId': requestId, 'newStatus': newStatus});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Status updated')));
    }

    Future<void> _requestAppeal(String reason) async {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken(true);

      final response = await http.post(
        Uri.parse(
          'https://us-central1-carrygo-55444.cloudfunctions.net/requestAppealHttp',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tripRequestId': requestId,
          'reason': reason,
          'chatId': chatId,
        }),
      );

      if (response.statusCode != 200) {
        String message = 'Something went wrong';

        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['error'] != null) {
            message = body['error'].toString();
          }
        } catch (_) {
          message = response.body.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade600,
          ),
        );

        return; // ⛔ stop further execution
      }
    }

    void _openAppealDialog(BuildContext context) {
      final controller = TextEditingController();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Request Appeal'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Explain why this decision should be reviewed',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;

                await _requestAppeal(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Submit Appeal'),
            ),
          ],
        ),
      );
    }

    Future<void> update(String newStatus) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final token = await user.getIdToken(true);

      final response = await http.post(
        Uri.parse(
          'https://us-central1-carrygo-55444.cloudfunctions.net/updateTransactionStatusHttp',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'tripRequestId': requestId, 'newStatus': newStatus}),
      );

      if (response.statusCode != 200) {
        throw Exception('API failed: ${response.body}');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Status updated')));
    }

    if (isTraveller) {
      switch (status) {
        case RequestStatus.accepted:
          return _actionButton(
            label: 'Mark Purchased',
            onTap: () => update(RequestStatus.purchased),
          );

        case RequestStatus.purchased:
          return _actionButton(
            label: 'Start Journey',
            onTap: () => update(RequestStatus.inTransit),
          );

        case RequestStatus.inTransit:
          return _actionButton(
            label: 'Mark Delivered',
            onTap: () => update(RequestStatus.delivered),
          );
        case RequestStatus.disputed:
          return infoChip(
            text: 'Dispute Raised • Under Review',
            icon: Icons.report_problem,
            color: Colors.red,
          );
      }
    } else {
      //Buyer
      switch (status) {
        case RequestStatus.purchased:
          return infoChip(
            text: 'Item Purchased',
            icon: Icons.shopping_bag,
            color: Colors.orange,
          );

        case RequestStatus.inTransit:
          return infoChip(
            text: 'In Transit',
            icon: Icons.local_shipping,
            color: Colors.purple,
          );
        //           infoChip(
        //   text: 'Delivered',
        //   icon: Icons.check_circle,
        //   color: Colors.green,
        // )
        case RequestStatus.confirmedDelivery:
          return Row(
            children: [
              infoChip(
                text: 'Delivery Confirmed',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _outlineActionButton(
                label: 'Raise Dispute',
                onTap: () => raiseDispute(context),
              ),
            ],
          );
        case RequestStatus.disputed:
          return Row(
            children: [
              infoChip(
                text: 'Dispute in Review',
                icon: Icons.report_problem,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _outlineActionButton(
                label: 'Upload Evidence',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DisputeEvidenceScreen(tripRequestId: requestId),
                    ),
                  );
                },
              ),
            ],
          );

        case RequestStatus.completed:
          return Row(
            children: [
              infoChip(
                text: 'Dispute Resolved',
                icon: Icons.verified,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _outlineActionButton(
                label: 'Request Appeal',
                onTap: () => _openAppealDialog(context),
              ),
            ],
          );

        case RequestStatus.delivered:
          return Row(
            children: [
              _actionButton(
                label: 'Confirm Delivery',
                //onTap: () => update(RequestStatus.completed),
                onTap: () => update(RequestStatus.confirmedDelivery),
              ),
              const SizedBox(width: 8),
              _outlineActionButton(
                label: 'Raise Dispute',
                onTap: () => raiseDispute(context),
              ),
            ],
          );
      }
      // if (status == RequestStatus.delivered) {
      //   return _actionButton(
      //     label: 'Confirm Delivery',
      //     onTap: () => update(RequestStatus.completed),
      //   );
      // }
    }

    return const SizedBox.shrink();
  }

  Future<void> raiseDispute(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken(true);

    final response = await http.post(
      Uri.parse(
        'https://us-central1-carrygo-55444.cloudfunctions.net/raiseDisputeHttp',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tripRequestId': requestId,
        'reason': 'Item issue', // can make dynamic later
        'description': 'Buyer raised dispute from chat',
      }),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.body)));
      //throw Exception(response.body);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dispute raised successfully')),
    );
  }

  Widget _outlineActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
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

class _ChatActionBar extends ConsumerWidget {
  final String requestId;
  final String status;
  final bool isTraveller;
  final String chatId;

  const _ChatActionBar({
    required this.requestId,
    required this.status,
    required this.isTraveller,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: _ChatStatusAction(
        requestId: requestId,
        status: status,
        isTraveller: isTraveller,
        chatId: chatId,
      ),
    );
  }
}

class _ChatLockedBanner extends StatelessWidget {
  const _ChatLockedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            'Chat locked after dispute resolution',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
