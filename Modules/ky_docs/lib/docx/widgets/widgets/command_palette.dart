import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/command.dart';
import '../../states/command_provider.dart';
import '../../states/docs_provider.dart';

class CommandPalette extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const CommandPalette({super.key, required this.onDismiss});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final commands = _getFilteredCommands();

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 500),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Type a command or search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: commands.length,
                      itemBuilder: (context, index) {
                        final cmd = commands[index];
                        return ListTile(
                          leading: Icon(cmd.icon, size: 20),
                          title: Text(cmd.title),
                          subtitle: Text(cmd.description),
                          trailing: cmd.shortcut != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    cmd.shortcut!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                )
                              : null,
                          onTap: () {
                            cmd.action(ref);
                            widget.onDismiss();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Command> _getFilteredCommands() {
    final allCommands = [
      Command(
        'New Document',
        'Create a new document',
        Icons.add,
        (ref) => ref.read(documentControllerProvider.notifier).newDocument(),
        '⌘N',
      ),
      Command(
        'Save Document',
        'Save current document',
        Icons.save,
        (ref) => ref.read(documentControllerProvider.notifier).saveDocument(),
        '⌘S',
      ),
      Command(
        'Toggle Theme',
        'Switch between light and dark mode',
        Icons.brightness_4,
        (ref) =>
            ref.read(themeProvider.notifier).state = !ref.read(themeProvider),
        null,
      ),
      Command(
        'Focus Mode',
        'Enter distraction-free writing mode',
        Icons.fullscreen,
        (ref) => ref.read(focusModeProvider.notifier).state = !ref.read(
          focusModeProvider,
        ),
        null,
      ),
      Command(
        'Toggle Toolbar',
        'Show or hide formatting toolbar',
        Icons.settings,
        (ref) => ref.read(toolbarVisibilityProvider.notifier).state = !ref.read(
          toolbarVisibilityProvider,
        ),
        null,
      ),
      Command('Export JSON', 'Export document as JSON', Icons.download, (ref) {
        final json = ref
            .read(documentControllerProvider.notifier)
            .exportToJson();
        Clipboard.setData(ClipboardData(text: json));
      }, null),
      Command(
        'Export Markdown',
        'Export document as Markdown',
        Icons.text_fields,
        (ref) {
          final md = ref
              .read(documentControllerProvider.notifier)
              .exportToMarkdown();
          Clipboard.setData(ClipboardData(text: md));
        },
        null,
      ),
      Command(
        'Share Document',
        'Share with others',
        Icons.share,
        (ref) {},
        null,
      ),
      Command(
        'Version History',
        'View document versions',
        Icons.history,
        (ref) {},
        null,
      ),
    ];

    if (_query.isEmpty) return allCommands;

    return allCommands.where((cmd) {
      return cmd.title.toLowerCase().contains(_query.toLowerCase()) ||
          cmd.description.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }
}
