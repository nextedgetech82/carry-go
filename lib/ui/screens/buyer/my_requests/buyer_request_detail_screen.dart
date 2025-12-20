import 'package:carrygo/ui/screens/buyer/my_requests/contact_traveller_cta.dart';
import 'package:carrygo/ui/screens/buyer/request_timeline/request_timeline.dart';
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
    final status = request['status'];

    final tripRequestStream = FirebaseFirestore.instance
        .collection('trip_requests')
        .where('requestId', isEqualTo: requestId)
        .limit(1)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🚚 ROUTE CARD
            Container(
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
                      '${request['fromCity']} → ${request['toCity']}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🕒 STATUS TIMELINE
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
              child: RequestTimeline(status: status),
            ),

            const SizedBox(height: 24),

            /// 💰 PRICE + WEIGHT
            Text(
              'Price Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: tripRequestStream,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _InfoHint(
                    icon: Icons.hourglass_empty,
                    text: 'Waiting for traveller response...',
                  );
                }

                final trDoc = snap.data!.docs.first;
                final tr = trDoc.data() as Map<String, dynamic>;
                final travellerId = tr['travellerId'];

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users') // or profiles
                      .doc(travellerId)
                      .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData || !userSnap.data!.exists) {
                      return _InfoHint(
                        icon: Icons.person,
                        text: 'Loading traveller details...',
                      );
                    }

                    final traveller = userSnap.data!.data()!;
                    final travellerName =
                        '${traveller['firstName'] ?? 'Traveller'}';
                    final phone = traveller['phone'] as String?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        /// 📞 CONTACT CTA
                        if (status == 'accepted' &&
                            phone != null &&
                            phone.isNotEmpty)
                          ContactTravellerCTA(
                            travellerName: travellerName,
                            phone: _normalizePhone(phone),
                          ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // ///  Accept INFO
            // if (status == 'accepted') ...[
            //   const SizedBox(height: 24),
            //   ContactTravellerCTA(
            //     travellerName: 'Traveller',
            //     phone: '91XXXXXXXXXX',
            //   ),
            // ],

            /// ❌ REJECTED INFO
            if (status == 'rejected')
              Container(
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
              ),
          ],
        ),
      ),
    );
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
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

class _InfoHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
