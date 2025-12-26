import 'package:carrygo/ui/screens/trip/airport/airport_model.dart';
import 'package:carrygo/ui/screens/trip/airport/airport_repository.dart';
import 'package:flutter/material.dart';

Widget airportField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
}) {
  return Autocomplete<Airport>(
    displayStringForOption: (a) => '${a.city} (${a.code})',

    optionsBuilder: (TextEditingValue text) async {
      if (text.text.length < 3) {
        return const Iterable<Airport>.empty();
      }
      return await AirportRepository.search(text.text);
    },

    onSelected: (airport) {
      controller.text = '${airport.city} (${airport.code})';
    },

    fieldViewBuilder: (context, textCtrl, focusNode, _) {
      return TextFormField(
        controller: textCtrl,
        focusNode: focusNode,
        validator: (v) => v!.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    },

    optionsViewBuilder: (context, onSelected, options) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: options.length,
          itemBuilder: (_, i) {
            final a = options.elementAt(i);
            return ListTile(
              leading: const Icon(Icons.flight),
              title: Text('${a.city} (${a.code})'),
              subtitle: Text('${a.airport}, ${a.country}'),
              onTap: () => onSelected(a),
            );
          },
        ),
      );
    },
  );
}
