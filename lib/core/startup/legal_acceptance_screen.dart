import 'package:carrygo/core/startup/legal_webview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LegalAcceptanceScreen extends StatefulWidget {
  const LegalAcceptanceScreen({super.key});

  @override
  State<LegalAcceptanceScreen> createState() => _LegalAcceptanceScreenState();
}

class _LegalAcceptanceScreenState extends State<LegalAcceptanceScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool agreed = false;
  bool loading = false;

  static const _policyVersion = 'v1.0';

  Future<void> _accept() async {
    if (!agreed || loading) return;

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'legal': {
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
        'version': _policyVersion,
      },
    }, SetOptions(merge: true));

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before you continue',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please review and accept our legal terms',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 STEP INDICATOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(
                  2,
                  (i) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: _index >= i
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 LEGAL CONTENT
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _LegalCard(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle:
                        'By using Travel Fetcher, you agree to comply with all applicable laws and platform rules.',
                    policyUrl: 'https://carrygo.app/terms',
                  ),
                  _LegalCard(
                    icon: Icons.lock_outline,
                    title: 'Privacy Policy',
                    subtitle:
                        'We respect your privacy and protect your personal data responsibly.',
                    policyUrl: 'https://carrygo.app/privacy',
                  ),
                ],
              ),
            ),

            /// 🔹 AGREEMENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isLast ? 1 : 0.6,
                child: CheckboxListTile(
                  value: agreed,
                  onChanged: isLast
                      ? (v) => setState(() => agreed = v ?? false)
                      : null,
                  title: const Text(
                    'I agree to the Terms & Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'You must accept to continue',
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔹 CTA BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: (!loading && (isLast ? agreed : true))
                      ? () {
                          if (isLast) {
                            _accept();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      : null,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: (!isLast || agreed)
                            ? [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.85),
                              ]
                            : [Colors.grey.shade400, Colors.grey.shade400],
                      ),
                      boxShadow: (!isLast || agreed)
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.35,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isLast ? 'Accept & Continue' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///
/// 🔹 PREMIUM LEGAL CARD
///
class _LegalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? policyUrl;

  const _LegalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.policyUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),

            if (policyUrl != null) ...[
              const SizedBox(height: 20),

              TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text(
                  'Read full policy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LegalWebViewScreen(title: title, url: policyUrl!),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
