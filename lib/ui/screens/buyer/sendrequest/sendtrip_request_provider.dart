import 'package:carrygo/ui/screens/buyer/models/fetch_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final sendTripRequestProvider =
    StateNotifierProvider<SendTripRequestController, bool>((ref) {
      return SendTripRequestController(ref);
    });

class SendTripRequestController extends StateNotifier<bool> {
  SendTripRequestController(this.ref) : super(false);
  final Ref ref;

  Future<void> send({
    required QueryDocumentSnapshot<Map<String, dynamic>> tripDoc,
    required FetchRequestModel request,
  }) async {
    state = true;

    final db = FirebaseFirestore.instance;

    try {
      await db.runTransaction((tx) async {
        final tripRef = tripDoc.reference;
        final tripSnap = await tx.get(tripRef);

        final available = (tripSnap['availableWeightKg'] ?? 0).toDouble();

        if (available < request.weight) {
          throw Exception('Not enough available weight');
        }

        final pricePerKg = (tripSnap['pricePerKg'] ?? 0).toDouble();

        final totalPrice = request.weight * pricePerKg;

        // 🔹 1️⃣ Create trip_requests entry
        final linkRef = db.collection('trip_requests').doc();

        tx.set(linkRef, {
          'tripId': tripRef.id,
          'requestId': request.id,
          'buyerId': request.buyerId,
          'travellerId': tripSnap['travellerId'],
          'fromCity': request.fromCity,
          'toCity': request.toCity,
          'itemName': request.itemName,
          'requestedWeightKg': request.weight,
          'pricePerKg': pricePerKg,
          'totalPrice': totalPrice,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 🔹 2️⃣ Update request status
        tx.update(db.collection('requests').doc(request.id), {
          'status': 'sent',
        });

        // ❌ DO NOT deduct weight yet
        // Weight is deducted only when traveller ACCEPTS
      });
    } finally {
      state = false;
    }
  }
}
