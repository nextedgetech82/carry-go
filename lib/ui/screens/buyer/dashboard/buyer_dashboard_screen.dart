import 'package:flutter/material.dart';
import 'buyer_dashboard_tab.dart';

class BuyerDashboardScreen extends StatelessWidget {
  const BuyerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buyer Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Post Request'),
              Tab(text: 'My Requests'),
              Tab(text: 'Matching Trips'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BuyerDashboardTab.postRequest(),
            BuyerDashboardTab.myRequests(),
            BuyerDashboardTab.matchingTrips(),
          ],
        ),
      ),
    );
  }
}
