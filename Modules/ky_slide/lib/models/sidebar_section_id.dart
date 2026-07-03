enum SidebarSectionId {
  designAssist(initiallyExpanded: true),
  outline(initiallyExpanded: true);

  const SidebarSectionId({required this.initiallyExpanded});

  final bool initiallyExpanded;
}
