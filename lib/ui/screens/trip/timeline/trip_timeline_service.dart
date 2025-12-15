import 'package:cloud_firestore/cloud_firestore.dart';

class TripTimelineService {
  static Future<void> log({
    required String tripId,
    required String action,
    required String title,
    required String description,
    required String travellerId,
  }) async {
    await FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .collection('timeline')
        .add({
          'action':
              action, // created / updated / completed / cancelled / deleted
          'title': title,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'traveller',
          'createdById': travellerId,
        });
  }
}
