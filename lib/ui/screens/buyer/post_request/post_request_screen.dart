import 'package:carrygo/ui/screens/buyer/matching/buyer_trip_filter_provider.dart';
import 'package:carrygo/ui/screens/buyer/matching/matching_trips_provider.dart';
import 'package:carrygo/ui/screens/buyer/models/fetch_request_input.dart';
import 'package:carrygo/ui/screens/trip/airport/airport_field.dart';
import 'package:carrygo/ui/screens/trip/airport/airport_model.dart';
import 'package:carrygo/ui/screens/trip/airport/airport_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fetch_request_model.dart';
import 'post_request_provider.dart';

// final airportProvider = FutureProvider<List<Airport>>((ref) async {
//   return AirportRepository.loadAirports();
// });

class PostRequestScreen extends ConsumerStatefulWidget {
  const PostRequestScreen({super.key});

  @override
  ConsumerState<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends ConsumerState<PostRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fromCity = TextEditingController();
  final _toCity = TextEditingController();
  final _item = TextEditingController();
  final _weight = TextEditingController();
  final _qty = TextEditingController();
  final _budget = TextEditingController();

  DateTime? _deadline;

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(postRequestProvider);
    //final airportsAsync = ref.watch(airportProvider);

    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(
              title: 'Item Details',
              subtitle: 'What do you want to send?',
            ),
            _Card(
              children: [
                _field(_item, 'Item Name', icon: Icons.inventory_2_outlined),
                _field(
                  _weight,
                  'Weight (kg)',
                  number: true,
                  icon: Icons.scale_outlined,
                ),
                _field(
                  _qty,
                  'Quantity',
                  number: true,
                  icon: Icons.confirmation_number_outlined,
                ),
              ],
            ),

            const SizedBox(height: 20),

            _SectionTitle(title: 'Route', subtitle: 'Where should it go?'),
            _Card(
              children: [
                // airportField(
                //   controller: _fromCity,
                //   label: 'From Airport',
                //   icon: Icons.flight_takeoff_outlined,
                // ),
                // airportField(
                //   controller: _toCity,
                //   label: 'To Airport',
                //   icon: Icons.flight_land_outlined,
                // ),
                _field(
                  _fromCity,
                  'From City',
                  icon: Icons.flight_takeoff_outlined,
                ),
                _field(_toCity, 'To City', icon: Icons.flight_land_outlined),
              ],
            ),

            const SizedBox(height: 20),

            _SectionTitle(
              title: 'Budget & Deadline',
              subtitle: 'Pricing and delivery date',
            ),
            _Card(
              children: [
                _field(
                  _budget,
                  'Budget',
                  number: true,
                  icon: Icons.currency_rupee,
                ),
                _DeadlinePicker(
                  date: _deadline,
                  onTap: () async {
                    _deadline = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      initialDate: DateTime.now(),
                    );
                    setState(() {});
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate() ||
                          _deadline == null)
                        return;

                      final model = FetchRequestInput(
                        fromCity: _fromCity.text.trim(),
                        toCity: _toCity.text.trim(),
                        itemName: _item.text.trim(),
                        weight: double.parse(_weight.text),
                        quantity: int.parse(_qty.text),
                        budget: double.parse(_budget.text),
                        deadline: _deadline!,
                      );

                      await ref
                          .read(postRequestProvider.notifier)
                          .submit(model);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request Posted Successfully'),
                        ),
                      );
                    },
              child: loading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    )
                  : const Text(
                      'Post Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool number = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (v) => v!.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: children),
      ),
    );
  }
}

class _DeadlinePicker extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DeadlinePicker({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(
        date == null
            ? 'Select Delivery Deadline'
            : '${date!.day}/${date!.month}/${date!.year}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
