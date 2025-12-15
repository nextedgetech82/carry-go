import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'add_trip_state.dart';

final addTripProvider = StateNotifierProvider<AddTripController, AddTripState>(
  (ref) => AddTripController(),
);

class AddTripController extends StateNotifier<AddTripState> {
  AddTripController() : super(const AddTripState());

  Future<void> addTrip({
    required String fromCity,
    required String toCity,
    required DateTime departureDate,
    required DateTime arrivalDate,
    required int weight,
    required int pricePerKg,
    required String notes,
  }) async {
    state = state.copyWith(loading: true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('trips').add({
      'travellerId': user.uid,
      'fromCity': fromCity,
      'toCity': toCity,
      'departureDate': departureDate,
      'arrivalDate': arrivalDate,
      'availableWeightKg': weight,
      'pricePerKg': pricePerKg,
      'notes': notes,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    state = state.copyWith(loading: false);
  }
}
