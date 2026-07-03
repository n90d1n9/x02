import 'package:flutter/material.dart';

enum SheetRibbonTab { home, insert, data, formulas, view, review }

class SheetRibbonTabSpec {
  const SheetRibbonTabSpec({
    required this.tab,
    required this.label,
    required this.icon,
  });

  final SheetRibbonTab tab;
  final String label;
  final IconData icon;
}

class SheetRibbonTabCatalog {
  const SheetRibbonTabCatalog._();

  static const all = [
    SheetRibbonTabSpec(
      tab: SheetRibbonTab.home,
      label: 'Home',
      icon: Icons.home_outlined,
    ),
    SheetRibbonTabSpec(
      tab: SheetRibbonTab.insert,
      label: 'Insert',
      icon: Icons.add_box_outlined,
    ),
    SheetRibbonTabSpec(
      tab: SheetRibbonTab.data,
      label: 'Data',
      icon: Icons.filter_alt_outlined,
    ),
    SheetRibbonTabSpec(
      tab: SheetRibbonTab.formulas,
      label: 'Formulas',
      icon: Icons.functions,
    ),
    SheetRibbonTabSpec(
      tab: SheetRibbonTab.view,
      label: 'View',
      icon: Icons.visibility_outlined,
    ),
    SheetRibbonTabSpec(
      tab: SheetRibbonTab.review,
      label: 'Review',
      icon: Icons.rate_review_outlined,
    ),
  ];
}
