import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/page_settings.dart';
import '../states/provider.dart';
import 'page_settings/page_settings_form.dart';

/// Presents document page size, header, footer, and numbering settings.
class PageSettingDialog extends ConsumerStatefulWidget {
  const PageSettingDialog({super.key});

  @override
  ConsumerState<PageSettingDialog> createState() => _PageSettingDialogState();
}

class _PageSettingDialogState extends ConsumerState<PageSettingDialog> {
  late PageSettings _draftSettings;

  @override
  void initState() {
    super.initState();
    _draftSettings = ref.read(documentProvider).pageSettings;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Page Settings'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: DocumentPageSettingsForm(
            settings: _draftSettings,
            onChanged: (settings) => _draftSettings = settings,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _applySettings, child: const Text('Apply')),
      ],
    );
  }

  void _applySettings() {
    ref.read(documentProvider.notifier).updatePageSettings(_draftSettings);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Page settings updated')));
  }
}
