import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'aiaction.dart';

class AIAssistantService {
  static const String _apiEndpoint = 'https://api.anthropic.com/v1/messages';
  String? _apiKey;
  void setApiKey(String key) {
    _apiKey = key;
  }

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  Future<String> processText(String text, AIAction action) async {
    if (!hasApiKey) {
      throw Exception('API key not set. Please configure your Claude API key.');
    }
    final prompt = _buildPrompt(text, action);
    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 2048,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'];
        if (content is List && content.isNotEmpty) {
          return content[0]['text'] ?? text;
        }
        return text;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          'API Error: ${error['error']?['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to process text: $e');
    }
  }

  String _buildPrompt(String text, AIAction action) {
    switch (action) {
      case AIAction.improve:
        return '''Improve the following text by making it clearer, more engaging, and better written while preserving the original meaning. Return only the improved text without any explanations:

$text''';
      case AIAction.expandText:
        return '''Expand the following text by adding more details, examples, and context while maintaining the same style and tone. Return only the expanded text:

$text''';
      case AIAction.shortenText:
        return '''Make the following text more concise while preserving all key information and meaning. Return only the shortened text:

$text''';
      case AIAction.summarize:
        return '''Provide a clear, concise summary of the following text. Capture the main points and key information:

$text''';
      case AIAction.fixGrammar:
        return '''Fix any grammar, spelling, and punctuation errors in the following text. Return only the corrected text without explanations:

$text''';
      case AIAction.changeToneFormal:
        return '''Rewrite the following text in a formal, professional tone suitable for business or academic contexts. Return only the rewritten text:

$text''';
      case AIAction.changeToneCasual:
        return '''Rewrite the following text in a casual, conversational tone that's friendly and approachable. Return only the rewritten text:

$text''';
      case AIAction.continueWriting:
        return '''Continue writing based on the following text. Maintain the same style, tone, and subject matter. Write 2-3 additional sentences:

$text''';
      case AIAction.simplify:
        return '''Simplify the following text to make it easier to understand while keeping the core message. Use simpler words and shorter sentences:

$text''';
      case AIAction.addDetails:
        return '''Add more specific details, examples, and supporting information to the following text to make it more informative and complete:

$text''';
    }
  }

  String getActionLabel(AIAction action) {
    switch (action) {
      case AIAction.improve:
        return 'Improve Writing';
      case AIAction.expandText:
        return 'Expand Text';
      case AIAction.shortenText:
        return 'Shorten Text';
      case AIAction.summarize:
        return 'Summarize';
      case AIAction.fixGrammar:
        return 'Fix Grammar';
      case AIAction.changeToneFormal:
        return 'Make Formal';
      case AIAction.changeToneCasual:
        return 'Make Casual';
      case AIAction.continueWriting:
        return 'Continue Writing';
      case AIAction.simplify:
        return 'Simplify';
      case AIAction.addDetails:
        return 'Add Details';
    }
  }

  IconData getActionIcon(AIAction action) {
    switch (action) {
      case AIAction.improve:
        return Icons.auto_fix_high;
      case AIAction.expandText:
        return Icons.expand;
      case AIAction.shortenText:
        return Icons.compress;
      case AIAction.summarize:
        return Icons.summarize;
      case AIAction.fixGrammar:
        return Icons.spellcheck;
      case AIAction.changeToneFormal:
        return Icons.business_center;
      case AIAction.changeToneCasual:
        return Icons.chat_bubble_outline;
      case AIAction.continueWriting:
        return Icons.edit_note;
      case AIAction.simplify:
        return Icons.lightbulb_outline;
      case AIAction.addDetails:
        return Icons.add_circle_outline;
    }
  }
}
