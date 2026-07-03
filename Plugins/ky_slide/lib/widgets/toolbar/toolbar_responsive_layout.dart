import 'package:flutter/material.dart';

typedef ToolbarGroupBuilder =
    Widget Function(BuildContext context, bool compact);

typedef ToolbarTrailingGroupsBuilder =
    List<Widget> Function(BuildContext context, bool compact);

class ToolbarResponsiveLayout extends StatelessWidget {
  final ToolbarGroupBuilder leadingGroup;
  final ToolbarTrailingGroupsBuilder trailingGroups;
  final double compactBreakpoint;
  final double compactGroupGap;

  const ToolbarResponsiveLayout({
    super.key,
    required this.leadingGroup,
    required this.trailingGroups,
    this.compactBreakpoint = 920,
    this.compactGroupGap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < compactBreakpoint;
        final row = Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            leadingGroup(context, compact),
            if (compact) SizedBox(width: compactGroupGap) else const Spacer(),
            ...trailingGroups(context, compact),
          ],
        );

        if (!compact) return row;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: row,
        );
      },
    );
  }
}
