import 'package:flutter/material.dart';

import '../../models/document_stats.dart';

class DocumentInfoDialog extends StatelessWidget {
  final DocumentStats stats;

  const DocumentInfoDialog({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Document Statistics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Words', stats.words.toString()),
          _buildInfoRow('Characters', stats.characters.toString()),
          _buildInfoRow(
            'Characters (no spaces)',
            stats.charactersNoSpaces.toString(),
          ),
          _buildInfoRow('Paragraphs', stats.paragraphs.toString()),
          _buildInfoRow('Reading time', '${stats.readingTime} min'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
