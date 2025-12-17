import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
