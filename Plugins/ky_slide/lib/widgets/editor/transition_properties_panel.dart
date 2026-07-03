import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slide_transition.dart';
import '../services/slide_transition_service.dart';

/// Properties panel widget for configuring the selected slide's transition.
/// Includes duration, direction, sound, and "Apply to All" functionality.
class TransitionPropertiesPanel extends ConsumerStatefulWidget {
  final String slideId;

  const TransitionPropertiesPanel({
    super.key,
    required this.slideId,
  });

  @override
  ConsumerState<TransitionPropertiesPanel> createState() =>
      _TransitionPropertiesPanelState();
}

class _TransitionPropertiesPanelState
    extends ConsumerState<TransitionPropertiesPanel> {
  late TextEditingController _durationController;
  bool _isAutoAdvance = false;
  double _autoAdvanceDelay = 0.0;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: '0.5');
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(slideTransitionServiceProvider);
    // In a real app, we would watch the specific slide's transition state
    // For now, we simulate getting the current transition
    final currentTransition = service.getTransitionForSlide(widget.slideId) ??
        SlideTransition.defaultTransition();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration Control
          _buildSectionTitle('Timing'),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    suffixText: 'sec',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    // Update transition duration logic here
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              // Direction Dropdown (only for directional transitions)
              if ([
                TransitionType.push,
                TransitionType.wipe,
                TransitionType.reveal,
                TransitionType.cover,
                TransitionType.uncover,
              ].contains(currentTransition.type))
                Expanded(
                  child: DropdownButtonFormField<TransitionDirection>(
                    value: currentTransition.direction,
                    decoration: const InputDecoration(
                      labelText: 'Direction',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                    ),
                    items: TransitionDirection.values.map((dir) {
                      return DropdownMenuItem(
                        value: dir,
                        child: Text(dir.displayName,
                            style: const TextStyle(fontSize: 12.0)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      // Update transition direction logic here
                    },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24.0),

          // Advance Slide Options
          _buildSectionTitle('Advance Slide'),
          const SizedBox(height: 8.0),
          CheckboxListTile(
            title: const Text('On Mouse Click'),
            subtitle: const Text('Allow manual advance'),
            value: !currentTransition.autoAdvance,
            onChanged: (value) {
              // Toggle manual advance logic
            },
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('After'),
            value: currentTransition.autoAdvance,
            onChanged: (value) {
              setState(() {
                _isAutoAdvance = value ?? false;
              });
              // Toggle auto advance logic
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (currentTransition.autoAdvance)
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        suffixText: 'seconds',
                        border: UnderlineInputBorder(),
                        contentPadding: EdgeInsets.zero,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _autoAdvanceDelay = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32.0),

          // Apply to All Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showApplyToAllDialog(context, service);
              },
              icon: const Icon(Icons.layers),
              label: const Text('Apply to All Slides'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Sound Effect (Future Enhancement Placeholder)
          _buildSectionTitle('Sound'),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<String>(
            value: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: 'none',
                child: Text('[No Sound]'),
              ),
              const DropdownMenuItem(
                value: 'chime',
                child: Text('Chime'),
              ),
              const DropdownMenuItem(
                value: 'click',
                child: Text('Click'),
              ),
              const DropdownMenuItem(
                value: 'explode',
                child: Text('Explode'),
              ),
            ],
            onChanged: (value) {
              // Update sound effect logic here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
    );
  }

  void _showApplyToAllDialog(
      BuildContext context, SlideTransitionService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Transition to All Slides?'),
        content: const Text(
          'This will replace all existing transitions in your presentation with the current settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.applyToAll(widget.slideId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transition applied to all slides'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
