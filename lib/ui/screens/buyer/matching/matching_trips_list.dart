import 'package:carrygo/ui/screens/buyer/matching/buyer_trip_filter_provider.dart';
import 'package:carrygo/ui/screens/buyer/matching/matching_trips_provider.dart';
import 'package:carrygo/ui/screens/buyer/trip_detail/trip_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchingTripsList extends ConsumerWidget {
  const MatchingTripsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(buyerTripFilterProvider);

    if (filter == null) {
      return const _EmptySearchState();
    }

    final tripsAsync = ref.watch(matchingTripsProvider(filter));

    return tripsAsync.when(
      loading: () => const _LoadingState(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (docs) {
        if (docs.isEmpty) {
          return const _NoMatchState();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            //return _TripCard(data: docs[i].data());
            return _TripCard(doc: docs[i]);
          },
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  //final Map<String, dynamic> data;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _TripCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final departure = (data['departureDate'] as Timestamp).toDate();
    final arrival = (data['arrivalDate'] as Timestamp).toDate();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailScreen(
                tripDoc: doc, // ✅ full Firestore doc
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${data['fromCity']} → ${data['toCity']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _PriceTag(price: data['pricePerKg']),
                ],
              ),

              const SizedBox(height: 10),

              // Dates
              Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_fmt(departure)}  →  ${_fmt(arrival)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Info Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.scale,
                    text: '${data['availableWeightKg']} kg available',
                  ),
                  _InfoChip(
                    icon: Icons.notes,
                    text: data['notes'] ?? 'No notes',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // CTA
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View Details →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _PriceTag extends StatelessWidget {
  final num price;

  const _PriceTag({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '₹$price / kg',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade800,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Post a request to see matching trips',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.airplanemode_inactive, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No matching trips found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}
