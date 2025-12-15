import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// final tripTimelineProvider =
//     StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
//       return FirebaseFirestore.instance
//           .collection('trips')
//           .doc(tripId)
//           .collection('timeline')
//           .orderBy('createdAt', descending: true)
//           .snapshots()
//           .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
//     });

final tripTimelineProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) {
      return FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .collection('timeline')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    });
