import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_trip_controller.dart';

class AddTripScreen extends ConsumerStatefulWidget {
  const AddTripScreen({super.key});

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  DateTime? departureDate;
  DateTime? arrivalDate;

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
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      if (isDeparture) {
        departureDate = date;
      } else {
        arrivalDate = date;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (departureDate == null || arrivalDate == null) return;

    await ref
        .read(addTripProvider.notifier)
        .addTrip(
          fromCity: fromCtrl.text.trim(),
          toCity: toCtrl.text.trim(),
          departureDate: departureDate!,
          arrivalDate: arrivalDate!,
          weight: int.parse(weightCtrl.text),
          pricePerKg: int.parse(priceCtrl.text),
          notes: notesCtrl.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(addTripProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Trip'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header
              Text(
                'Trip Details',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Share your travel route and available space',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),

              const SizedBox(height: 24),

              /// 🔹 Form Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: fromCtrl,
                          decoration: const InputDecoration(
                            labelText: 'From City',
                            prefixIcon: Icon(Icons.flight_takeoff),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: toCtrl,
                          decoration: const InputDecoration(
                            labelText: 'To City',
                            prefixIcon: Icon(Icons.flight_land),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 20),

                        /// 🔹 Dates
                        Row(
                          children: [
                            Expanded(
                              child: _DateTile(
                                label: 'Departure',
                                date: departureDate,
                                onTap: () => _pickDate(true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateTile(
                                label: 'Arrival',
                                date: arrivalDate,
                                onTap: () => _pickDate(false),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: weightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Available Weight (kg)',
                            prefixIcon: Icon(Icons.inventory_2),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price per kg',
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// 🔹 CTA
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: state.loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                            ),
                            child: state.loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Publish Trip',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Date Tile Widget
class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              date == null
                  ? 'Select date'
                  : date!.toLocal().toString().split(' ')[0],
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
