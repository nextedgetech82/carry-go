import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final airportSearchProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, query) {
      print('Query: $query');
      if (query.trim().length < 2) {
        // 👇 Return an EMPTY LIST stream (not Stream.empty)
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('airports')
          .where('search', arrayContains: query.toLowerCase())
          .limit(10)
          .snapshots()
          .map((snap) => snap.docs.map((d) => d.data()).toList());
    });
