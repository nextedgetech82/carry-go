import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/role_selection_controller.dart';
import '../../screens/signup/email_verification_screen.dart';

class RoleSelectionScreenNew extends ConsumerWidget {
  /// 🔑 If true → Phone OTP flow (ONLY role selection)
  final bool phoneOnly;

  /// 🔁 Used ONLY for email/password signup (optional now)
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? password;

  const RoleSelectionScreenNew({
    super.key,
    this.phoneOnly = true,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.password,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(roleSelectionControllerProvider);

    /// 🔁 LISTEN FOR COMPLETION
    ref.listen(roleSelectionControllerProvider, (prev, next) {
      if (prev?.loading == true &&
          next.loading == false &&
          next.error == null) {
        /// 📧 Email signup → go to email verification
        if (!phoneOnly) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          );
        }

        /// 📱 Phone OTP users → app will restart via startupProvider
      }

      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Role')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🧭 TITLE
              Text(
                'How will you use Travel Fetcher?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              /// 🟦 ROLE CARDS
              /// 🟦 ROLE CARDS (RECTANGLE – VERTICAL)
              Column(
                children: [
                  _RoleRectCard(
                    title: 'Traveller',
                    subtitle: 'Earn money by carrying items while you travel.',
                    icon: Icons.flight_takeoff,
                    selected: state.selectedRole == 'traveller',
                    onTap: () => ref
                        .read(roleSelectionControllerProvider.notifier)
                        .selectRole('traveller'),
                  ),
                  const SizedBox(height: 16),
                  _RoleRectCard(
                    title: 'Fetcher',
                    subtitle:
                        'Send / receive items safely through verified travellers.',
                    icon: Icons.local_shipping,
                    selected: state.selectedRole == 'sender',
                    onTap: () => ref
                        .read(roleSelectionControllerProvider.notifier)
                        .selectRole('sender'),
                  ),
                ],
              ),

              const Spacer(),

              /// ℹ️ HELPER TEXT
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'You can change this later from settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              /// ✅ CTA BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: state.loading
                      ? null
                      : () {
                          final notifier = ref.read(
                            roleSelectionControllerProvider.notifier,
                          );

                          /// 📱 PHONE OTP FLOW
                          if (phoneOnly) {
                            notifier.submitPhoneRole(ref, context);
                          }
                          /// 📧 EMAIL SIGNUP FLOW
                          else {
                            notifier.submitSignup(
                              firstName: firstName!,
                              lastName: lastName!,
                              email: email!,
                              phone: phone!,
                              password: password!,
                            );
                          }
                        },
                  child: state.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleRectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleRectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 🔵 ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
              child: Icon(icon, size: 28, color: theme.colorScheme.primary),
            ),

            const SizedBox(width: 16),

            /// 📝 TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),

            /// ✅ CHECK
            if (selected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// ROLE CARD (SQUARE)
/// ─────────────────────────────────────────────

class _RoleSquareCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleSquareCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
              child: Icon(icon, size: 30, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
