import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditTripScreen extends ConsumerStatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;

  const EditTripScreen({super.key, required this.tripId, required this.trip});

  @override
  ConsumerState<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends ConsumerState<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController fromCtrl;
  late TextEditingController toCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController notesCtrl;

  late DateTime departureDate;
  late DateTime arrivalDate;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;

    fromCtrl = TextEditingController(text: trip['fromCity']);
    toCtrl = TextEditingController(text: trip['toCity']);
    weightCtrl = TextEditingController(
      text: trip['availableWeightKg'].toString(),
    );
    priceCtrl = TextEditingController(text: trip['pricePerKg'].toString());
    notesCtrl = TextEditingController(text: trip['notes'] ?? '');

    departureDate = (trip['departureDate'] as Timestamp).toDate();
    arrivalDate = (trip['arrivalDate'] as Timestamp).toDate();
  }

  @override
  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    weightCtrl.dispose();
    priceCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDeparture) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeparture ? departureDate : arrivalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      if (isDeparture) {
        departureDate = picked;
      } else {
        arrivalDate = picked;
      }
    });
  }

  Future<void> _updateTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .update({
          'fromCity': fromCtrl.text.trim(),
          'toCity': toCtrl.text.trim(),
          'departureDate': Timestamp.fromDate(departureDate),
          'arrivalDate': Timestamp.fromDate(arrivalDate),
          'availableWeightKg': int.parse(weightCtrl.text),
          'pricePerKg': int.parse(priceCtrl.text),
          'notes': notesCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _cancelTrip() async {
    setState(() => saving = true);

    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _markCompleted() async {
    setState(() => saving = true);

    await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.trip['status'] ?? 'active';
    final canEdit = status == 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: saving || !canEdit ? null : _updateTrip,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// From
                TextFormField(
                  controller: fromCtrl,
                  enabled: canEdit,
                  decoration: const InputDecoration(labelText: 'From City'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                /// To
                TextFormField(
                  controller: toCtrl,
                  enabled: canEdit,
                  decoration: const InputDecoration(labelText: 'To City'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                /// Dates
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: canEdit ? () => _pickDate(true) : null,
                        child: Text(
                          'Departure: ${departureDate.day}/${departureDate.month}/${departureDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: canEdit ? () => _pickDate(false) : null,
                        child: Text(
                          'Arrival: ${arrivalDate.day}/${arrivalDate.month}/${arrivalDate.year}',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Weight
                TextFormField(
                  controller: weightCtrl,
                  enabled: canEdit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Available Weight (kg)',
                  ),
                ),
                const SizedBox(height: 16),

                /// Price
                TextFormField(
                  controller: priceCtrl,
                  enabled: canEdit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price per kg'),
                ),
                const SizedBox(height: 16),

                /// Notes
                TextFormField(
                  controller: notesCtrl,
                  enabled: canEdit,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),

                const SizedBox(height: 32),

                if (canEdit) ...[
                  /// Cancel Trip
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: saving ? null : _cancelTrip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel Trip'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Mark Completed
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _markCompleted,
                      child: const Text('Mark as Completed'),
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'This trip is $status and cannot be edited.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
