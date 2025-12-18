import 'package:carrygo/ui/screens/buyer/models/fetch_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final postRequestProvider = StateNotifierProvider<PostRequestController, bool>((
  ref,
) {
  return PostRequestController(ref);
});

class PostRequestController extends StateNotifier<bool> {
  PostRequestController(this.ref) : super(false);
  final Ref ref;

  Future<void> submit(FetchRequestModel input) async {
    state = true;
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final doc = FirebaseFirestore.instance.collection('requests').doc();

      final model = FetchRequestModel(
        id: doc.id,
        buyerId: user.uid,
        fromCity: input.fromCity,
        toCity: input.toCity,
        itemName: input.itemName,
        weight: input.weight,
        quantity: input.quantity,
        budget: input.budget,
        deadline: input.deadline,
        status: 'open',
      );

      await doc.set(model.toMap());
    } finally {
      state = false;
    }
  }
}
