import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final buyerRequestsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      return FirebaseFirestore.instance
          .collection('requests')
          .where('buyerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    });

final requestByIdProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      requestId,
    ) {
      return FirebaseFirestore.instance
          .collection('trip_requests')
          .doc(requestId)
          .snapshots();
    });
