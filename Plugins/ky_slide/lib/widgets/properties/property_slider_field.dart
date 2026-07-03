import 'package:flutter/material.dart';

class PropertySliderField extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final String Function(double value) valueLabelBuilder;
  final ValueChanged<double> onChangeEnd;

  const PropertySliderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions = 100,
    this.enabled = true,
    this.valueLabelBuilder = _defaultValueLabel,
  });

  @override
  State<PropertySliderField> createState() => _PropertySliderFieldState();

  static String _defaultValueLabel(double value) {
    return value.toStringAsFixed(2);
  }
}

class _PropertySliderFieldState extends State<PropertySliderField> {
  late double _draftValue;

  @override
  void initState() {
    super.initState();
    _draftValue = widget.value;
  }

  @override
  void didUpdateWidget(PropertySliderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _draftValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _draftValue.clamp(widget.min, widget.max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              widget.valueLabelBuilder(value),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6366F1),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF6366F1).withValues(alpha: 0.18),
          ),
          child: Slider(
            value: value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: widget.enabled
                ? (value) => setState(() => _draftValue = value)
                : null,
            onChangeEnd: widget.enabled ? widget.onChangeEnd : null,
          ),
        ),
      ],
    );
  }
}
