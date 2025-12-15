import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userProfileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('User not logged in');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data() ?? {});
});
