import 'package:carrygo/ui/screens/dashboard/wallet/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync = ref.watch(walletTxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: Column(
        children: [
          walletAsync.when(
            data: (snap) {
              final data = snap.data();
              final balance = data?['balance'] ?? 0;
              return _WalletHeader(balance: balance);
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error'),
          ),

          const Divider(),

          Expanded(
            child: txAsync.when(
              data: (snap) => ListView(
                children: snap.docs.map((d) {
                  final t = d.data();
                  return ListTile(
                    leading: Icon(
                      t['type'] == 'CREDIT'
                          ? Icons.add_circle
                          : Icons.remove_circle,
                      color: t['type'] == 'CREDIT' ? Colors.green : Colors.red,
                    ),
                    title: Text('₹ ${t['amount']}'),
                    subtitle: Text(t['source']),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  final num balance;

  const _WalletHeader({required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          /// Withdraw button (disabled for now)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null, // 🔒 enable later
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Withdraw (Coming Soon)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
