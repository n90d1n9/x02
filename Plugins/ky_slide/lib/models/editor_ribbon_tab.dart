/// Top-level ribbon tabs shown by the presentation editor toolbar.
enum EditorRibbonTab { home, insert, design, view, format }

/// Presentation labels and visibility rules for editor ribbon tabs.
extension EditorRibbonTabLabel on EditorRibbonTab {
  String get label {
    return switch (this) {
      EditorRibbonTab.home => 'Home',
      EditorRibbonTab.insert => 'Insert',
      EditorRibbonTab.design => 'Design',
      EditorRibbonTab.view => 'View',
      EditorRibbonTab.format => 'Format',
    };
  }

  bool get isContextual {
    return switch (this) {
      EditorRibbonTab.format => true,
      _ => false,
    };
  }

  static List<EditorRibbonTab> visibleTabs({required bool hasSelection}) {
    return [
      EditorRibbonTab.home,
      EditorRibbonTab.insert,
      EditorRibbonTab.design,
      EditorRibbonTab.view,
      if (hasSelection) EditorRibbonTab.format,
    ];
  }
}
