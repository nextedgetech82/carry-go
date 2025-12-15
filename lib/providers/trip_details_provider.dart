import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

final tripDetailsProvider = StateNotifierProvider<TripDetailsController, bool>(
  (ref) => TripDetailsController(),
);

class TripDetailsController extends StateNotifier<bool> {
  TripDetailsController() : super(false);

  Future<void> updateStatus({
    required String tripId,
    required String status,
    required BuildContext context,
  }) async {
    try {
      state = true;

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Trip marked as $status')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      state = false;
    }
  }
}
