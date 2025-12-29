import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:carrygo/ui/screens/buyer/dashboard/buyer_drawer.dart';
import 'package:carrygo/ui/screens/buyer/matching/buyer_trip_filter_provider.dart';
import 'package:carrygo/ui/screens/buyer/requests/active_buyer_request_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'buyer_dashboard_tab.dart';

class BuyerDashboardScreen extends ConsumerWidget {
  const BuyerDashboardScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (profile) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            drawer: BuyerDrawer(profile: profile), // ✅ ADD HERE

            appBar: AppBar(
              title: const Text('Buyer Dashboard'),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Post Request'),
                  Tab(text: 'My Requests'),
                  Tab(text: 'Matching Trips'),
                ],
              ),
            ),

            body: TabBarView(
              children: [
                BuyerDashboardTab.postRequest(profile: profile),
                BuyerDashboardTab.myRequests(profile: profile),
                BuyerDashboardTab.matchingTrips(profile: profile),
              ],
            ),
          ),
        );
      },
    );
  }
}
