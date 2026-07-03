import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Empty result state for command searches with no matches.
class CommandPaletteEmptyState extends StatelessWidget {
  final String query;
  final Color accentColor;
  final VoidCallback? onClearQuery;

  const CommandPaletteEmptyState({
    super.key,
    this.query = '',
    this.accentColor = const Color(0xFF38BDF8),
    this.onClearQuery,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final hasQuery = normalizedQuery.isNotEmpty;

    return SizedBox(
      height: 170,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: Colors.white30, size: 30),
            const SizedBox(height: 10),
            const Text(
              'No commands found',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'No matches for "$normalizedQuery"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (hasQuery && onClearQuery != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onPressed: onClearQuery,
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Clear'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Command palette empty state', size: Size(420, 220))
Widget commandPaletteEmptyStatePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: CommandPaletteEmptyState(
          query: 'timeline export',
          accentColor: const Color(0xFF38BDF8),
          onClearQuery: () {},
        ),
      ),
    ),
  );
}
