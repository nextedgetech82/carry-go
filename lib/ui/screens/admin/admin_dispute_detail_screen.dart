import 'dart:convert';

import 'package:carrygo/ui/screens/chat/full_image_screen.dart';
import 'package:carrygo/ui/screens/chat/pdf_preview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

          final status = data['status'];

          final adminNoteReadOnly =
              status == 'APPEALED' || status == 'RESOLVED';

          /// 🔥 AUTO CLOSE AFTER RESOLUTION (BEST UX)
          if (data['status'] == 'RESOLVED') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true); // true = notify parent to refresh
              }
            });

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Dispute resolved successfully',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              /// 🔹 HEADER (fixed)
              _DisputeHeaderWithEvidenceCount(disputeId: disputeId, data: data),

              /// 🔹 SCROLLABLE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 📎 EVIDENCE
                      //_SectionTitle('Evidence'),
                      //_AdminEvidenceList(disputeId: disputeId),
                      CollapsibleSection(
                        title: 'Evidence',
                        initiallyExpanded: true,
                        trailing: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('disputes')
                              .doc(disputeId)
                              .collection('evidence')
                              .snapshots(),
                          builder: (context, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            if (count == 0) return const SizedBox.shrink();

                            return _EvidenceCountBadge(count: count);
                          },
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _AdminEvidenceList(disputeId: disputeId),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// 🕒 TIMELINE
                      //_SectionTitle('Activity Timeline'),
                      //_DisputeTimeline(disputeId: disputeId),
                      CollapsibleSection(
                        title: 'Activity Timeline',
                        initiallyExpanded: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _DisputeTimeline(disputeId: disputeId),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// 📝 ADMIN NOTES
                      _AdminCommentBox(
                        disputeId: disputeId,
                        initialNote: data['adminNote'] ?? '',
                        readOnly: adminNoteReadOnly,
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔹 ACTION BAR (fixed bottom)
              _AdminActionBar(
                disputeId: disputeId,
                tripRequestId: data['tripRequestId'],
                status: data['status'], // ✅ PASS
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DisputeHeaderWithEvidenceCount extends StatelessWidget {
  final String disputeId;
  final Map<String, dynamic> data;

  const _DisputeHeaderWithEvidenceCount({
    required this.disputeId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🧾 MAIN HEADER
        _DisputeHeader(data: data),

        /// 📎 EVIDENCE COUNT BADGE
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('disputes')
                .doc(disputeId)
                .collection('evidence')
                .snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;

              if (count == 0) return const SizedBox.shrink();

              return Align(
                alignment: Alignment.centerLeft,
                child: _EvidenceCountBadge(count: count),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EvidenceCountBadge extends StatelessWidget {
  final int count;

  const _EvidenceCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, size: 16, color: Colors.indigo),
          const SizedBox(width: 6),
          Text(
            '$count Evidence${count > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
    final createdAt = (data['createdAt'] as Timestamp).toDate();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('trip_requests')
          .doc(data['tripRequestId'])
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Loading trip details…'),
          );
        }

        final trip = snap.data!.data() as Map<String, dynamic>;

        final fromCity = trip['fromCity'];
        final toCity = trip['toCity'];
        final item = trip['itemName'];
        final weight = trip['requestedWeightKg'] as num?;
        final price = trip['pricePerKg'] as num?;
        final total = (weight ?? 0) * (price ?? 0);

        final priority = _priority(total);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🚚 ROUTE
              Text(
                '$fromCity → $toCity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 10),

              /// 📦 ITEM + PRICE
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _ItemBadge(itemName: item),
                  Text(
                    '$weight kg × ₹$price',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '= ₹$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  _PriorityBadge(priority: priority),
                ],
              ),

              const SizedBox(height: 16),

              /// 📝 DISPUTE TEXT
              Text(
                data['reason'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data['description'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 14),

              /// 👤 USERS
              Wrap(
                spacing: 12,
                children: [
                  _UserChip(label: 'Buyer', userId: data['buyerId']),
                  _UserChip(label: 'Traveller', userId: data['travellerId']),
                ],
              ),

              const SizedBox(height: 10),

              /// 🕒 DATE
              Text(
                'Raised on: ${DateFormat.yMMMd().add_jm().format(createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  String _priority(num total) {
    if (total >= 5000) return 'HIGH';
    if (total >= 1000) return 'MEDIUM';
    return 'LOW';
  }
}

class _ItemBadge extends StatelessWidget {
  final String itemName;
  const _ItemBadge({required this.itemName});

  @override
  Widget build(BuildContext context) {
    final color = itemName.toLowerCase().contains('mobile')
        ? Colors.blue
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        itemName.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priority == 'HIGH'
        ? Colors.red
        : priority == 'MEDIUM'
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
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

  Future<void> _addTimelineEvent(
    String disputeId,
    String type,
    String title,
  ) async {
    await FirebaseFirestore.instance
        .collection('disputes')
        .doc(disputeId)
        .collection('timeline')
        .add({
          'type': type,
          'title': title,
          'createdAt': FieldValue.serverTimestamp(),
          'createdByRole': 'admin',
        });
  }

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

        return Column(
          children: List.generate(snap.data!.docs.length, (i) {
            final e = snap.data!.docs[i].data() as Map<String, dynamic>;
            final isImage = e['type'] == 'IMAGE';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EvidencePremiumCard(
                disputeId: disputeId,
                isImage: isImage,
                filename: e['filename'],
                url: e['url'],
                reviewed: e['reviewed'] == true,
                onMarkReviewed: () async {
                  await FirebaseFirestore.instance
                      .collection('disputes')
                      .doc(disputeId)
                      .collection('evidence')
                      .doc(snap.data!.docs[i].id)
                      .update({
                        'reviewed': true,
                        'reviewedAt': FieldValue.serverTimestamp(),
                      });

                  await _addTimelineEvent(
                    disputeId,
                    'ADMIN_REVIEW',
                    'Admin reviewed evidence',
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }
}

class _EvidencePremiumCard extends StatelessWidget {
  final String disputeId;
  final bool isImage;
  final String filename;
  final String url;
  final bool reviewed;
  final VoidCallback onMarkReviewed;

  const _EvidencePremiumCard({
    required this.disputeId,
    required this.isImage,
    required this.filename,
    required this.url,
    required this.reviewed,
    required this.onMarkReviewed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// CARD
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () {
              if (!isImage) return;

              // Fetch first two image URLs
              FirebaseFirestore.instance
                  .collection('disputes')
                  .doc(disputeId)
                  .collection('evidence')
                  .where('type', isEqualTo: 'IMAGE')
                  .limit(2)
                  .get()
                  .then((snap) {
                    if (snap.docs.length == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageCompareScreen(
                            leftUrl: snap.docs[0]['url'],
                            rightUrl: snap.docs[1]['url'],
                          ),
                        ),
                      );
                    }
                  });
            },
            onTap: () {
              if (isImage) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullImageViewer(imageUrl: url),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  /// THUMB
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isImage
                        ? Image.network(
                            url,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.picture_as_pdf, size: 48),
                  ),
                  const SizedBox(width: 12),

                  /// META
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filename,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reviewed ? 'Reviewed' : 'Not reviewed',
                          style: TextStyle(
                            fontSize: 12,
                            color: reviewed ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// REVIEW BUTTON
        if (!reviewed)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: onMarkReviewed,
            ),
          ),
      ],
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
  final String status;

  const _AdminActionBar({
    required this.disputeId,
    required this.tripRequestId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    // 🔒 After resolved → nothing
    if (status == 'RESOLVED') {
      return const SizedBox.shrink();
    }

    // 🔁 Appeal handling ONLY
    if (status == 'APPEALED') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _AppealActionSection(
            disputeId: disputeId,
            tripRequestId: tripRequestId,
          ),
        ),
      );
    }

    // ✅ Normal dispute resolution (OPEN)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disputes')
          .doc(disputeId)
          .collection('evidence')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;
        final reviewed = docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['reviewed'] == true;
        }).length;

        final canResolve = total > 0 && reviewed == total;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!canResolve)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.lock, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Review all evidence before resolving',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canResolve
                            ? () => _confirm(context, 'BUYER')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canResolve
                              ? Colors.green
                              : Colors.grey,
                        ),
                        child: const Text('Buyer Wins'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canResolve
                            ? () => _confirm(context, 'TRAVELLER')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canResolve
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        child: const Text('Traveller Wins'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  Future<void> _resolveDispute(BuildContext context, String winner) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken(true);

      final res = await http.post(
        Uri.parse(
          'https://us-central1-carrygo-55444.cloudfunctions.net/resolveDisputeHttp',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'disputeId': disputeId, 'winner': winner}),
      );

      if (res.statusCode != 200) {
        final body = jsonDecode(res.body);
        throw Exception(body['error'] ?? 'Resolution failed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$winner wins. Dispute resolved.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
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

class _UserChip extends StatelessWidget {
  final String label;
  final String userId;

  const _UserChip({required this.label, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 14),
          const SizedBox(width: 6),
          Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 4),
          _UserNameText(userId: userId, fallbackLabel: label),
        ],
      ),
    );
  }
}

class _UserNameText extends StatelessWidget {
  final String userId;
  final String fallbackLabel;

  const _UserNameText({required this.userId, required this.fallbackLabel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Text(
            fallbackLabel,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = data['firstName'] + ' ' + data['lastName'] ?? 'Unknown';

        return Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _AdminCommentBox extends StatefulWidget {
  final String disputeId;
  final String initialNote;
  final bool readOnly; // 🔥 ADD

  const _AdminCommentBox({
    required this.disputeId,
    required this.initialNote,
    this.readOnly = false,
  });

  @override
  State<_AdminCommentBox> createState() => _AdminCommentBoxState();
}

class _AdminCommentBoxState extends State<_AdminCommentBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Notes',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            maxLines: 3,
            enabled: !widget.readOnly, // 🔒 LOCK
            decoration: InputDecoration(
              hintText: widget.readOnly
                  ? 'Notes are locked'
                  : 'Write internal remarks for this dispute...',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.readOnly ? null : _save,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('disputes')
        .doc(widget.disputeId)
        .update({
          'adminNote': _controller.text.trim(),
          'adminNoteUpdatedAt': FieldValue.serverTimestamp(),
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Admin note saved')));
  }
}

class ImageCompareScreen extends StatelessWidget {
  final String leftUrl;
  final String rightUrl;

  const ImageCompareScreen({required this.leftUrl, required this.rightUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Evidence')),
      body: Row(
        children: [
          Expanded(child: Image.network(leftUrl, fit: BoxFit.contain)),
          const VerticalDivider(width: 1),
          Expanded(child: Image.network(rightUrl, fit: BoxFit.contain)),
        ],
      ),
    );
  }
}

class _DisputeTimeline extends StatelessWidget {
  final String disputeId;

  const _DisputeTimeline({required this.disputeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disputes')
          .doc(disputeId)
          .collection('timeline')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const Text(
              //   'Activity Timeline',
              //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              // ),
              //const SizedBox(height: 8),
              ...snap.data!.docs.map((d) {
                final e = d.data() as Map<String, dynamic>;

                return ListTile(
                  leading: const Icon(Icons.timeline),
                  title: Text(e['title'] ?? 'Activity'),
                  subtitle: Text(
                    (() {
                      final ts = e['createdAt'] as Timestamp?;
                      final date = ts?.toDate();
                      return date == null
                          ? 'Just now'
                          : DateFormat.yMMMd().add_jm().format(date);
                    })(),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? trailing;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.trailing,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// HEADER
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _expanded ? 0.5 : 0,
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        ),

        /// BODY
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.child,
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

class _AppealActionSection extends StatefulWidget {
  final String disputeId;
  final String tripRequestId;

  const _AppealActionSection({
    required this.disputeId,
    required this.tripRequestId,
  });

  @override
  State<_AppealActionSection> createState() => _AppealActionSectionState();
}

class _AppealActionSectionState extends State<_AppealActionSection> {
  final _adminNoteController = TextEditingController();
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _adminNoteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Admin Note (optional for appeal)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _processing
                    ? null
                    : () => _resolve(context, 'ACCEPT'),
                child: const Text('Accept Appeal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: _processing
                    ? null
                    : () => _resolve(context, 'REJECT'),
                child: const Text('Reject Appeal'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _resolve(BuildContext context, String decision) async {
    setState(() => _processing = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken(true);

      final res = await http.post(
        Uri.parse(
          'https://us-central1-carrygo-55444.cloudfunctions.net/adminResolveAppealHttp',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tripRequestId': widget.tripRequestId,
          'decision': decision,
          'adminNote': _adminNoteController.text.trim(),
        }),
      );

      if (res.statusCode != 200) {
        final body = jsonDecode(res.body);
        throw Exception(body['error'] ?? 'Failed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'ACCEPT' ? 'Appeal accepted' : 'Appeal rejected',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // 🔥 refresh parent
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _processing = false);
    }
  }
}

class _ResolveDisputeSection extends StatelessWidget {
  final String disputeId;

  const _ResolveDisputeSection({required this.disputeId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirm(context, 'BUYER'),
            child: const Text('Buyer Wins'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirm(context, 'TRAVELLER'),
            child: const Text('Traveller Wins'),
          ),
        ),
      ],
    );
  }

  void _confirm(BuildContext context, String winner) {
    // your existing confirm + resolve logic
  }
}
