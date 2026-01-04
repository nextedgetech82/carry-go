import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DisputeService {
  static Future<void> raiseDispute({
    required String tripRequestId,
    required String reason,
    String? description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken();

    final res = await http.post(
      Uri.parse(
        'https://us-central1-carrygo-55444.cloudfunctions.net/raiseDisputeHttp',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tripRequestId': tripRequestId,
        'reason': reason,
        'description': description ?? '',
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }
}
