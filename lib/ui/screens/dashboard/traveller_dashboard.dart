import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/providers/my_trips_provider.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:carrygo/ui/screens/sender/incoming_requests_provider.dart';
import 'package:carrygo/ui/screens/trip/add_trip_screen.dart';
import 'package:carrygo/ui/screens/trip/trip_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravellerDashboard extends ConsumerWidget {
  const TravellerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final tripsAsync = ref.watch(myTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Fetcher'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              // 🔥 Reset cached app state
              ref.invalidate(startupProvider);
              ref.invalidate(userProfileProvider);
              ref.invalidate(myTripsProvider);

              // 🔁 Restart app flow
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) {
          final fullName =
              '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}';

          return _DashboardBody(
            theme: theme,
            fullName: fullName.trim(),
            tripsAsync: tripsAsync,
          );
        },
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final ThemeData theme;
  final String fullName;
  final AsyncValue tripsAsync;

  const _DashboardBody({
    required this.theme,
    required this.fullName,
    required this.tripsAsync,
  });

  Future<void> acceptTripRequest(
    BuildContext context,
    String tripRequestId,
    Map<String, dynamic> r,
  ) async {
    final db = FirebaseFirestore.instance;

    await db.runTransaction((tx) async {
      bool tripCompleted = false;

      final tripRef = db.collection('trips').doc(r['tripId']);
      final trRef = db.collection('trip_requests').doc(tripRequestId);
      final reqRef = db.collection('requests').doc(r['requestId']);

      final tripSnap = await tx.get(tripRef);
      final available = (tripSnap['availableWeightKg'] as num).toDouble();
      //final requested = (r['requestedWeight'] as num).toDouble();
      final requested = (r['requestedWeightKg'] as num).toDouble();

      if (available < requested) {
        throw Exception('Not enough available weight');
      }

      final remaining = available - requested;
      tripCompleted = remaining <= 0;

      /// 🔹 UPDATE TRIP
      tx.update(tripRef, {
        'availableWeightKg': remaining,
        'status': tripCompleted ? 'completed' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      /// 🔹 Accept current trip_request
      tx.update(trRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      //tx.update(tripRef, {'availableWeightKg': available - requested});

      /// 🔹 ACCEPT BUYER REQUEST
      tx.update(reqRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      /// 🔹 2️⃣ AUTO-REJECT REMAINING REQUESTS
      /// Auto Reject Pending Requests
      if (tripCompleted) {
        await _rejectPendingRequests(r['tripId'], tripRequestId);
      }

      // ✅ Update buyer request
      //tx.update(reqRef, {'status': 'accepted'});
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request accepted')));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Greeting
          _Header(theme: theme, fullName: fullName),

          const SizedBox(height: 24),

          /// 🔹 Stats
          Row(
            children: const [
              _StatCard(
                title: 'Total Earnings',
                value: '₹0',
                icon: Icons.currency_rupee,
              ),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTripScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Post a New Trip',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
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
                    child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('requests')
                          .doc(r['requestId'])
                          .get(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Loading request...'),
                          );
                        }

                        final req = snap.data!.data();
                        if (req == null) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Request not found'),
                          );
                        }

                        return Padding(
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
                                      '${req['fromCity']} → ${req['toCity']}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// 📦 ITEM (optional but nice)
                              if (req['itemName'] != null)
                                Text(
                                  req['itemName'],
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
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => acceptTripRequest(
                                        context,
                                        tripRequestId,
                                        r,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
          child: Text(
            'Welcome back, $fullName 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
