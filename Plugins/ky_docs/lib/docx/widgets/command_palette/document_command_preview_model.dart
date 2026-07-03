import 'document_command.dart';

/// Builds the focused command summary shown below palette results.
class DocumentCommandPreviewModel {
  final DocumentCommand command;

  const DocumentCommandPreviewModel({required this.command});

  bool get isEnabled => command.enabled;

  String get categoryLabel {
    final category = command.category.trim();
    return category.isEmpty ? 'General' : category;
  }

  String get statusLabel {
    if (isEnabled) return 'Ready';
    final disabledLabel = command.disabledLabel?.trim();
    if (disabledLabel != null && disabledLabel.isNotEmpty) {
      return disabledLabel;
    }
    return 'Unavailable';
  }

  String get statusDescription {
    if (isEnabled) return 'Runs from $categoryLabel commands.';
    final disabledReason = command.disabledReason?.trim();
    if (disabledReason != null && disabledReason.isNotEmpty) {
      return disabledReason;
    }
    return 'This command is not available right now.';
  }

  String? get shortcutLabel {
    final shortcut = command.shortcut?.trim();
    if (shortcut == null || shortcut.isEmpty) return null;
    return shortcut;
  }
}
