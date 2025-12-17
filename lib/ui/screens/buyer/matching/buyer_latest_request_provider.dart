import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final buyerLatestRequestProvider =
    StreamProvider<QueryDocumentSnapshot<Map<String, dynamic>>?>((ref) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      return FirebaseFirestore.instance
          .collection('requests')
          .where('buyerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            return snapshot.docs.first;
          });
    });
