import 'package:carrygo/ui/screens/buyer/models/fetch_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'active_buyer_request_id_provider.dart';

final activeBuyerRequestProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
      final requestId = ref.watch(activeBuyerRequestIdProvider);

      if (requestId == null) {
        // ✅ Emits once, UI can proceed
        return Stream.value(null);
      }

      return FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .snapshots()
          .map((doc) => doc.exists ? doc : null);
    });

final buyerOpenRequestsProvider = StreamProvider<List<FetchRequestModel>>((
  ref,
) {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  return FirebaseFirestore.instance
      .collection('requests')
      .where('buyerId', isEqualTo: uid)
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => FetchRequestModel.fromDoc(d)).toList(),
      );
});

final selectedBuyerRequestProvider = StateProvider<FetchRequestModel?>(
  (ref) => null,
);

final selectedBuyerRequestIdProvider = StateProvider<String?>((ref) => null);
