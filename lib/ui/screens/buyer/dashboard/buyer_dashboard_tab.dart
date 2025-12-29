import 'package:carrygo/ui/screens/buyer/my_requests/my_requests_screen.dart';
import 'package:carrygo/ui/screens/dashboard/profile.dart';
import 'package:carrygo/ui/screens/dashboard/traveller_dashboard.dart';
import 'package:flutter/material.dart';
import '../post_request/post_request_screen.dart';
import '../matching/matching_trips_list.dart';

bool isProfileComplete(Map<String, dynamic> profile) {
  return (profile['firstName'] ?? '').toString().isNotEmpty &&
      (profile['lastName'] ?? '').toString().isNotEmpty;
}

class BuyerDashboardTab extends StatelessWidget {
  final Widget child;
  final Map<String, dynamic> profile;

  const BuyerDashboardTab._({
    super.key,
    required this.child,
    required this.profile,
  });

  /// 🔹 POST REQUEST TAB
  factory BuyerDashboardTab.postRequest({
    Key? key,
    required Map<String, dynamic> profile,
  }) {
    return BuyerDashboardTab._(
      key: key,
      profile: profile,
      child: const PostRequestScreen(),
    );
  }

  /// 🔹 MY REQUESTS TAB
  factory BuyerDashboardTab.myRequests({
    Key? key,
    required Map<String, dynamic> profile,
  }) {
    return BuyerDashboardTab._(
      key: key,
      profile: profile,
      child: const MyRequestsScreen(),
    );
  }

  /// 🔹 MATCHING TRIPS TAB
  factory BuyerDashboardTab.matchingTrips({
    Key? key,
    required Map<String, dynamic> profile,
  }) {
    return BuyerDashboardTab._(
      key: key,
      profile: profile,
      child: const MatchingTripsList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complete = isProfileComplete(profile);

    final fullName =
        '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 👋 GREETING HEADER (LIKE TRAVELLER)
          _BuyerHeader(fullName: fullName.isEmpty ? 'Buyer' : fullName),

          const SizedBox(height: 16),

          /// ⚠️ PROFILE INCOMPLETE BANNER
          if (!complete) ...[
            const CompleteProfileBanner(),
            const SizedBox(height: 12),
          ],

          /// 🔒 BLOCK POST REQUEST IF PROFILE INCOMPLETE
          Expanded(
            child: AbsorbPointer(
              absorbing: !complete && child is PostRequestScreen,
              child: Opacity(
                opacity: !complete && child is PostRequestScreen ? 0.5 : 1,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// PROFILE INCOMPLETE BANNER
/// ─────────────────────────────────────────
class CompleteProfileBanner extends StatelessWidget {
  const CompleteProfileBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Complete your profile to post requests',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class _BuyerHeader extends StatelessWidget {
  final String fullName;

  const _BuyerHeader({required this.fullName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back 👋',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Verified',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
