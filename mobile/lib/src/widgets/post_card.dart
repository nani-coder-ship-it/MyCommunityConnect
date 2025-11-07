import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post['userName'] ?? 'Resident',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(post['message'] ?? ''),
          ],
        ),
      ),
    );
  }
}
