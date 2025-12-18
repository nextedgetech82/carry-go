import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
      final mode = ref.watch(matchModeProvider);

      /// ✅ IMPORTANT: Typed query
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('trips')
          .where('fromCity', isEqualTo: filter.from)
          .where('toCity', isEqualTo: filter.to)
          .orderBy('departureDate');

      /// 🔹 Smart Match → apply deadline filter
      if (mode == MatchMode.smart) {
        query = query.where(
          'departureDate',
          isLessThanOrEqualTo: Timestamp.fromDate(filter.deadline),
        );
      }

      return query.snapshots().map((
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        return snapshot.docs.where((doc) {
          final data = doc.data();

          final availableWeight = (data['availableWeightKg'] ?? 0).toDouble();

          final arrivalDate = (data['arrivalDate'] as Timestamp).toDate();

          if (mode == MatchMode.smart) {
            return availableWeight >= filter.minWeight &&
                !arrivalDate.isBefore(filter.deadline);
          } else {
            /// 🔥 Explore mode → relaxed
            return availableWeight > 0;
          }
        }).toList();
      });
    });

enum MatchMode { smart, explore }

final matchModeProvider = StateProvider<MatchMode>((ref) => MatchMode.smart);

final travellerVerificationProvider = StreamProvider.family<bool, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return false;
        return doc.data()?['emailVerified'] == true;
      });
});
