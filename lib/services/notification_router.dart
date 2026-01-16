import 'package:flutter/material.dart';

class NotificationRouter {
  static void handle(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'DISPUTE_RESULT':
      case 'APPEAL_RESULT':
        final disputeId = data['disputeId'];
        if (disputeId != null) {
          Navigator.pushNamed(context, '/dispute', arguments: disputeId);
        }
        break;

      case 'DISPUTE_OPEN':
        Navigator.pushNamed(context, '/admin/disputes');
        break;

      case 'WITHDRAW_APPROVED':
        Navigator.pushNamed(context, '/wallet');
        break;

      case 'TRIP_STATUS':
        final tripRequestId = data['tripRequestId'];
        if (tripRequestId != null) {
          Navigator.pushNamed(
            context,
            '/trip-request',
            arguments: tripRequestId,
          );
        }
        break;

      default:
        Navigator.pushNamed(context, '/notifications');
    }
  }
}
