import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/providers/my_trips_provider.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:carrygo/ui/screens/dashboard/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TravellerDrawer extends ConsumerWidget {
  final Map<String, dynamic> profile;

  const TravellerDrawer({super.key, required this.profile});

  bool _isProfileComplete() {
    return (profile['firstName'] ?? '').toString().trim().isNotEmpty &&
        (profile['lastName'] ?? '').toString().trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final fullName =
        '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();

    final displayName = fullName.isEmpty ? 'Traveller' : fullName;
    final phone = profile['phone'] ?? '';
    final complete = _isProfileComplete();

    final initials = displayName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Drawer(
      child: Column(
        children: [
          /// 🌈 PREMIUM HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                /// 👤 AVATAR WITH RING
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                /// 👋 NAME + PHONE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ✅ PROFILE STATUS BADGE
                Icon(
                  complete ? Icons.verified : Icons.warning_amber_rounded,
                  color: complete ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// 👤 MY PROFILE
          _DrawerItem(
            icon: Icons.person_outline,
            title: 'My Profile',
            trailing: complete
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.warning_amber, color: Colors.orange),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          // 🔧 SETTINGS (FUTURE)
          _DrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),

          const Spacer(),

          const Divider(height: 1),

          /// 🚪 LOGOUT
          _DrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();

              ref.invalidate(startupProvider);
              ref.invalidate(userProfileProvider);
              ref.invalidate(myTripsProvider);

              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: color ?? theme.iconTheme.color),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
