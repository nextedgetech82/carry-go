import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:carrygo/ui/screens/dashboard/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BuyerDrawer extends ConsumerWidget {
  final Map<String, dynamic> profile;

  const BuyerDrawer({super.key, required this.profile});

  Future<void> _confirmSwitchRole(BuildContext context, WidgetRef ref) async {
    final currentRole = profile['role'];
    final newRole = currentRole == 'traveller' ? 'sender' : 'traveller';

    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Switch Role',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 30,
                    color: Colors.black.withOpacity(0.25),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🌈 GRADIENT ICON
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: newRole == 'traveller'
                            ? [Colors.blue, Colors.indigo]
                            : [Colors.orange, Colors.deepOrange],
                      ),
                    ),
                    child: Icon(
                      newRole == 'traveller'
                          ? Icons.flight_takeoff
                          : Icons.local_shipping,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🧠 TITLE
                  Text(
                    'Switch to ${newRole[0].toUpperCase()}${newRole.substring(1)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// 💬 DESCRIPTION
                  Text(
                    newRole == 'traveller'
                        ? 'Post trips and earn by carrying items for others.'
                        : 'Send items safely using verified travellers.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// 🔘 ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Switch Role',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(scale: curved, child: child);
      },
    );

    if (ok == true) {
      /// 📳 HAPTIC CONFIRMATION
      HapticFeedback.mediumImpact();

      await _switchRole(context, ref);
    }
  }

  Future<void> _switchRole(BuildContext context, WidgetRef ref) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final currentRole = profile['role'];

    final newRole = currentRole == 'traveller' ? 'sender' : 'traveller';

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔥 Clear cached state
    ref.invalidate(startupProvider);
    ref.invalidate(userProfileProvider);

    // 🔁 Restart flow
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  bool _isProfileComplete() {
    return (profile['firstName'] ?? '').toString().trim().isNotEmpty &&
        (profile['lastName'] ?? '').toString().trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final fullName =
        '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();

    final displayName = fullName.isEmpty ? 'Buyer' : fullName;
    final phone = profile['phone'] ?? '';
    final complete = _isProfileComplete();

    final subtitle = profile['email'] ?? profile['phone'] ?? 'Verified user';
    final activeRole = profile['role'];
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
                /// 👤 AVATAR
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

                /// 👋 NAME + SUBTITLE
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

                      const SizedBox(height: 6),

                      /// 🔖 ACTIVE ROLE BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activeRole.toUpperCase() == 'SENDER'
                              ? 'Buyer'
                              : 'Traveller',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
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

          /// 📂 MENU SECTION
          _DrawerItem(
            icon: Icons.person_outline,
            title: 'My Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          _DrawerItem(
            icon: Icons.swap_horiz,
            title: activeRole == 'traveller'
                ? 'Switch to Buyer'
                : 'Switch to Traveller',
            onTap: () {
              //Navigator.pop(context);
              //HapticFeedback.mediumImpact();
              _confirmSwitchRole(context, ref);
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
              await FirebaseAuth.instance.signOut();
              ref.invalidate(startupProvider);
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

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
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
      onTap: onTap,
    );
  }
}
