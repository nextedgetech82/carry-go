import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/ui/screens/trip/add_trip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravellerDashboard extends ConsumerWidget {
  const TravellerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Fetcher'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              // 🔥 IMPORTANT: clear cached providers
              ref.invalidate(startupProvider);
              ref.invalidate(userProfileProvider);

              // 🔁 Go to splash (fresh routing)
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';

          return _DashboardContent(
            theme: theme,
            fullName: '$firstName $lastName',
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final ThemeData theme;
  final String fullName;

  const _DashboardContent({required this.theme, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome back, $fullName 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
          ),

          const SizedBox(height: 8),

          Text(
            'Earn money by carrying items on your trips',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),

          const SizedBox(height: 24),

          Row(
            children: const [
              _StatCard(
                title: 'Total Earnings',
                value: '\$0',
                icon: Icons.attach_money,
              ),
              SizedBox(width: 16),
              _StatCard(title: 'Trips', value: '0', icon: Icons.flight_takeoff),
            ],
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTripScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Post a New Trip',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
