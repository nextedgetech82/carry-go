import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final sendRequestProvider = StateNotifierProvider<SendRequestController, bool>(
  (ref) => SendRequestController(),
);

class SendRequestController extends StateNotifier<bool> {
  SendRequestController() : super(false);

  Future<void> sendRequest({
    required String tripId,
    required Map<String, dynamic> trip,
    required int weight,
    required BuildContext context,
  }) async {
    try {
      state = true;

      final user = FirebaseAuth.instance.currentUser!;
      final total = weight * trip['pricePerKg'];

      await FirebaseFirestore.instance.collection('requests').add({
        'tripId': tripId,
        'senderId': user.uid,
        'travellerId': trip['travellerId'],
        'fromCity': trip['fromCity'],
        'toCity': trip['toCity'],
        'requestedWeightKg': weight,
        'pricePerKg': trip['pricePerKg'],
        'totalPrice': total,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      state = false;
    }
  }
}

final senderRequestsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return const Stream.empty();
      }

      return FirebaseFirestore.instance
          .collection('requests')
          .where('senderId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
    });
