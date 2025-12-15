import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SenderTripDetailsScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;

  const SenderTripDetailsScreen({
    super.key,
    required this.tripId,
    required this.trip,
  });

  @override
  State<SenderTripDetailsScreen> createState() =>
      _SenderTripDetailsScreenState();
}

class _SenderTripDetailsScreenState extends State<SenderTripDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();

  bool sending = false;

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  int get availableWeight => widget.trip['availableWeightKg'];
  int get pricePerKg => widget.trip['pricePerKg'];

  int get totalPrice {
    final w = int.tryParse(_weightCtrl.text) ?? 0;
    return w * pricePerKg;
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => sending = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      await db.collection('requests').add({
        'tripId': widget.tripId,
        'travellerId': widget.trip['travellerId'],
        'senderId': user.uid,
        'fromCity': widget.trip['fromCity'],
        'toCity': widget.trip['toCity'],
        'requestedWeightKg': int.parse(_weightCtrl.text),
        'pricePerKg': pricePerKg,
        'totalPrice': totalPrice,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Route
            Text(
              '${widget.trip['fromCity']} → ${widget.trip['toCity']}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _InfoTile(
              icon: Icons.calendar_today,
              label: 'Travel Dates',
              value:
                  '${_formatDate(widget.trip['departureDate'])} → ${_formatDate(widget.trip['arrivalDate'])}',
            ),

            _InfoTile(
              icon: Icons.inventory_2,
              label: 'Available Weight',
              value: '$availableWeight kg',
            ),

            _InfoTile(
              icon: Icons.currency_rupee,
              label: 'Price per Kg',
              value: '₹$pricePerKg',
            ),

            if ((widget.trip['notes'] ?? '').toString().isNotEmpty)
              _InfoTile(
                icon: Icons.note,
                label: 'Notes',
                value: widget.trip['notes'],
              ),

            const SizedBox(height: 32),

            /// 🔹 Request Form
            Text(
              'Send Request',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight to send (kg)',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter weight';
                      }

                      final w = int.tryParse(v);
                      if (w == null || w <= 0) {
                        return 'Invalid weight';
                      }

                      if (w > availableWeight) {
                        return 'Only $availableWeight kg available';
                      }

                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  /// 💰 Price Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Total Price: ₹$totalPrice',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// 🚀 Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: sending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send Request'),
                      onPressed: sending ? null : _sendRequest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// INFO TILE
/// ─────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
