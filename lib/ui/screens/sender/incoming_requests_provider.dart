import 'package:carrygo/ui/screens/buyer/request_timeline/request_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final incomingTripRequestsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      return FirebaseFirestore.instance
          .collection('trip_requests')
          .where('travellerId', isEqualTo: uid)
          .where('status', isEqualTo: RequestStatus.requested)
          .snapshots()
          .map((snap) => snap.docs);
    });
