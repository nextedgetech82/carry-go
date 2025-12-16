import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/fetch_request_model.dart';

class PostRequestController extends StateNotifier<bool> {
  PostRequestController(this.ref) : super(false);
  final Ref ref;

  Future<void> submit(FetchRequestModel model) async {
    try {
      state = true;
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('requests')
          .add(model.toMap(user.uid));
    } finally {
      state = false;
    }
  }
}
