import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carrygo/ui/screens/signup/role_selection.dart';
import 'signup_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController passwordCtrl;
  late final TextEditingController confirmPasswordCtrl;

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController();
    lastNameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    confirmPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    final signupController = ref.read(signupProvider.notifier);

    if (!signupController.validateForm(_formKey, context)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(
          firstName: firstNameCtrl.text.trim(),
          lastName: lastNameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(signupProvider);
    final controller = ref.read(signupProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.flight_takeoff,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join Travel Fetcher and start earning',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              /// 🔹 Form Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: firstNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: lastNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v != null && v.contains('@')
                              ? null
                              : 'Invalid email',
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: !state.showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                state.showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: controller.togglePassword,
                            ),
                          ),
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Min 6 characters',
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: confirmPasswordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (v) => v == passwordCtrl.text
                              ? null
                              : 'Passwords do not match',
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Checkbox(
                              value: state.agreed,
                              onChanged: (v) =>
                                  controller.setAgreed(v ?? false),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'I agree to the Terms & Privacy Policy',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// 🔹 CTA
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _continue,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
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
