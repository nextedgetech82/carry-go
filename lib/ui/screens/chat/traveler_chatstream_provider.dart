import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final travellerChatsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      return FirebaseFirestore.instance
          .collection('chats')
          .where('travellerId', isEqualTo: uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs);
    });
