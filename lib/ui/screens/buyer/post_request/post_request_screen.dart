import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fetch_request_model.dart';
import 'post_request_provider.dart';

class PostRequestScreen extends ConsumerStatefulWidget {
  const PostRequestScreen({super.key});

  @override
  ConsumerState<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends ConsumerState<PostRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _item = TextEditingController();
  final _weight = TextEditingController();
  final _qty = TextEditingController();
  final _budget = TextEditingController();
  DateTime? _deadline;

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(postRequestProvider);

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _field(_item, 'Item Name'),
          _field(_weight, 'Weight (kg)', number: true),
          _field(_qty, 'Quantity', number: true),
          _field(_budget, 'Budget', number: true),
          ListTile(
            title: Text(
              _deadline == null
                  ? 'Select Deadline'
                  : _deadline!.toLocal().toString().split(' ')[0],
            ),
            trailing: const Icon(Icons.calendar_today),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate() || _deadline == null)
                      return;

                    await ref
                        .read(postRequestProvider.notifier)
                        .submit(
                          FetchRequestModel(
                            itemName: _item.text,
                            weight: double.parse(_weight.text),
                            quantity: int.parse(_qty.text),
                            budget: double.parse(_budget.text),
                            deadline: _deadline!,
                          ),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request Posted')),
                    );
                  },
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Post Request'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (v) => v!.isEmpty ? 'Required' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
