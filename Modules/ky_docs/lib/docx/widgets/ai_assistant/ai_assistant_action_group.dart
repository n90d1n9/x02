import 'package:flutter/material.dart';

import '../../models/aiaction.dart';

/// Groups AI writing actions into task-focused sections for the assistant UI.
class AIAssistantActionGroup {
  final String title;
  final IconData icon;
  final List<AIAction> actions;

  const AIAssistantActionGroup({
    required this.title,
    required this.icon,
    required this.actions,
  });
}

/// Provides the default action groups used by the document AI assistant.
class AIAssistantActionCatalog {
  const AIAssistantActionCatalog._();

  static const groups = [
    AIAssistantActionGroup(
      title: 'Refine',
      icon: Icons.auto_fix_high,
      actions: [AIAction.improve, AIAction.fixGrammar, AIAction.simplify],
    ),
    AIAssistantActionGroup(
      title: 'Shape',
      icon: Icons.tune,
      actions: [AIAction.shortenText, AIAction.expandText, AIAction.addDetails],
    ),
    AIAssistantActionGroup(
      title: 'Tone',
      icon: Icons.record_voice_over_outlined,
      actions: [AIAction.changeToneFormal, AIAction.changeToneCasual],
    ),
    AIAssistantActionGroup(
      title: 'Draft',
      icon: Icons.edit_note,
      actions: [AIAction.summarize, AIAction.continueWriting],
    ),
  ];
}
