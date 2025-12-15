import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/providers/my_trips_provider.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
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

class _DashboardBody extends StatelessWidget {
  final ThemeData theme;
  final String fullName;
  final AsyncValue tripsAsync;

  const _DashboardBody({
    required this.theme,
    required this.fullName,
    required this.tripsAsync,
  });

  @override
  Widget build(BuildContext context) {
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
  final int pricePerKg;
  final int availableWeight; // NEW
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
                      '$availableWeight kg available',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '₹$pricePerKg / kg',
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
