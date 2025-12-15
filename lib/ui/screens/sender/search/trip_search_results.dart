import 'package:carrygo/ui/screens/sender/search/trip_search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripSearchResults extends ConsumerWidget {
  const TripSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripSearchProvider);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(child: Text('No trips found'));
        }

        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return _SenderTripCard(trip: trip);
          },
        );
      },
    );
  }
}

class _SenderTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const _SenderTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('${trip['fromCity']} → ${trip['toCity']}'),
        subtitle: Text(
          '${trip['availableWeightKg']} kg • ₹${trip['pricePerKg']}/kg',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => SenderTripDetailsScreen(trip: trip),
          //   ),
          // );
        },
      ),
    );
  }
}
