import 'package:carrygo/ui/screens/dashboard/admin_kyc_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminKycListScreen extends StatelessWidget {
  const AdminKycListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KYC Approvals',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('kyc.status', isEqualTo: 'SUBMITTED')
            .orderBy('kyc.submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState();
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final user = docs[i];
              final data = user.data() as Map<String, dynamic>;
              final kyc = data['kyc'] ?? {};

              final firstName = data['firstName'] ?? '';
              final lastName = data['lastName'] ?? '';
              final docType = kyc['docType'] ?? 'Document';
              final docNumber = kyc['docNumber'] ?? '';
              final initials =
                  '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                      .toUpperCase();

              final Timestamp submittedAt = kyc['submittedAt'];
              final sla = calculateKycSla(submittedAt);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminKycDetailScreen(userId: user.id, userData: data),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// 👤 USER AVATAR
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.15,
                        ),
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      /// 📄 USER + KYC INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $lastName',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            Text(
                              '$docType • $docNumber',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 10),

                            _SlaChip(label: sla.label, color: sla.color),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// ➡️ ARROW
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 🟠 STATUS CHIP
class _StatusChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'PENDING REVIEW',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Colors.orange,
        ),
      ),
    );
  }
}

/// 📭 EMPTY STATE
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No pending KYC requests',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class KycSla {
  final String label;
  final Color color;

  const KycSla(this.label, this.color);
}

KycSla calculateKycSla(Timestamp submittedAt) {
  final now = DateTime.now();
  final submitted = submittedAt.toDate();
  final diff = now.difference(submitted);

  if (diff.inMinutes < 60) {
    return KycSla('Pending ${diff.inMinutes}m', Colors.green);
  }

  if (diff.inHours < 6) {
    return KycSla('Pending ${diff.inHours}h', Colors.orange);
  }

  return KycSla('Pending ${diff.inDays}d', Colors.red);
}

class _SlaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SlaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}
