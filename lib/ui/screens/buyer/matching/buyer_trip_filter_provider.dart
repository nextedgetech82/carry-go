import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'matching_trips_provider.dart';
import 'buyer_latest_request_provider.dart';

final buyerTripFilterProvider = Provider<TripMatchFilter?>((ref) {
  final latestRequestAsync = ref.watch(buyerLatestRequestProvider);

  return latestRequestAsync.maybeWhen(
    data: (doc) {
      if (doc == null) return null;

      final data = doc.data();

      return TripMatchFilter(
        from: data['fromCity'],
        to: data['toCity'],
        deadline: (data['deadline'] as Timestamp).toDate(),
        minWeight: (data['weight'] ?? 0).toDouble(),
      );
    },
    orElse: () => null,
  );
});
