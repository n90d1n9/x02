import 'package:flutter/material.dart';

import '../../models/document_state.dart';

class DocumentCollaboratorsMenu extends StatelessWidget {
  final DocumentState documentState;

  const DocumentCollaboratorsMenu({super.key, required this.documentState});

  @override
  Widget build(BuildContext context) {
    if (!documentState.isCollaborationEnabled ||
        documentState.collaborators.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<void>(
      icon: Stack(
        children: [
          const Icon(Icons.people),
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                '${documentState.collaborators.length}',
                style: const TextStyle(color: Colors.white, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      tooltip: 'Collaborators',
      itemBuilder: (context) {
        return documentState.collaborators.map((user) {
          return PopupMenuItem<void>(
            enabled: false,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: user.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(user.name),
                const Spacer(),
                Icon(Icons.circle, size: 8, color: Colors.green[700]),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
