import 'package:flutter/material.dart';

class RequestTimeline extends StatelessWidget {
  final String status;

  const RequestTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Step(title: 'Request Sent', done: true),
        _Divider(),
        _Step(
          title: 'Accepted by Traveller',
          done: status == 'accepted' || status == 'completed',
          error: status == 'rejected',
        ),
        _Divider(),
        _Step(title: 'Purchased by Traveller', done: status == 'purchased'),
        _Divider(),
        _Step(title: 'In Transit', done: status == 'in_transit'),
        _Divider(),
        _Step(title: 'Delivered', done: status == 'delivered'),
        _Divider(),
        _Step(title: 'Trip Completed', done: status == 'completed'),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String title;
  final bool done;
  final bool error;

  const _Step({required this.title, this.done = false, this.error = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (error) {
      color = Colors.red;
      icon = Icons.close;
    } else if (done) {
      color = Colors.green;
      icon = Icons.check;
    } else {
      color = Colors.grey;
      icon = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Container(height: 24, width: 2, color: Colors.grey.shade300),
    );
  }
}
