import 'package:carrygo/ui/screens/buyer/my_requests/contact_traveller_cta.dart';
import 'package:carrygo/ui/screens/buyer/request_timeline/request_timeline.dart';
import 'package:carrygo/ui/screens/chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BuyerRequestDetailScreen extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> request;

  const BuyerRequestDetailScreen({
    super.key,
    required this.requestId,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tripRequestStream = FirebaseFirestore.instance
        .collection('trip_requests')
        .where('buyerId', isEqualTo: request['buyerId'])
        //.orderBy('acceptedAt', descending: true) // 🔥 IMPORTANT
        .where('status', whereIn: ['accepted', 'pending'])
        .limit(1)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ───────────────── ROUTE CARD ─────────────────
            _RouteCard(
              fromCity: request['fromCity'],
              toCity: request['toCity'],
            ),

            const SizedBox(height: 24),

            /// ───────────────── STATUS + PRICE ─────────────────
            StreamBuilder<QuerySnapshot>(
              stream: tripRequestStream,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _WaitingForTraveller();
                }

                final trDoc = snap.data!.docs.first;
                final tr = trDoc.data() as Map<String, dynamic>;
                final tripStatus = tr['status'] as String;
                final travellerId = tr['travellerId'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🕒 TIMELINE (BASED ON TRIP STATUS)
                    Text(
                      'Request Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: RequestTimeline(status: tripStatus),
                    ),

                    const SizedBox(height: 24),

                    /// 💰 PRICE DETAILS
                    Text(
                      'Price Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _StatTile(
                          icon: Icons.scale,
                          label: 'Weight',
                          value: '${tr['requestedWeightKg']} kg',
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          icon: Icons.currency_rupee,
                          label: 'Rate',
                          value: '₹${tr['pricePerKg']} / kg',
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          icon: Icons.payments,
                          label: 'Total',
                          value: '₹${tr['totalPrice']}',
                          highlight: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// ───────────────── CTA SECTION ─────────────────
                    if (tripStatus == 'accepted')
                      _AcceptedCTA(
                        //context: context,
                        travellerId: travellerId,
                        requestId: requestId,
                        request: request,
                      ),

                    if (tripStatus == 'rejected') _RejectedInfo(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ───────────────────────── COMPONENTS ─────────────────────────

class _RouteCard extends StatelessWidget {
  final String fromCity;
  final String toCity;
  const _RouteCard({required this.fromCity, required this.toCity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$fromCity → $toCity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingForTraveller extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.hourglass_empty, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          'Waiting for traveller response...',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class _AcceptedCTA extends StatelessWidget {
  //final BuildContext context;
  final String travellerId;
  final String requestId;
  final Map<String, dynamic> request;

  const _AcceptedCTA({
    //required this.context,
    required this.travellerId,
    required this.requestId,
    required this.request,
  });

  Future<void> ensureChatExists({
    required String chatId,
    required String buyerId,
    required String travellerId,
    required String requestId,
  }) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final snap = await chatRef.get();
    if (snap.exists) return;

    await chatRef.set({
      'buyerId': buyerId,
      'travellerId': travellerId,
      'requestId': requestId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastSenderId': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(travellerId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox();
        }

        final traveller = snap.data!.data()!;
        final name = traveller['firstName'] ?? 'Traveller';
        final phone = traveller['phone'] as String?;

        return Column(
          children: [
            /// 💬 CHAT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Traveller'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await ensureChatExists(
                    chatId: requestId,
                    buyerId: request['buyerId'],
                    travellerId: travellerId,
                    requestId: requestId,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: requestId,
                        otherUserName: traveller['firstName'] ?? 'Traveller',
                      ),
                    ),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(chatId: requestId, otherUserName: name),
                    ),
                  );
                },
              ),
            ),

            /// 📞 CALL / WHATSAPP
            if (phone != null && phone.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ContactTravellerCTA(
                travellerName: name,
                phone: _normalizePhone(phone),
              ),
            ],
          ],
        );
      },
    );
  }

  static String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');
}

class _RejectedInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This request was rejected because the trip was completed.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
