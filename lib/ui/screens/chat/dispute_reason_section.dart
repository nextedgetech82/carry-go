import 'package:carrygo/ui/screens/chat/dispute_evidance_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DisputeReasonSection extends StatefulWidget {
  final String disputeId;

  const DisputeReasonSection({super.key, required this.disputeId});

  @override
  State<DisputeReasonSection> createState() => _DisputeReasonSectionState();
}

class _DisputeReasonSectionState extends State<DisputeReasonSection> {
  String? selectedReason;
  final TextEditingController descCtrl = TextEditingController();
  bool saving = false;

  Future<void> _save() async {
    if (selectedReason == null) return;

    setState(() => saving = true);

    final selected = disputeReasons.firstWhere(
      (e) => e['code'] == selectedReason,
    );

    await FirebaseFirestore.instance
        .collection('disputes')
        .doc(widget.disputeId)
        .update({
          'disputeReason': selected['code'],
          'disputeReasonLabel': selected['label'],
          'disputeDescription': descCtrl.text.trim(),
          'reasonUpdatedAt': FieldValue.serverTimestamp(),
        });

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disputes')
          .doc(widget.disputeId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final data = snap.data!.data() as Map<String, dynamic>;
        final locked = data['reasonLocked'] == true;

        // hydrate from Firestore once
        selectedReason ??= data['disputeReason'];
        if (descCtrl.text.isEmpty) {
          descCtrl.text = data['disputeDescription'] ?? '';
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dispute Reason',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              /// 🔽 REASON DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedReason,
                hint: const Text('Select a reason'),
                items: disputeReasons.map((r) {
                  return DropdownMenuItem<String>(
                    value: r['code'],
                    child: Text(r['label']!),
                  );
                }).toList(),
                onChanged: locked
                    ? null
                    : (v) => setState(() => selectedReason = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 12),

              /// ✍ DESCRIPTION
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                enabled: !locked,
                decoration: const InputDecoration(
                  hintText: 'Add more details (optional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              if (locked)
                Row(
                  children: const [
                    Icon(Icons.lock, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'Reason locked after evidence upload',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              /// 💾 SAVE
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: locked || saving || selectedReason == null
                      ? null
                      : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Reason'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
