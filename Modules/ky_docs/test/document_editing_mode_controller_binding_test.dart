import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_controller_binding.dart';

void main() {
  group('DocumentEditingModeControllerBinding', () {
    testWidgets('syncs viewing mode to controller read-only state', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DocumentEditingModeControllerBinding(
          controller: controller,
          mode: DocumentEditingMode.viewing,
          child: const SizedBox.shrink(),
        ),
      );

      expect(controller.readOnly, isTrue);

      await tester.pumpWidget(
        DocumentEditingModeControllerBinding(
          controller: controller,
          mode: DocumentEditingMode.editing,
          child: const SizedBox.shrink(),
        ),
      );

      expect(controller.readOnly, isFalse);
    });

    testWidgets('restores the controller read-only state on disposal', (
      tester,
    ) async {
      final controller = quill.QuillController.basic()..readOnly = true;
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DocumentEditingModeControllerBinding(
          controller: controller,
          mode: DocumentEditingMode.editing,
          child: const SizedBox.shrink(),
        ),
      );

      expect(controller.readOnly, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(controller.readOnly, isTrue);
    });
  });
}
