import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/layout_provider.dart';

class CustomToolbar extends ConsumerWidget {
  final quill.QuillController controller;

  const CustomToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRuler = ref.watch(rulerVisibilityProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            quill.QuillToolbarHistoryButton(
              controller: controller,
              isUndo: true,
              options: const quill.QuillToolbarHistoryButtonOptions(),
            ),
            quill.QuillToolbarHistoryButton(
              controller: controller,
              isUndo: false,
              options: const quill.QuillToolbarHistoryButtonOptions(),
            ),

            const VerticalDivider(),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.bold,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),

            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.italic,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.underline,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.strikeThrough,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),
            quill.QuillToolbarFontFamilyButton(controller: controller),
            quill.QuillToolbarFontSizeButton(controller: controller),
            quill.QuillToolbarFontFamilyButton(
              controller: controller,
              options: quill.QuillToolbarFontFamilyButtonOptions(
                tooltip: 'Font Family',
                /*  fontSizes: const {
                  'Default': null,
                  'Arial': 'Arial',
                  'Courier New': 'Courier New',
                  'Georgia': 'Georgia',
                  'Times New Roman': 'Times New Roman',
                  'Verdana': 'Verdana',
                }, */
              ),
            ),
            const SizedBox(width: 8),

            quill.QuillToolbarFontSizeButton(
              controller: controller,
              options: quill.QuillToolbarFontSizeButtonOptions(
                tooltip: 'Font Size',
                /* fontSizes: const {
                  'Default': null,
                  'Small': 'small',
                  'Normal': 'normal', 
                  'Large': 'large',
                  'Huge': 'huge',
                }, */
              ),
            ),
            const VerticalDivider(),
            quill.QuillToolbarColorButton(
              controller: controller,
              isBackground: false,
              options: const quill.QuillToolbarColorButtonOptions(),
            ),
            quill.QuillToolbarColorButton(
              controller: controller,
              isBackground: true,
              options: const quill.QuillToolbarColorButtonOptions(),
            ),
            const VerticalDivider(),
            quill.QuillToolbarSelectHeaderStyleDropdownButton(
              controller: controller,
              options:
                  const quill.QuillToolbarSelectHeaderStyleDropdownButtonOptions(),
            ),
            const VerticalDivider(),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.ol,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.ul,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),
            quill.QuillToolbarIndentButton(
              controller: controller,
              isIncrease: true,
              options: const quill.QuillToolbarIndentButtonOptions(),
            ),
            quill.QuillToolbarIndentButton(
              controller: controller,
              isIncrease: false,
              options: const quill.QuillToolbarIndentButtonOptions(),
            ),
            const VerticalDivider(),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.blockQuote,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),
            quill.QuillToolbarToggleStyleButton(
              attribute: quill.Attribute.codeBlock,
              controller: controller,
              options: const quill.QuillToolbarToggleStyleButtonOptions(),
            ),
            const VerticalDivider(),
            quill.QuillToolbarLinkStyleButton(
              controller: controller,
              options: const quill.QuillToolbarLinkStyleButtonOptions(),
            ),
            quill.QuillToolbarClearFormatButton(
              controller: controller,
              options: const quill.QuillToolbarClearFormatButtonOptions(),
            ),
            const VerticalDivider(),
            // Ruler toggle button
            IconButton(
              icon: Icon(
                showRuler ? Icons.straighten : Icons.straighten_outlined,
                size: 20,
              ),
              tooltip: showRuler ? 'Hide Ruler' : 'Show Ruler',
              onPressed: () {
                ref.read(rulerVisibilityProvider.notifier).state = !showRuler;
              },
              isSelected: showRuler,
              style: IconButton.styleFrom(
                backgroundColor: showRuler
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
