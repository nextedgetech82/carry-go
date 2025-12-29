import 'package:carrygo/ui/screens/trip/airport/airport_repository.dart';
import 'package:flutter/material.dart';
import 'airport_model.dart';

Widget airportField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required void Function(Airport airport) onSelected,
}) {
  return Autocomplete<Airport>(
    displayStringForOption: (a) => '${a.city} (${a.code})',

    /// 🔍 NOW SEARCHES LOCAL + FIREBASE CACHE
    optionsBuilder: (TextEditingValue text) {
      final query = text.text.trim().toLowerCase();
      if (query.length < 2) {
        return const Iterable<Airport>.empty();
      }
      return AirportRepo.search(query).take(15);
    },

    onSelected: (airport) {
      controller.text = '${airport.city} (${airport.code})';
      onSelected(airport);
    },

    fieldViewBuilder: (context, textCtrl, focusNode, _) {
      return TextFormField(
        controller: textCtrl,
        focusNode: focusNode,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
