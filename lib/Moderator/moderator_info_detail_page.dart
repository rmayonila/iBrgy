import 'package:flutter/material.dart';

class ModeratorInfoDetailPage extends StatelessWidget {
  final Map<String, String> info;
  const ModeratorInfoDetailPage({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final title = info['title'] ?? 'Details';
    final category = info['category'] ?? '';
    final updated = info['lastUpdated'] ?? '';
    final description = info['description'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  category,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (updated.isNotEmpty)
              Text(
                'Updated $updated',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            const SizedBox(height: 16),
            if (description.isNotEmpty)
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.6,
                ),
              )
            else
              Text(
                'No additional details available.',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
