import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text(request['title'] ?? ''),
        subtitle: Text(request['status'] ?? 'Open'),
      ),
    );
  }
}
