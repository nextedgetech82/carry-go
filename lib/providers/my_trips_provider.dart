import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final myTripsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('trips')
      .where('travellerId', isEqualTo: user.uid)
      //.orderBy('departureDate', descending: true)
      .snapshots()
      .map((snapshot) {
        //return snapshot.docs.map((doc) => doc.data()).toList();
        return snapshot.docs.map((doc) {
          return {
            'id': doc.id, // ✅ REQUIRED
            ...doc.data(),
          };
        }).toList();
      });
});
