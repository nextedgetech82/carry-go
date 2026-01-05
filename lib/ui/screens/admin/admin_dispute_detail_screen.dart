import 'package:carrygo/ui/screens/chat/full_image_screen.dart';
import 'package:carrygo/ui/screens/chat/pdf_preview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDisputeDetailScreen extends StatelessWidget {
  final String disputeId;

  const AdminDisputeDetailScreen({super.key, required this.disputeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Review')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('disputes')
            .doc(disputeId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              _DisputeHeader(data: data),
              const Divider(height: 1),
              Expanded(child: _AdminEvidenceList(disputeId: disputeId)),
              _AdminActionBar(
                disputeId: disputeId,
                tripRequestId: data['tripRequestId'],
              ),
            ],
          );
        },
      ),
    );
  }
}

//
// =======================
// 🔹 HEADER
// =======================
//
class _DisputeHeader extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DisputeHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final createdAt = (data['createdAt'] as Timestamp).toDate().toLocal();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['reason'] ?? 'Dispute',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            data['description'] ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),

          _InfoRow('Trip Request', data['tripRequestId']),
          _InfoRow('Buyer ID', data['buyerId']),
          _InfoRow('Traveller ID', data['travellerId']),

          const SizedBox(height: 8),
          Text(
            'Raised on: $createdAt',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

//
// =======================
// 🔹 EVIDENCE LIST
// =======================
//
class _AdminEvidenceList extends StatelessWidget {
  final String disputeId;

  const _AdminEvidenceList({required this.disputeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disputes')
          .doc(disputeId)
          .collection('evidence')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No evidence uploaded',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) {
            final e = snap.data!.docs[i].data() as Map<String, dynamic>;
            final isImage = e['type'] == 'IMAGE';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: Icon(isImage ? Icons.image : Icons.picture_as_pdf),
                title: Text(e['filename'] ?? 'Evidence'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  if (isImage) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullImageViewer(imageUrl: e['url']),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerScreen(
                          pdfUrl: e['url'],
                          filename: e['filename'],
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

//
// =======================
// 🔹 ACTION BAR
// =======================
//
class _AdminActionBar extends StatelessWidget {
  final String disputeId;
  final String tripRequestId;

  const _AdminActionBar({required this.disputeId, required this.tripRequestId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _confirm(context, 'BUYER');
                },
                child: const Text('Buyer Wins'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _confirm(context, 'TRAVELLER');
                },
                child: const Text('Traveller Wins'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context, String winner) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Resolution'),
        content: Text('Resolve dispute in favour of $winner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resolveDispute(context, winner);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _resolveDispute(BuildContext context, String winner) {
    // 🔥 NEXT STEP:
    // Call Cloud Function resolveDisputeHttp
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Resolving dispute: $winner wins')));
  }
}

//
// =======================
// 🔹 SHARED UI
// =======================
//
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
