// providers/trip_actions_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final tripActionsProvider = StateNotifierProvider<TripActionsController, bool>(
  (ref) => TripActionsController(),
);

class TripActionsController extends StateNotifier<bool> {
  TripActionsController() : super(false);

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

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Trip marked as $status')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      state = false;
    }
  }

  /// 🗑️ SOFT DELETE
  Future<void> deleteTrip({
    required String tripId,
    required BuildContext context,
  }) async {
    try {
      state = true;

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      state = false;
    }
  }
}

final tripDetailsStreamProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, tripId) {
      return FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) throw Exception('Trip not found');
            return {...doc.data()!, 'id': doc.id};
          });
    });
