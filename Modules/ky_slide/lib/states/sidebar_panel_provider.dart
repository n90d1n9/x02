import 'package:flutter_riverpod/legacy.dart';

import '../models/component_layer_filter.dart';
import '../models/sidebar_menu_item.dart';
import '../models/sidebar_section_id.dart';
import '../models/slide_navigator_density.dart';
import '../models/slide_template.dart';

final activeSidebarMenuProvider = StateProvider<SidebarMenuItem>((ref) {
  return SidebarMenuItem.slides;
});

final sidebarSectionExpandedProvider =
    StateProvider.family<bool, SidebarSectionId>((ref, sectionId) {
      return sectionId.initiallyExpanded;
    });

final outlineSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final designAssistSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final designAssistCategoryProvider = StateProvider<SlideTemplateCategory?>((
  ref,
) {
  return null;
});

final slideSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final slideNavigatorDensityProvider = StateProvider<SlideNavigatorDensity>((
  ref,
) {
  return SlideNavigatorDensity.comfortable;
});

final layerSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final layerFilterProvider = StateProvider<ComponentLayerFilter>((ref) {
  return ComponentLayerFilter.all;
});
