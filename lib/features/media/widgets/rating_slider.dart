import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RatingSlider extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const RatingSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<RatingSlider> createState() => _RatingSliderState();
}

class _RatingSliderState extends State<RatingSlider> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = (widget.value ?? 0).toDouble();
  }

  @override
  void didUpdateWidget(RatingSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _current = (widget.value ?? 0).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = _current > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Rating', style: theme.textTheme.labelSmall),
            const Spacer(),
            if (hasValue)
              GestureDetector(
                onTap: () {
                  setState(() => _current = 0);
                  widget.onChanged(null);
                },
                child: Text(
                  'Clear',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasValue
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasValue ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  hasValue ? '${_current.round()}' : '—',
                  style: TextStyle(
                    color: hasValue ? AppColors.primaryLight : AppColors.textTertiary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surface,
                  thumbColor: AppColors.primaryLight,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
                  value: _current,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (v) {
                    setState(() => _current = v);
                    widget.onChanged(v > 0 ? v.round() : null);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
