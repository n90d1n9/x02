import 'package:flutter/material.dart';

class SidebarResultSummary extends StatelessWidget {
  final int count;
  final bool isFiltered;
  final String singularLabel;
  final String pluralLabel;

  const SidebarResultSummary({
    super.key,
    required this.count,
    required this.isFiltered,
    required this.singularLabel,
    required this.pluralLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = isFiltered
        ? count == 1
              ? 'match'
              : 'matches'
        : count == 1
        ? singularLabel
        : pluralLabel;

    return SizedBox(
      width: double.infinity,
      height: 18,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count $label',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
