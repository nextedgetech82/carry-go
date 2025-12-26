import 'package:carrygo/ui/screens/buyer/request_timeline/request_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final acceptedTripRequestsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      return FirebaseFirestore.instance
          .collection('trip_requests')
          .where('travellerId', isEqualTo: uid)
          .where(
            'status',
            whereIn: [
              'accepted',
              'purchased',
              'in_transit',
              'delivered',
              'completed',
              'cancelled',
            ],
          )
          .orderBy('acceptedAt', descending: true)
          .snapshots();
    });

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

final chatByRequestProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      requestId,
    ) {
      return FirebaseFirestore.instance
          .collection('chats')
          .doc(requestId)
          .snapshots();
    });

Future<void> updateRequestStatus({
  required String requestId,
  required String newStatus,
  required String chatId,
}) async {
  final db = FirebaseFirestore.instance;
  final trRef = db.collection('trip_requests').doc(requestId);

  final chatSnap = await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .get();

  if (!chatSnap.exists) {
    throw Exception('Chat not found');
  }

  final chatData = chatSnap.data()!;
  final reqId = chatData['requestId'] as String;
  final reqRef = db.collection('requests').doc(reqId);

  await db.runTransaction((tx) async {
    tx.update(trRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    tx.update(reqRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // tx.set(db.collection('chats').doc(chatId).collection('messages').doc(), {
    //   'type': 'system',
    //   'text': 'Item marked as Purchased',
    //   'createdAt': FieldValue.serverTimestamp(),
    // });

    //final reqRef = db.collection('requests').doc(r['requestId']);
  });
  //final uid = FirebaseAuth.instance.currentUser!.uid;
  // await FirebaseFirestore.instance.collection('requests').doc(requestId).update(
  //   {'status': 'purchased', 'updatedAt': FieldValue.serverTimestamp()},
  // );

  // await FirebaseFirestore.instance.collection('requests').doc(requestId).update(
  //   {
  //     'status': newStatus,
  //     'updatedAt': FieldValue.serverTimestamp(),
  //     'statusHistory': FieldValue.arrayUnion([
  //       {'status': newStatus, 'by': uid, 'at': Timestamp.now()},
  //     ]),
  //   },
  //);
}
