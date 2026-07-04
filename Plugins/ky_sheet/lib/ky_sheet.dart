/// KySheet - A professional spreadsheet application for Flutter.
/// 
/// This library provides a complete spreadsheet solution with:
/// - Full-featured grid with cell editing and formatting
/// - Formula engine with support for common functions
/// - Charting and visualization capabilities
/// - File import/export (Excel, CSV)
/// - Undo/Redo support
/// - Real-time collaboration (optional)
/// 
/// ## Architecture
/// 
/// The codebase follows clean architecture principles:
/// - **Core**: Business logic, commands, events, services
/// - **Features**: UI components organized by feature (file_menu, grid, toolbar, etc.)
/// - **Shared**: Reusable widgets and utilities
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:ky_sheet/ky_sheet.dart';
/// 
/// void main() {
///   runApp(KySheetApp());
/// }
/// ```
library ky_sheet;

// ============================================
// CORE ENGINE - New modular architecture
// ============================================
export 'src/core/core.dart';
export 'src/shared/shared.dart';

// ============================================
// LEGACY EXPORTS - Being refactored
// TODO: Migrate these to the new modular structure
// ============================================

// Models
export 'model/border_style.dart';
export 'model/cell/cell_address.dart';
export 'model/cell/cell_data.dart';
export 'model/cell/cell_selection.dart';
export 'model/cell/cell_style.dart';
export 'model/cell/cell_validation.dart';
export 'model/column_config.dart';
export 'model/conditional_format_rule.dart';
export 'model/conditional_formatting_rule.dart';
export 'model/number_format.dart';
export 'model/row_config.dart';
export 'model/sheet_chart.dart';
export 'model/sheet_named_range.dart';
export 'model/sheet_pivot_table.dart';
export 'model/sheet_table.dart';
export 'model/workbook_sheet.dart';

// Services
export 'service/conditional_formatting_manager.dart';
export 'service/pivot_table_manager.dart';
export 'service/sheet_formula_engine.dart';
export 'service/sheet_formula_functions.dart';

// Widgets - Core Grid
export 'widget/spreadsheet_grid.dart';
export 'widget/spreadsheet_cell.dart';
export 'widget/sheet_view_panel.dart';

// Widgets - Toolbar & Menus
export 'widget/toolbar_widget.dart';
export 'widget/tool_button.dart';
export 'widget/tool_popup_button.dart';

// Widgets - Sheet Navigation
export 'widget/sheet_tabs_bar.dart';
export 'widget/sheet_tab.dart';

// Widgets - Status Bar
export 'widget/status_bar.dart';

// Screens
export 'screen/spreadsheet_screen.dart';

// Office Integration
export 'office_product.dart';
export 'state/sheet_chart_provider.dart';
export 'state/sheet_command_palette_provider.dart';
export 'state/sheet_active_table_provider.dart';
export 'state/sheet_format_painter_provider.dart';
export 'state/sheet_find_replace_provider.dart';
export 'state/sheet_formula_health_focus_provider.dart';
export 'state/sheet_formula_health_filter_provider.dart';
export 'state/sheet_formula_health_search_provider.dart';
export 'state/sheet_formula_health_sort_provider.dart';
export 'state/sheet_formula_preview_provider.dart';
export 'state/sheet_engine_operation_provider.dart';
export 'state/sheet_navigation_provider.dart';
export 'state/sheet_named_range_provider.dart';
export 'state/sheet_recent_sheet_provider.dart';
export 'state/sheet_sidebar_provider.dart';
export 'state/sheet_table_provider.dart';
export 'state/sheet_viewport_provider.dart';
export 'state/spreadsheet_provider.dart';
export 'state/toolbar_provider.dart';
export 'state/workbook_provider.dart';
export 'theme/ky_sheet_theme.dart';
export 'utils/sheet_cleanup_engine.dart';
export 'utils/sheet_cell_quick_filter_rule_builder.dart';
export 'utils/sheet_command_catalog.dart';
export 'utils/sheet_clipboard_codec.dart';
export 'utils/sheet_cell_formatter.dart';
export 'utils/sheet_chart_data_builder.dart';
export 'utils/sheet_conditional_format_evaluator.dart';
export 'utils/sheet_data_profiler.dart';
export 'utils/sheet_column_filter_summary_builder.dart';
export 'utils/sheet_column_filter_value_builder.dart';
export 'utils/sheet_filter_evaluator.dart';
export 'utils/sheet_fill_series.dart';
export 'utils/sheet_find_replace_engine.dart';
export 'utils/sheet_freeze_pane_layout.dart';
export 'utils/sheet_formula_auditor.dart';
export 'utils/sheet_formula_autocomplete.dart';
export 'utils/sheet_formula_error_status.dart';
export 'utils/sheet_formula_health_filter.dart';
export 'utils/sheet_formula_health_scanner.dart';
export 'utils/sheet_formula_issue_focus.dart';
export 'utils/sheet_formula_issue_guidance.dart';
export 'utils/sheet_formula_issue_report_builder.dart';
export 'utils/sheet_formula_issue_sorter.dart';
export 'utils/sheet_formula_issue_trace_builder.dart';
export 'utils/sheet_formula_reference.dart';
export 'utils/sheet_formula_trace_builder.dart';
export 'utils/sheet_function_insert_builder.dart';
export 'utils/sheet_go_to_special_scanner.dart';
export 'utils/sheet_history_summarizer.dart';
export 'utils/sheet_range_parser.dart';
export 'utils/sheet_review_scanner.dart';
export 'utils/sheet_shortcut_catalog.dart';
export 'utils/sheet_table_append_effect_summary_builder.dart';
export 'utils/sheet_table_badge_resolver.dart';
export 'utils/sheet_table_calculated_column_summary_builder.dart';
export 'utils/sheet_table_cell_template_builder.dart';
export 'utils/sheet_table_column_append_builder.dart';
export 'utils/sheet_table_corner_action_resolver.dart';
export 'utils/sheet_table_data_row_append_builder.dart';
export 'utils/sheet_table_filter_impact_label_builder.dart';
export 'utils/sheet_table_filter_summary_builder.dart';
export 'utils/sheet_table_filter_visibility_summary_builder.dart';
export 'utils/sheet_table_header_action_tooltip_builder.dart';
export 'utils/sheet_table_header_name_validator.dart';
export 'utils/sheet_table_outline_resolver.dart';
export 'utils/sheet_table_total_autofill_builder.dart';
export 'utils/sheet_table_style_resolver.dart';
export 'utils/sheet_table_range_resolver.dart';
export 'utils/sheet_table_total_formula_builder.dart';
export 'utils/sheet_table_total_label_builder.dart';
export 'utils/sheet_table_total_suggestion_builder.dart';
export 'utils/sheet_engine_codec.dart';
export 'utils/sheet_engine_edit_codec.dart';
export 'utils/sheet_engine_operation_diff.dart';
export 'utils/sheet_engine_operation_payload_parser.dart';
export 'utils/sheet_engine_operation_replayer.dart';
export 'utils/sheet_validation_status.dart';
export 'utils/sheet_viewport_metrics.dart';
export 'utils/sheet_workbook_codec.dart';

// Core enhanced engines for Excel-like functionality
export 'core/core.dart';

export 'widget/color_button.dart';
export 'widget/conditional_format_panel.dart';
export 'widget/conditional_formatting_dialog.dart';
export 'widget/formula_bar.dart';
export 'widget/formula_suggestion_panel.dart';
export 'widget/inline_cell_editor.dart';
export 'widget/pivot_table_dialog.dart';
export 'widget/quick_action_sheet.dart';
export 'widget/search_dialog.dart';
export 'widget/sheet_cell_context_menu.dart';
export 'widget/sheet_cell_inspector_panel.dart';
export 'widget/sheet_cell_metadata_badges.dart';
export 'widget/sheet_chart_builder_panel.dart';
export 'widget/sheet_chart_preview.dart';
export 'widget/sheet_column_filter_dialog.dart';
export 'widget/sheet_column_filter_quick_actions.dart';
export 'widget/sheet_column_filter_state_summary.dart';
export 'widget/sheet_column_header_menu_button.dart';
export 'widget/sheet_command_palette_dialog.dart';
export 'widget/sheet_data_cleanup_panel.dart';
export 'widget/sheet_data_insights_panel.dart';
export 'widget/sheet_data_validation_panel.dart';
export 'widget/sheet_delete_sheet_dialog.dart';
export 'widget/sheet_engine_operation_import_dialog.dart';
export 'widget/sheet_engine_operation_panel.dart';
export 'widget/sheet_file_menu.dart';
export 'widget/sheet_filter_rule_editor.dart';
export 'widget/sheet_filter_value_checklist.dart';
export 'widget/sheet_find_replace_panel.dart';
export 'widget/sheet_formula_audit_panel.dart';
export 'widget/sheet_formula_bar_actions.dart';
export 'widget/sheet_formula_health_panel.dart';
export 'widget/sheet_formula_issue_code_badge.dart';
export 'widget/sheet_formula_issue_detail_card.dart';
export 'widget/sheet_formula_issue_filter_bar.dart';
export 'widget/sheet_formula_issue_search_field.dart';
export 'widget/sheet_formula_issue_sort_control.dart';
export 'widget/sheet_formula_issue_view_summary.dart';
export 'widget/sheet_function_library_panel.dart';
export 'widget/sheet_go_to_special_panel.dart';
export 'widget/sheet_headers.dart';
export 'widget/sheet_hidden_sheet_row.dart';
export 'widget/sheet_history_panel.dart';
export 'widget/sheet_menu_section_label.dart';
export 'widget/sheet_name_box.dart';
export 'widget/sheet_named_ranges_panel.dart';
export 'widget/sheet_navigator_dialog.dart';
export 'widget/sheet_performance_panel.dart';
export 'widget/sheet_rename_dialog.dart';
export 'widget/sheet_review_panel.dart';
export 'widget/sheet_ribbon_command_row.dart';
export 'widget/sheet_ribbon_conditional_formatting_group.dart';
export 'widget/sheet_ribbon_context_bar.dart';
export 'widget/sheet_ribbon_data_group.dart';
export 'widget/sheet_ribbon_density.dart';
export 'widget/sheet_ribbon_formula_group.dart';
export 'widget/sheet_ribbon_group.dart';
export 'widget/sheet_ribbon_home_groups.dart';
export 'widget/sheet_ribbon_menu_button.dart';
export 'widget/sheet_ribbon_overflow_scroller.dart';
export 'widget/sheet_ribbon_panel_launcher_group.dart';
export 'widget/sheet_ribbon_review_group.dart';
export 'widget/sheet_ribbon_structure_group.dart';
export 'widget/sheet_ribbon_surface.dart';
export 'widget/sheet_ribbon_tab.dart';
export 'widget/sheet_ribbon_tab_groups.dart';
export 'widget/sheet_ribbon_tab_strip.dart';
export 'widget/sheet_ribbon_validation_dialogs.dart';
export 'widget/sheet_ribbon_view_group.dart';
export 'widget/sheet_selection_mini_toolbar.dart';
export 'widget/sheet_shortcut_category_filter.dart';
export 'widget/sheet_shortcut_hint.dart';
export 'widget/sheet_shortcuts_panel.dart';
export 'widget/sheet_sidebar.dart';
export 'widget/sheet_sidebar_menu.dart';
export 'widget/sheet_sidebar_panel_surface.dart';
export 'widget/sheet_sidebar_rail.dart';
export 'widget/sheet_tab.dart';
export 'widget/sheet_tab_action_menu.dart';
export 'widget/sheet_tab_color_dialog.dart';
export 'widget/sheet_tab_color_picker.dart';
export 'widget/sheet_tab_inline_rename_field.dart';
export 'widget/sheet_tab_reorder_target.dart';
export 'widget/sheet_table_corner_action_button.dart';
export 'widget/sheet_table_corner_badge.dart';
export 'widget/sheet_table_design_tile.dart';
export 'widget/sheet_table_header_action_button.dart';
export 'widget/sheet_table_header_rename_dialog.dart';
export 'widget/sheet_table_outline_overlay.dart';
export 'widget/sheet_table_total_action_button.dart';
export 'widget/sheet_tables_panel.dart';
export 'widget/sheet_tabs_bar.dart';
export 'widget/sheet_tabs_navigator_button.dart';
export 'widget/sheet_tabs_overflow_scroller.dart';
export 'widget/sheet_validation_dropdown_button.dart';
export 'widget/sheet_view_panel.dart';
export 'widget/sheet_workbook_shortcuts.dart';
export 'widget/sheet_zoom_control.dart';
export 'widget/sort_filter_panel.dart';
export 'widget/spreadsheet_cell.dart';
export 'widget/spreadsheet_grid.dart';
export 'widget/status_bar.dart';
export 'widget/status_metric_chip.dart';
export 'widget/status_metric_row.dart';
export 'widget/status_sheet_switcher_chip.dart';
export 'widget/tenun_chart_widget.dart';
export 'widget/tool_button.dart';
export 'widget/tool_popup_button.dart';
export 'widget/toolbar_widget.dart';
export 'widget/workbook_sheet_menu_item.dart';
