import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/ui/screens/buyer/matching/buyer_trip_filter_provider.dart';
import 'package:carrygo/ui/screens/buyer/requests/active_buyer_request_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'buyer_dashboard_tab.dart';

class BuyerDashboardScreen extends ConsumerWidget {
  const BuyerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buyer Dashboard'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                // 🔥 Reset buyer-related state
                ref.invalidate(startupProvider);
                ref.invalidate(buyerTripFilterProvider);
                ref.invalidate(activeBuyerRequestProvider);

                // 🔁 Restart app flow
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (_) => false);
              },
            ),
          ],
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
