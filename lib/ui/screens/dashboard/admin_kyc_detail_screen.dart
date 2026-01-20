import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminKycDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const AdminKycDetailScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<AdminKycDetailScreen> createState() => _AdminKycDetailScreenState();
}

class _AdminKycDetailScreenState extends State<AdminKycDetailScreen> {
  bool loading = false;
  final rejectionCtrl = TextEditingController();

  Map<String, dynamic> get kyc => widget.userData['kyc'] ?? {};

  Future<void> _approve() async {
    setState(() => loading = true);

    final admin = FirebaseAuth.instance.currentUser!;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    final batch = FirebaseFirestore.instance.batch();

    // 1️⃣ Update KYC status
    batch.update(userRef, {
      'kyc.status': 'APPROVED',
      'kyc.reviewedAt': FieldValue.serverTimestamp(),
      'kyc.reviewedBy': admin.uid,
      'kyc.rejectionReason': '',
    });

    // 2️⃣ Add audit log
    batch.set(userRef.collection('kyc_audit_logs').doc(), {
      'action': 'APPROVED',
      'statusFrom': 'SUBMITTED',
      'statusTo': 'APPROVED',
      'reviewedBy': admin.uid,
      'reviewedByEmail': admin.email,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': '',
      'adminRole': 'ADMIN', // or SUPER_ADMIN
    });

    await batch.commit();

    if (mounted) Navigator.pop(context);
  }

  Future<void> _reject() async {
    if (rejectionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejection reason is mandatory')),
      );
      return;
    }

    setState(() => loading = true);

    final admin = FirebaseAuth.instance.currentUser!;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    final batch = FirebaseFirestore.instance.batch();

    batch.update(userRef, {
      'kyc.status': 'REJECTED',
      'kyc.reviewedAt': FieldValue.serverTimestamp(),
      'kyc.reviewedBy': admin.uid,
      'kyc.rejectionReason': rejectionCtrl.text.trim(),
    });

    batch.set(userRef.collection('kyc_audit_logs').doc(), {
      'action': 'REJECTED',
      'statusFrom': 'SUBMITTED',
      'statusTo': 'REJECTED',
      'reviewedBy': admin.uid,
      'reviewedByEmail': admin.email,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': rejectionCtrl.text.trim(),
      'adminRole': 'ADMIN',
    });

    await batch.commit();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName =
        '${widget.userData['firstName']} ${widget.userData['lastName']}';
    final email = widget.userData['email'] ?? '';
    final bool canReview = kyc['status'] == 'SUBMITTED';

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 👤 USER IDENTITY
            _SectionCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0] : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: kyc['status']),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 📄 DOCUMENT DETAILS
            _SectionTitle('Document Information'),
            const SizedBox(height: 8),

            _InfoRow(label: 'Type', value: kyc['docType']),
            _InfoRow(label: 'Number', value: kyc['docNumber']),

            const SizedBox(height: 16),

            /// 🖼 DOCUMENT IMAGE
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uploaded Document',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      kyc['docImage'],
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ❌ REJECTION REASON
            _SectionTitle('Rejection Reason (Required if rejecting)'),
            const SizedBox(height: 8),

            TextFormField(
              controller: rejectionCtrl,
              enabled: canReview,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Explain why this KYC is rejected...',
                prefixIcon: Icon(Icons.warning_amber),
              ),
            ),

            const SizedBox(height: 32),

            if (!canReview)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: const [
                    Icon(Icons.lock, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'This KYC has already been reviewed',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            /// ✅ ACTIONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (loading || !canReview) ? null : _approve,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (loading || !canReview) ? null : _reject,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 🔥 6️⃣ AUDIT LOG (ADD HERE)
            KycAuditLogSection(userId: widget.userId),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class KycAuditLogSection extends StatelessWidget {
  final String userId;

  const KycAuditLogSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('kyc_audit_logs')
          .orderBy('reviewedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text(
            'No audit history available',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Approval History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...snap.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final action = data['action'];
              final admin = data['reviewedByEmail'] ?? '';
              final reason = data['rejectionReason'] ?? '';
              final ts = (data['reviewedAt'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: action == 'APPROVED' ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('By: $admin'),
                    if (ts != null)
                      Text(
                        ts.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (reason.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Reason: $reason',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
