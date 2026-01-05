import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/providers/my_trips_provider.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:carrygo/ui/screens/buyer/request_timeline/request_status.dart';
import 'package:carrygo/ui/screens/chat/chat_screen.dart';
import 'package:carrygo/ui/screens/chat/traveler_chatstream_provider.dart';
import 'package:carrygo/ui/screens/dashboard/accept_trip_provider.dart';
import 'package:carrygo/ui/screens/dashboard/profile.dart';
import 'package:carrygo/ui/screens/dashboard/traveller_drawer.dart';
import 'package:carrygo/ui/screens/dashboard/wallet/wallet_provider.dart';
import 'package:carrygo/ui/screens/dashboard/wallet/wallet_screen.dart';
import 'package:carrygo/ui/screens/sender/incoming_requests_provider.dart';
import 'package:carrygo/ui/screens/trip/add_trip_screen.dart';
import 'package:carrygo/ui/screens/trip/trip_details_screen.dart';
import 'package:carrygo/widgets/role_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

bool isProfileComplete(Map<String, dynamic> profile) {
  return (profile['firstName'] != null &&
      profile['firstName'].toString().isNotEmpty &&
      profile['lastName'] != null &&
      profile['lastName'].toString().isNotEmpty);
}

class TravellerDashboard extends ConsumerWidget {
  const TravellerDashboard({super.key});

  //String profileFullName = "";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final tripsAsync = ref.watch(myTripsProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),

      data: (profile) {
        final fullName =
            '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
        final role = profile['role'] ?? 'traveller';

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const SizedBox(width: 16),
                const Text('Travel Fetcher'),
                const SizedBox(width: 10),
                RoleBadge(role: role),
              ],
            ),
            centerTitle: true,
          ),

          /// ✅ NOW profile IS AVAILABLE
          drawer: TravellerDrawer(profile: profile),

          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                    Tab(icon: Icon(Icons.chat), text: 'Chats'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DashboardBody(
                        theme: theme,
                        fullName: fullName,
                        tripsAsync: tripsAsync,
                        profile: profile,
                      ),
                      AcceptedRequestsTab(theme: theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings coming soon')),
    );
  }
}

// class TravellerDashboardTab extends ConsumerWidget {
//   final ThemeData theme;
//   final String fullName;
//   final AsyncValue tripsAsync;

//   const TravellerDashboardTab({
//     required this.theme,
//     required this.fullName,
//     required this.tripsAsync,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _Header(theme: theme, fullName: fullName),

//           const SizedBox(height: 24),

//           Row(
//             children: const [
//               _StatCard(
//                 title: 'Total Earnings',
//                 value: '₹0',
//                 icon: Icons.currency_rupee,
//               ),
//               SizedBox(width: 16),
//               _StatCard(title: 'Trips', value: '0', icon: Icons.flight_takeoff),
//             ],
//           ),

//           const SizedBox(height: 32),

//           Text(
//             'My Trips',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),

//           const SizedBox(height: 12),

//           tripsAsync.when(
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (e, _) => Text(e.toString()),
//             data: (trips) {
//               if (trips.isEmpty) return _EmptyTrips(theme: theme);

//               return Column(
//                 children: trips.map<Widget>((trip) {
//                   return _TripRow(
//                     fromCity: trip['fromCity'],
//                     toCity: trip['toCity'],
//                     departureDate: trip['departureDate'],
//                     arrivalDate: trip['arrivalDate'],
//                     pricePerKg: trip['pricePerKg'],
//                     availableWeight: trip['availableWeightKg'],
//                     status: trip['status'],
//                   );
//                 }).toList(),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

class IncomingRequestsTab extends ConsumerWidget {
  final ThemeData theme;
  const IncomingRequestsTab({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingTripRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load requests')),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No incoming requests'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: requests.map((doc) {
            final r = doc.data();

            return Card(
              child: ListTile(
                title: Text('${r['fromCity']} → ${r['toCity']}'),
                subtitle: Text(
                  '${r['itemName']} • ${r['requestedWeightKg']} kg',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class AcceptedRequestsTab extends ConsumerWidget {
  final ThemeData theme;
  const AcceptedRequestsTab({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acceptedAsync = ref.watch(acceptedTripRequestsProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return acceptedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const Center(child: Text('Failed to load accepted requests')),
      data: (snapshot) {
        final docs = snapshot.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No accepted requests yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final r = docs[index].data();
            final requestId = docs[index].id;

            return _AcceptedRequestCard(
              theme: theme,
              requestId: requestId,
              data: r,
              uid: uid,
              otherUserId: r['buyerId'],
            );
          },
        );
      },
    );
  }
}

class _AcceptedRequestCard extends ConsumerWidget {
  final ThemeData theme;
  final String requestId;
  final Map<String, dynamic> data;
  final String uid;
  final String otherUserId; // buyerId

  const _AcceptedRequestCard({
    required this.theme,
    required this.requestId,
    required this.data,
    required this.uid,
    required this.otherUserId,
  });

  Widget _statusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case RequestStatus.accepted:
        color = Colors.blue;
        text = 'Accepted';
        break;

      case RequestStatus.purchased:
        color = Colors.orange;
        text = 'Item Purchased';
        break;

      case RequestStatus.inTransit:
        color = Colors.purple;
        text = 'In Transit';
        break;

      case RequestStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;

      case RequestStatus.confirmedDelivery:
        color = Colors.teal;
        text = 'Delivery Confirmed';
        break;

      case RequestStatus.completed:
        color = Colors.green.shade700;
        text = 'Completed';
        break;

      case RequestStatus.disputed:
        color = Colors.red;
        text = 'Disputed';
        break;

      case RequestStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;

      default:
        color = Colors.grey;
        text = status.toUpperCase();
    }

    return Chip(
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatId = (data['requestId'] as String?) ?? requestId;
    final chatAsync = ref.watch(chatByRequestProvider(chatId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .snapshots(),
        builder: (context, userSnap) {
          final user = userSnap.data?.data();
          final buyerName =
              '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim();

          final initials = buyerName.isNotEmpty
              ? buyerName
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
              : 'B';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ───── Buyer Header ─────
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    child: Text(
                      initials.toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buyerName.isEmpty ? 'Buyer' : buyerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Accepted Request',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// ───── Route Pill ─────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${data['fromCity']} → ${data['toCity']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// ───── Item Name ─────
              if (data['itemName'] != null &&
                  data['itemName'].toString().isNotEmpty)
                Text(data['itemName'], style: theme.textTheme.bodyMedium),

              const SizedBox(height: 10),

              /// ───── Info Chips ─────
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.scale,
                    text: '${data['requestedWeightKg']} kg',
                  ),
                  _InfoChip(
                    icon: Icons.currency_rupee,
                    text: '₹${data['totalPrice']}',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// ───── Chat Button ─────
              chatAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (chatSnap) {
                  final chat = chatSnap.data();
                  final unread = chat != null && chat['lastSenderId'] != uid;
                  //final chatReqId = chat?['requestId'];
                  final chatReqId = chat?['trip_request_id'];

                  return Column(
                    children: [
                      /// 🔹 STATUS CHIP
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _statusChip(data['status']),
                      ),

                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: unread
                                ? Colors.red
                                : theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatId: chatId,
                                  otherUserName: buyerName.isEmpty
                                      ? 'Buyer'
                                      : buyerName,
                                  requestId: chatReqId,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                unread ? 'New Message' : 'Open Chat',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompleteProfileBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Complete your profile to start posting trips.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final ThemeData theme;
  final String fullName;
  final AsyncValue tripsAsync;
  final Map<String, dynamic> profile;

  const _DashboardBody({
    required this.theme,
    required this.fullName,
    required this.tripsAsync,
    required this.profile,
  });

  // Future<void> acceptTripRequest2(
  //   BuildContext context,
  //   String tripRequestId,
  //   Map<String, dynamic> r,
  // ) async {
  //   final db = FirebaseFirestore.instance;

  //   await db.runTransaction((tx) async {
  //     bool tripCompleted = false;

  //     final tripRef = db.collection('trips').doc(r['tripId']);
  //     final trRef = db.collection('trip_requests').doc(tripRequestId);
  //     final reqRef = db.collection('requests').doc(r['requestId']);

  //     final tripSnap = await tx.get(tripRef);
  //     final available = (tripSnap['availableWeightKg'] as num).toDouble();
  //     //final requested = (r['requestedWeight'] as num).toDouble();
  //     final requested = (r['requestedWeightKg'] as num).toDouble();

  //     if (available < requested) {
  //       throw Exception('Not enough available weight');
  //     }

  //     final remaining = available - requested;
  //     tripCompleted = remaining <= 0;

  //     /// 🔹 UPDATE TRIP
  //     tx.update(tripRef, {
  //       'availableWeightKg': remaining,
  //       'status': tripCompleted ? 'completed' : 'active',
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     });

  //     /// 🔹 Accept current trip_request
  //     tx.update(trRef, {
  //       'status': RequestStatus.accepted,
  //       'acceptedAt': FieldValue.serverTimestamp(),
  //     });

  //     // updateRequestStatus(
  //     //   requestId: r['requestId'],
  //     //   newStatus: RequestStatus.accepted,
  //     // );

  //     //tx.update(tripRef, {'availableWeightKg': available - requested});

  //     /// 🔹 ACCEPT BUYER REQUEST
  //     tx.update(reqRef, {
  //       'status': RequestStatus.accepted,
  //       'acceptedAt': FieldValue.serverTimestamp(),
  //     });

  //     /// 🔹 CREATE CHAT
  //     final chatRef = db.collection('chats').doc(r['requestId']);

  //     tx.set(chatRef, {
  //       'requestId': r['requestId'],
  //       'buyerId': r['buyerId'],
  //       'travellerId': r['travellerId'],
  //       'lastMessage': 'Chat started',
  //       'lastSenderId': 'system',
  //       'trip_request_id': tripRequestId,
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     });

  //     /// 🔹 2️⃣ AUTO-REJECT REMAINING REQUESTS
  //     /// Auto Reject Pending Requests
  //     // if (tripCompleted) {
  //     //   await _rejectPendingRequests(r['tripId'], tripRequestId);
  //     // }

  //     // ✅ Update buyer request
  //     //tx.update(reqRef, {'status': 'accepted'});
  //   });

  //   // ScaffoldMessenger.of(
  //   //   context,
  //   // ).showSnackBar(const SnackBar(content: Text('Request accepted')));
  // }

  Future<void> acceptTripRequest(
    String tripRequestId,
    Map<String, dynamic> r,
  ) async {
    final db = FirebaseFirestore.instance;
    bool tripCompleted = false;

    await db.runTransaction((tx) async {
      final tripRef = db.collection('trips').doc(r['tripId']);
      final trRef = db.collection('trip_requests').doc(tripRequestId);
      final reqRef = db.collection('requests').doc(r['requestId']);
      final chatRef = db.collection('chats').doc(r['requestId']);

      // 🔥 NEW: transaction document
      //final transactionRef = db.collection('transactions').doc(tripRequestId);

      final tripSnap = await tx.get(tripRef);
      final available = (tripSnap['availableWeightKg'] as num).toDouble();
      final requested = (r['requestedWeightKg'] as num).toDouble();

      if (available < requested) {
        throw Exception('Not enough available weight');
      }

      final remaining = available - requested;
      tripCompleted = remaining <= 0;

      /// ───── UPDATE TRIP ─────
      tx.update(tripRef, {
        'availableWeightKg': remaining,
        'status': tripCompleted ? 'completed' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      /// ───── ACCEPT TRIP REQUEST ─────
      tx.update(trRef, {
        'status': RequestStatus.accepted,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      /// ───── ACCEPT BUYER REQUEST ─────
      // tx.update(reqRef, {
      //   'status': RequestStatus.accepted,
      //   //'travellerId': r['travellerId'],
      //   'travellerId': FirebaseAuth.instance.currentUser!.uid,
      //   'acceptedAt': FieldValue.serverTimestamp(),
      // });
      // update request
      tx.update(reqRef, {
        'status': RequestStatus.accepted,
        'travellerId': FirebaseAuth.instance.currentUser!.uid,
        'tripId': r['tripId'],
        'tripRequestId': tripRequestId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // /// ───── CREATE CHAT ─────
      tx.set(chatRef, {
        'requestId': r['requestId'],
        'buyerId': r['buyerId'],
        'travellerId': r['travellerId'],
        'lastMessage': 'Chat started',
        'lastSenderId': 'system',
        'trip_request_id': tripRequestId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(tripRequestId)
        .set({
          'requestId': r['requestId'],
          'tripRequestId': tripRequestId,
          'buyerId': r['buyerId'],
          'travellerId': r['travellerId'],

          'amount': r['totalPrice'],
          'platformFee': (r['totalPrice'] as num) * 0.10,
          'travellerEarning': (r['totalPrice'] as num) * 0.90,

          'status': 'ACCEPTED',

          'timestamps': {'acceptedAt': FieldValue.serverTimestamp()},
        });

    /// ───── AUTO REJECT OTHERS ─────
    if (tripCompleted) {
      await _rejectPendingRequests(r['tripId'], tripRequestId);
    }
  }

  Future<void> rejectTripRequest(String tripRequestId) async {
    await FirebaseFirestore.instance
        .collection('trip_requests')
        .doc(tripRequestId)
        .update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _rejectPendingRequests(
    String tripId,
    String acceptedTripRequestId,
  ) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    final pendingRequests = await db
        .collection('trip_requests')
        .where('tripId', isEqualTo: tripId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in pendingRequests.docs) {
      if (doc.id == acceptedTripRequestId) continue;

      final data = doc.data();

      /// Reject trip_request
      batch.update(doc.reference, {
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      /// Reject buyer request
      if (data['requestId'] != null) {
        batch.update(db.collection('requests').doc(data['requestId']), {
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingTripRequestsProvider);
    final profileComplete = isProfileComplete(profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Greeting
          _Header(theme: theme, fullName: fullName),

          const SizedBox(height: 24),

          if (!profileComplete) ...[
            _CompleteProfileBanner(),
            const SizedBox(height: 24),
          ],

          /// 🔹 Stats
          Row(
            children: const [
              _WalletHeader(), // 👈 LIVE wallet
              SizedBox(width: 16),
              _StatCard(title: 'Trips', value: '0', icon: Icons.flight_takeoff),
            ],
          ),

          const SizedBox(height: 32),

          /// 🔹 CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: profileComplete
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTripScreen(),
                        ),
                      );
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete your profile first'),
                        ),
                      );
                    },
              icon: const Icon(Icons.add),
              label: Text(
                profileComplete
                    ? 'Post a New Trip'
                    : 'Complete Profile to Post Trip',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: profileComplete ? null : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          /// 🔹 Incoming Requests
          Text(
            'Incoming Requests',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          requestsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Failed to load requests',
              style: TextStyle(color: Colors.red),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No incoming requests',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }

              return Column(
                children: requests.map<Widget>((doc) {
                  final r = doc.data();
                  final tripRequestId = doc.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🚚 ROUTE
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${r['fromCity']} → ${r['toCity']}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// 📦 ITEM
                          if (r['itemName'] != null &&
                              r['itemName'].toString().isNotEmpty)
                            Text(
                              r['itemName'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),

                          const SizedBox(height: 12),

                          /// 🔢 CHIPS
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _InfoChip(
                                icon: Icons.scale,
                                text: '${r['requestedWeightKg']} kg',
                              ),
                              _InfoChip(
                                icon: Icons.currency_rupee,
                                text: '₹${r['totalPrice']}',
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// ✅ ACTIONS
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () =>
                                      rejectTripRequest(tripRequestId),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  label: const Text('Accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    try {
                                      await acceptTripRequest(tripRequestId, r);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Request accepted'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                                  // onPressed: () => acceptTripRequest(
                                  //   context,
                                  //   tripRequestId,
                                  //   r,
                                  // ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          /// 🔹 Trips Section (placeholder for next step)
          Text(
            'My Trips',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          tripsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),

            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                error.toString(),
                style: TextStyle(color: Colors.red),
              ),
            ),

            data: (trips) {
              if (trips.isEmpty) {
                return _EmptyTrips(theme: theme);
              }

              return Column(
                children: trips.map<Widget>((trip) {
                  final tripId = trip['id']; // IMPORTANT: see note below

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailsScreen(tripId: tripId),
                          ),
                        );
                      },
                      child: _TripRow(
                        fromCity: trip['fromCity'],
                        toCity: trip['toCity'],
                        departureDate: trip['departureDate'],
                        arrivalDate: trip['arrivalDate'],
                        pricePerKg: trip['pricePerKg'],
                        availableWeight: trip['availableWeightKg'],
                        status: trip['status'],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// HEADER
/// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ThemeData theme;
  final String fullName;

  const _Header({required this.theme, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back 👋',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Verified',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────
/// STAT CARD
/// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// EMPTY STATE
/// ─────────────────────────────────────────────

class _EmptyTrips extends StatelessWidget {
  final ThemeData theme;

  const _EmptyTrips({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Icon(Icons.flight, size: 48),
          SizedBox(height: 8),
          Text('No trips yet', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text(
            'Post your first trip and start earning',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final dynamic departureDate; // Firestore Timestamp
  final dynamic arrivalDate; // Firestore Timestamp
  final num pricePerKg;
  final num availableWeight; // NEW
  final String status; // active / completed / cancelled

  const _TripRow({
    required this.fromCity,
    required this.toCity,
    required this.departureDate,
    required this.arrivalDate,
    required this.pricePerKg,
    required this.availableWeight,
    required this.status,
  });

  String _fmtKg(num value) {
    // show max 2 decimals, remove trailing zeros
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final dt = (date as Timestamp).toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color _statusColor(BuildContext context) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _statusText() {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✈️ Icon
          Icon(Icons.flight_takeoff, color: theme.colorScheme.primary),

          const SizedBox(width: 12),

          /// 📍 Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Route + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$fromCity → $toCity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      text: _statusText(),
                      color: _statusColor(context),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// Dates
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDate(departureDate)} → ${_formatDate(arrivalDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// Weight + Price
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Text(
                      '${_fmtKg(availableWeight)} kg available',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '₹${_fmtKg(pricePerKg)} / kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WalletHeader extends ConsumerWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final theme = Theme.of(context);

    return Expanded(
      child: walletAsync.when(
        loading: () => _walletCard(theme, '₹0', isLoading: true),
        error: (_, __) => _walletCard(theme, '₹0'),
        data: (snap) {
          final balance = (snap.data()?['balance'] ?? 0).toDouble();
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WalletScreen()),
              );
            },
            child: _walletCard(theme, '₹${balance.toStringAsFixed(0)}'),
          );
        },
      ),
    );
  }

  Widget _walletCard(ThemeData theme, String amount, {bool isLoading = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_wallet),
          const SizedBox(height: 12),
          Text(
            isLoading ? 'Loading...' : amount,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Wallet Balance'),
        ],
      ),
    );
  }
}
