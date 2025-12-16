import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/startup/startup_provider.dart';
import '../../../core/auth/email_verification_controller.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emailVerificationControllerProvider);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    // 🔁 Listen for verification success
    ref.listen(emailVerificationControllerProvider, (prev, next) {
      if (next.verified) {
        // Force splash/startup flow to recompute now that email is verified.
        ref.invalidate(startupProvider);
        Navigator.pushReplacementNamed(context, '/');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_unread,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              const Text(
                'Verify your email',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),

              const SizedBox(height: 16),

              const Text(
                'Check your inbox and click the verification link.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.sending
                      ? null
                      : () async {
                          await ref
                              .read(
                                emailVerificationControllerProvider.notifier,
                              )
                              .resendEmail();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification email sent'),
                            ),
                          );
                        },
                  child: state.sending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Resend Email'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
