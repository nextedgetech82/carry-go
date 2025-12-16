import 'package:flutter/material.dart';
import '../post_request/post_request_screen.dart';
import '../matching/matching_trips_list.dart';

class BuyerDashboardTab extends StatelessWidget {
  final Widget child;
  const BuyerDashboardTab._({super.key, required this.child});

  const BuyerDashboardTab.postRequest({Key? key})
    : this._(key: key, child: const PostRequestScreen());

  const BuyerDashboardTab.myRequests({Key? key})
    : this._(key: key, child: const Center(child: Text('My Requests (Next Step)')));

  const BuyerDashboardTab.matchingTrips({Key? key})
    : this._(key: key, child: const MatchingTripsList());

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(12), child: child);
  }
}
