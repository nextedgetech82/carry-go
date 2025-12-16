import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchingTripsProvider =
    StreamProvider.family<List<QueryDocumentSnapshot>, Map<String, dynamic>>((
      ref,
      filter,
    ) {
      return FirebaseFirestore.instance
          .collection('trips')
          .where('fromCity', isEqualTo: filter['from'])
          .where('toCity', isEqualTo: filter['to'])
          .where('travelDate', isGreaterThanOrEqualTo: filter['date'])
          .where('weightAvailable', isGreaterThanOrEqualTo: filter['weight'])
          .snapshots()
          .map((s) => s.docs);
    });
