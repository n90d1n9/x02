import '../../models/document_editing_mode.dart';

/// Provides compact status-bar labels for the active document editing mode.
class DocumentEditingModeStatusDetails {
  final DocumentEditingMode mode;

  const DocumentEditingModeStatusDetails(this.mode);

  String get modeLabel => mode.label;

  String get description => mode.description;

  String get editingAccessLabel {
    return switch (mode) {
      DocumentEditingMode.editing => 'Direct edits',
      DocumentEditingMode.suggesting => 'Review suggestions',
      DocumentEditingMode.viewing => 'Locked',
    };
  }

  String get toolbarLabel {
    if (mode.showsFormattingToolbar) return 'Available';
    return 'Hidden';
  }

  String get workspaceBannerLabel {
    if (mode.showsWorkspaceBanner) return 'Visible';
    return 'Hidden';
  }

  String get readOnlyLabel {
    if (mode.isReadOnly) return 'On';
    return 'Off';
  }
}
