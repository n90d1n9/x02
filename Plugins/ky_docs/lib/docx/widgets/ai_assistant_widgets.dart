import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/provider.dart';

/// Collects the API key used by the local AI assistant service.
class AIApiKeyDialog extends ConsumerStatefulWidget {
  const AIApiKeyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const AIApiKeyDialog(),
    );
  }

  @override
  ConsumerState<AIApiKeyDialog> createState() => _AIApiKeyDialogState();
}

class _AIApiKeyDialogState extends ConsumerState<AIApiKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.key),
          SizedBox(width: 8),
          Text('Configure AI Assistant'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your Claude API key to enable AI features:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-ant-...',
              border: OutlineInputBorder(),
              helperText: 'Stored locally on this device',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your API key is stored locally and never shared.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveApiKey, child: const Text('Save')),
      ],
    );
  }

  void _saveApiKey() {
    final apiKey = _controller.text.trim();
    if (apiKey.isEmpty) {
      return;
    }

    ref.read(aiAssistantServiceProvider).setApiKey(apiKey);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key configured successfully')),
    );
  }
}
