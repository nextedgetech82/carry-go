import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripMatchFilter {
  final String from;
  final String to;
  final DateTime deadline;
  final double minWeight;

  const TripMatchFilter({
    required this.from,
    required this.to,
    required this.deadline,
    required this.minWeight,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripMatchFilter &&
        other.from == from &&
        other.to == to &&
        other.deadline == deadline &&
        other.minWeight == minWeight;
  }

  @override
  int get hashCode =>
      from.hashCode ^ to.hashCode ^ deadline.hashCode ^ minWeight.hashCode;
}

final matchingTripsProvider =
    StreamProvider.family<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
      TripMatchFilter
    >((ref, filter) {
      return FirebaseFirestore.instance
          .collection('trips')
          .where('fromCity', isEqualTo: filter.from)
          .where('toCity', isEqualTo: filter.to)
          // ✅ ONE range filter only
          .where(
            'departureDate',
            isLessThanOrEqualTo: Timestamp.fromDate(filter.deadline),
          )
          .orderBy('departureDate') // REQUIRED
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.where((doc) {
              final data = doc.data();

              final availableWeight = (data['availableWeightKg'] ?? 0)
                  .toDouble();

              final arrivalDate = (data['arrivalDate'] as Timestamp).toDate();

              // ✅ Client-side checks
              return availableWeight >= filter.minWeight &&
                  !arrivalDate.isBefore(filter.deadline);
            }).toList();
          });
    });
