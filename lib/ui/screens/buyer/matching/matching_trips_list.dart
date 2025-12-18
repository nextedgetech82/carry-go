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
    final mode = ref.watch(matchModeProvider);

    if (filter == null) {
      return const _EmptySearchState();
    }

    final tripsAsync = ref.watch(matchingTripsProvider(filter));

    return Column(
      children: [
        /// 🔹 SMART / EXPLORE TOGGLE
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Smart Match'),
                  selected: mode == MatchMode.smart,
                  onSelected: (_) {
                    ref.read(matchModeProvider.notifier).state =
                        MatchMode.smart;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Explore More'),
                  selected: mode == MatchMode.explore,
                  onSelected: (_) {
                    ref.read(matchModeProvider.notifier).state =
                        MatchMode.explore;
                  },
                ),
              ),
            ],
          ),
        ),

        /// 🔹 LIST
        Expanded(
          child: tripsAsync.when(
            loading: () => const _LoadingState(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (docs) {
              if (docs.isEmpty) {
                return const _NoMatchState();
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  return _TripCard(doc: docs[i], filter: filter, mode: mode);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TripCard extends ConsumerWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final TripMatchFilter filter;
  final MatchMode mode;

  const _TripCard({
    required this.doc,
    required this.filter,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = doc.data();
    final travellerId = data['travellerId'] as String;

    final verificationAsync = ref.watch(
      travellerVerificationProvider(travellerId),
    );

    final departure = (data['departureDate'] as Timestamp).toDate();
    final arrival = (data['arrivalDate'] as Timestamp).toDate();
    final availableWeight = (data['availableWeightKg'] ?? 0).toDouble();

    final isPerfectMatch =
        availableWeight >= filter.minWeight &&
        !arrival.isBefore(filter.deadline);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripDetailScreen(tripDoc: doc)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ROUTE + PRICE
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

              const SizedBox(height: 8),

              /// MATCH BADGE
              //_MatchBadge(perfect: isPerfectMatch, mode: mode),
              /// MATCH + VERIFICATION BADGES
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MatchBadge(perfect: isPerfectMatch, mode: mode),
                  verificationAsync.when(
                    loading: () => const _VerificationSkeleton(),
                    error: (_, __) => const _VerificationBadge(verified: false),
                    data: (verified) => _VerificationBadge(verified: verified),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// DATES
              Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_fmt(departure)} → ${_fmt(arrival)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// INFO
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

class _MatchBadge extends StatelessWidget {
  final bool perfect;
  final MatchMode mode;

  const _MatchBadge({required this.perfect, required this.mode});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (perfect) {
      color = Colors.green;
      text = 'Perfect Match';
    } else if (mode == MatchMode.explore) {
      color = Colors.orange;
      text = 'Explore Match';
    } else {
      return const SizedBox.shrink();
    }

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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
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

class _VerificationBadge extends StatelessWidget {
  final bool verified;

  const _VerificationBadge({required this.verified});

  @override
  Widget build(BuildContext context) {
    final color = verified ? Colors.blue : Colors.grey;
    final icon = verified ? Icons.verified : Icons.info_outline;
    final text = verified ? 'Verified Traveller' : 'Not Verified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationSkeleton extends StatelessWidget {
  const _VerificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
