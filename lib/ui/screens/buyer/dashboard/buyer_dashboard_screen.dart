import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:carrygo/ui/screens/buyer/dashboard/buyer_dashboard_tab.dart';
import 'package:carrygo/ui/screens/buyer/dashboard/buyer_drawer.dart';
import 'package:carrygo/ui/screens/feed/feed_screen.dart';
import 'package:carrygo/ui/screens/notifications/notification_history_screen.dart';
import 'package:carrygo/widgets/notification_badge_icon.dart';
import 'package:carrygo/widgets/role_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class BuyerDashboardScreen extends ConsumerWidget {
  BuyerDashboardScreen({super.key});
  final buyerBottomTabProvider = StateProvider<int>((ref) => 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final tabIndex = ref.watch(buyerBottomTabProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (profile) {
        final role = profile['role'] ?? 'buyer';

        return Scaffold(
          drawer: BuyerDrawer(profile: profile),

          appBar: AppBar(
            title: Row(
              children: [
                const SizedBox(width: 16),
                const Text('Travel Fetcher'),
                const SizedBox(width: 10),
                RoleBadge(role: role),
              ],
            ),
            centerTitle: true,
            actions: [
              NotificationBellIcon(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          /// ✅ BODY (STATE PRESERVED)
          body: IndexedStack(
            index: tabIndex,
            children: [
              BuyerDashboardTab.postRequest(profile: profile),
              BuyerDashboardTab.myRequests(profile: profile),
              const FeedScreen(), // 🔥 NEW
              BuyerDashboardTab.matchingTrips(profile: profile),
            ],
          ),

          /// ✅ BOTTOM NAVIGATION
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabIndex,
            onTap: (i) => ref.read(buyerBottomTabProvider.notifier).state = i,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.add_box_outlined),
                label: 'Post',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'My Requests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dynamic_feed),
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.travel_explore),
                label: 'Matching',
              ),
            ],
          ),
        );
      },
    );
  }
}
