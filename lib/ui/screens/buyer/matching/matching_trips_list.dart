import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'matching_trips_provider.dart';

class MatchingTripsList extends ConsumerWidget {
  const MatchingTripsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = {
      'from': 'Surat',
      'to': 'Mumbai',
      'date': DateTime.now(),
      'weight': 2,
    };

    final trips = ref.watch(matchingTripsProvider(filter));

    return trips.when(
      data: (docs) => ListView.builder(
        itemCount: docs.length,
        itemBuilder: (_, i) {
          final d = docs[i].data() as Map<String, dynamic>;
          return Card(
            child: ListTile(
              title: Text('${d['fromCity']} → ${d['toCity']}'),
              subtitle: Text('Weight: ${d['weightAvailable']} kg'),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
