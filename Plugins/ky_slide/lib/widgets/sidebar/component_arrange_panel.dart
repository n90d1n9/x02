import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component_arrange_action.dart';
import '../../models/presentation.dart';
import '../../models/presentation_component.dart';
import '../../services/selection_identity_service.dart';
import '../../states/component_layer_actions_provider.dart';
import '../../states/component_provider.dart';
import '../../states/presentation_provider.dart';
import 'sidebar_command_grid.dart';
import 'sidebar_empty_state.dart';
import 'sidebar_section.dart';

/// Sidebar panel for precise selected-object alignment and layer ordering.
class ComponentArrangePanel extends ConsumerWidget {
  static const SelectionIdentityService _selectionIdentityService =
      SelectionIdentityService();

  const ComponentArrangePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final selectedId = ref.watch(selectedComponentProvider);
    final component = _selectedComponent(presentation, selectedId);
    final accentColor = presentation.theme.primaryColor;
    final secondaryColor = presentation.theme.secondaryColor;
    final actions = ref.read(componentLayerActionsProvider);
    final canArrange = component != null && !component.isLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SidebarSection(
          title: 'Arrange',
          subtitle: component == null
              ? 'Select an object to align, rotate, or layer it.'
              : 'Precise controls for the selected object.',
          icon: Icons.center_focus_strong,
          gradientColors: [accentColor, secondaryColor],
          child: component == null
              ? const SidebarEmptyState(message: 'No object selected')
              : _SelectedArrangeSummary(
                  component: component,
                  accentColor: accentColor,
                ),
        ),
        SidebarSection(
          title: 'Align',
          subtitle: canArrange
              ? 'Align the object to the slide bounds.'
              : 'Unlock the object to align it.',
          icon: Icons.align_horizontal_center,
          gradientColors: [accentColor, const Color(0xFF38BDF8)],
          child: SidebarCommandGrid(
            accentColor: accentColor,
            columns: 2,
            items: [
              _command(
                icon: Icons.format_align_left,
                label: 'Left',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.alignLeft,
                  );
                },
              ),
              _command(
                icon: Icons.format_align_center,
                label: 'Center',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.alignHorizontalCenter,
                  );
                },
              ),
              _command(
                icon: Icons.format_align_right,
                label: 'Right',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.alignRight,
                  );
                },
              ),
              _command(
                icon: Icons.vertical_align_top,
                label: 'Top',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(ComponentArrangeAction.alignTop);
                },
              ),
              _command(
                icon: Icons.vertical_align_center,
                label: 'Middle',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.alignVerticalCenter,
                  );
                },
              ),
              _command(
                icon: Icons.vertical_align_bottom,
                label: 'Bottom',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.alignBottom,
                  );
                },
              ),
            ],
          ),
        ),
        SidebarSection(
          title: 'Position',
          subtitle: 'Center, snap, or rotate without opening the inspector.',
          icon: Icons.open_with,
          gradientColors: [secondaryColor, const Color(0xFF22C55E)],
          child: SidebarCommandGrid(
            accentColor: secondaryColor,
            columns: 2,
            items: [
              _command(
                icon: Icons.center_focus_strong,
                label: 'Center slide',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.centerOnSlide,
                  );
                },
              ),
              _command(
                icon: Icons.grid_on,
                label: 'Snap grid',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.snapToGrid,
                  );
                },
              ),
              _command(
                icon: Icons.rotate_left,
                label: 'Rotate left',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.rotateLeft,
                  );
                },
              ),
              _command(
                icon: Icons.rotate_right,
                label: 'Rotate right',
                enabled: canArrange,
                onPressed: () {
                  actions.arrangeSelectedLayer(
                    ComponentArrangeAction.rotateRight,
                  );
                },
              ),
            ],
          ),
        ),
        SidebarSection(
          title: 'Layer Order',
          subtitle: 'Move the selected object through the visual stack.',
          icon: Icons.layers_outlined,
          gradientColors: [const Color(0xFFF59E0B), accentColor],
          child: SidebarCommandGrid(
            accentColor: const Color(0xFFF59E0B),
            columns: 2,
            items: [
              _command(
                icon: Icons.flip_to_front,
                label: 'To front',
                enabled: component != null,
                onPressed: actions.bringSelectedLayerToFront,
              ),
              _command(
                icon: Icons.arrow_upward,
                label: 'Forward',
                enabled: component != null,
                onPressed: actions.moveSelectedLayerForward,
              ),
              _command(
                icon: Icons.arrow_downward,
                label: 'Backward',
                enabled: component != null,
                onPressed: actions.moveSelectedLayerBackward,
              ),
              _command(
                icon: Icons.flip_to_back,
                label: 'To back',
                enabled: component != null,
                onPressed: actions.sendSelectedLayerToBack,
              ),
            ],
          ),
        ),
      ],
    );
  }

  SidebarCommandGridItem _command({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SidebarCommandGridItem(
      icon: icon,
      label: label,
      isEnabled: enabled,
      onPressed: onPressed,
    );
  }

  PresentationComponent? _selectedComponent(
    Presentation presentation,
    String? selectedId,
  ) {
    if (selectedId == null) return null;

    final slide = presentation.slides[presentation.currentSlideIndex];
    for (final component in slide.components) {
      if (component.id == selectedId) return component;
    }

    return null;
  }
}

/// Compact selected-object geometry summary for the arrange sidebar.
class _SelectedArrangeSummary extends StatelessWidget {
  final PresentationComponent component;
  final Color accentColor;

  const _SelectedArrangeSummary({
    required this.component,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final identity = ComponentArrangePanel._selectionIdentityService
        .identityFor(component);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            identity.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SummaryPill(identity.typeLabel),
              _SummaryPill(identity.stateLabel),
              _SummaryPill(_sizeLabel(component)),
              _SummaryPill('${component.rotation.round()} deg'),
            ],
          ),
        ],
      ),
    );
  }

  String _sizeLabel(PresentationComponent component) {
    return '${component.size.width.round()} x ${component.size.height.round()}';
  }
}

/// Small metadata chip used in the arrange panel selected-object summary.
class _SummaryPill extends StatelessWidget {
  final String label;

  const _SummaryPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

@Preview(name: 'Component arrange panel', size: Size(320, 620))
Widget componentArrangePanelPreview() {
  return const ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: SingleChildScrollView(
          child: SizedBox(width: 320, child: ComponentArrangePanel()),
        ),
      ),
    ),
  );
}
