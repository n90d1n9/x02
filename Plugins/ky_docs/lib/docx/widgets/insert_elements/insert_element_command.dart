import 'package:flutter/material.dart';

/// Identifies an insert command shown in the document insert hub.
enum InsertElementCommandId {
  table,
  chart,
  image,
  drawing,
  footnote,
  rectangle,
  circle,
  triangle,
  star,
}

/// Describes one insert action that can be rendered by the insert hub.
class InsertElementCommand {
  final InsertElementCommandId id;
  final IconData icon;
  final String label;

  const InsertElementCommand({
    required this.id,
    required this.icon,
    required this.label,
  });
}

/// Groups related insert commands for a scannable document editor surface.
class InsertElementCommandGroup {
  final String title;
  final IconData icon;
  final List<InsertElementCommand> commands;

  const InsertElementCommandGroup({
    required this.title,
    required this.icon,
    required this.commands,
  });
}

/// Provides the default insert command groups for the document editor.
class InsertElementCommandCatalog {
  const InsertElementCommandCatalog._();

  static const groups = [
    InsertElementCommandGroup(
      title: 'Content',
      icon: Icons.dashboard_customize_outlined,
      commands: [
        InsertElementCommand(
          id: InsertElementCommandId.table,
          icon: Icons.table_chart_outlined,
          label: 'Table',
        ),
        InsertElementCommand(
          id: InsertElementCommandId.chart,
          icon: Icons.bar_chart_outlined,
          label: 'Chart',
        ),
      ],
    ),
    InsertElementCommandGroup(
      title: 'Media',
      icon: Icons.perm_media_outlined,
      commands: [
        InsertElementCommand(
          id: InsertElementCommandId.image,
          icon: Icons.image_outlined,
          label: 'Image',
        ),
        InsertElementCommand(
          id: InsertElementCommandId.drawing,
          icon: Icons.draw_outlined,
          label: 'Drawing',
        ),
      ],
    ),
    InsertElementCommandGroup(
      title: 'References',
      icon: Icons.notes_outlined,
      commands: [
        InsertElementCommand(
          id: InsertElementCommandId.footnote,
          icon: Icons.format_list_numbered_outlined,
          label: 'Footnote',
        ),
      ],
    ),
    InsertElementCommandGroup(
      title: 'Shapes',
      icon: Icons.category_outlined,
      commands: [
        InsertElementCommand(
          id: InsertElementCommandId.rectangle,
          icon: Icons.rectangle_outlined,
          label: 'Rectangle',
        ),
        InsertElementCommand(
          id: InsertElementCommandId.circle,
          icon: Icons.circle_outlined,
          label: 'Circle',
        ),
        InsertElementCommand(
          id: InsertElementCommandId.triangle,
          icon: Icons.change_history,
          label: 'Triangle',
        ),
        InsertElementCommand(
          id: InsertElementCommandId.star,
          icon: Icons.star_border,
          label: 'Star',
        ),
      ],
    ),
  ];
}
