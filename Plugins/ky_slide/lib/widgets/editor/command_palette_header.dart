import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Header row for command palette identity and close action.
class CommandPaletteHeader extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onClose;

  const CommandPaletteHeader({
    super.key,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.manage_search, color: accentColor, size: 19),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Command Palette',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close command palette',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Command palette header', size: Size(520, 100))
Widget commandPaletteHeaderPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 460,
          child: CommandPaletteHeader(
            accentColor: const Color(0xFF38BDF8),
            onClose: () {},
          ),
        ),
      ),
    ),
  );
}
