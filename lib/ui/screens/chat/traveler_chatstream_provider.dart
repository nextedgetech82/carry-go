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

final chatOtherUserIdProvider = StreamProvider.family<String, String>((
  ref,
  chatId,
) {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((snap) {
        if (!snap.exists) throw Exception('Chat not found');

        final data = snap.data()!;
        final buyerId = data['buyerId'];
        final travellerId = data['travellerId'];

        return uid == buyerId ? travellerId : buyerId;
      });
});

final userNameByIdProvider = StreamProvider.family<String, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snap) {
        if (!snap.exists) return 'User';

        final data = snap.data()!;
        final first = data['firstName'] ?? '';
        final last = data['lastName'] ?? '';

        return ('$first $last').trim().isEmpty
            ? 'User'
            : ('$first $last').trim();
      });
});
