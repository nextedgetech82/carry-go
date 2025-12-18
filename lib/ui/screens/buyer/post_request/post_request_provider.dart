import 'package:carrygo/ui/screens/buyer/models/fetch_request_input.dart';
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
  final Ref ref;
  PostRequestController(this.ref) : super(false);

  Future<void> submit(FetchRequestInput input) async {
    state = true;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = FirebaseFirestore.instance.collection('requests').doc();

    final model = FetchRequestModel(
      id: doc.id,
      buyerId: uid,
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

    state = false;
  }
}
