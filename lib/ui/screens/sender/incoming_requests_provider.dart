import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final incomingTripRequestsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      return FirebaseFirestore.instance
          .collection('trip_requests')
          .where('travellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snap) => snap.docs);
    });
