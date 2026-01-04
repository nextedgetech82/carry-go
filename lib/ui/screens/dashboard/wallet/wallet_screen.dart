import 'dart:convert';

import 'package:carrygo/ui/screens/dashboard/wallet/wallet_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync = ref.watch(walletTxProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            walletAsync.when(
              data: (snap) {
                final data = snap.data();
                final balance = (data?['balance'] ?? 0).toDouble();
                final totalEarned = (data?['totalEarned'] ?? balance)
                    .toDouble();
                return _WalletHeader(
                  balance: balance,
                  totalEarned: totalEarned,
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Text('Failed to load wallet'),
            ),

            const Divider(height: 1),

            Expanded(
              child: txAsync.when(
                data: (snap) {
                  if (snap.docs.isEmpty) {
                    return const _EmptyWallet();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: snap.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = snap.docs[i].data();
                      return _WalletTxCard(data: t);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Failed to load transactions')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  final double balance;
  final double totalEarned;

  const _WalletHeader({required this.balance, required this.totalEarned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.9),
            theme.colorScheme.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.45),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ───── TITLE ─────
          Row(
            children: const [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'My Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// ───── BALANCE ─────
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 22),

          /// ───── STATS ─────
          Row(
            children: [
              _PremiumStat(
                icon: Icons.trending_up,
                label: 'Total Earned',
                value: '₹ ${totalEarned.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 14),
              const _PremiumStat(
                icon: Icons.lock_outline,
                label: 'Status',
                value: 'Withdrawable',
              ),
            ],
          ),

          const SizedBox(height: 22),

          /// ───── CTA ─────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  builder: (_) => const WithdrawSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Withdraw Funds',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PremiumStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTxCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _WalletTxCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isCredit = data['type'] == 'CREDIT';
    final amount = data['amount'] ?? 0;
    final source = data['source'] ?? 'Transaction';

    final type = data['type'];
    final status = data['status'] ?? 'SUCCESS';

    //final isCredit = type == 'CREDIT';
    final isPending = status == 'PENDING';

    Color color;
    IconData icon;
    String label;

    if (isPending) {
      color = Colors.orange;
      icon = Icons.hourglass_top;
      label = 'Pending Withdrawal';
    } else if (isCredit) {
      color = Colors.green;
      icon = Icons.arrow_downward;
      label = 'Credit';
    } else {
      color = Colors.red;
      icon = Icons.arrow_upward;
      label = 'Debit';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 12, color: color)),
                Text(
                  '${isCredit ? '+' : '-'} ₹${data['amount']}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} ₹$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.account_balance_wallet, size: 60),
          SizedBox(height: 12),
          Text(
            'No wallet activity yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text('Your earnings will appear here'),
        ],
      ),
    );
  }
}

class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final amountCtrl = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdToken();

    await http.post(
      Uri.parse(
        'https://us-central1-carrygo-55444.cloudfunctions.net/requestWithdrawHttp',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "amount": double.parse(amountCtrl.text),
        "bank": {
          "accountHolder": "Demo User",
          "accountNumber": "1234567890",
          "ifsc": "HDFC0001234",
        },
      }),
    );

    Navigator.pop(context);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Withdraw Amount',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: '₹ ',
              labelText: 'Amount',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loading ? null : submit,
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Request Withdraw'),
          ),
        ],
      ),
    );
  }
}
