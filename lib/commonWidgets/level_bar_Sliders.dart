import 'package:flutter/material.dart';

import 'package:flutter/material.dart';


class LevelBarSlider extends StatelessWidget {
  final int level;
  final int displayMaxLevel;
  final ValueChanged<int> onChanged;

  const LevelBarSlider({
    super.key,
    required this.level,
    this.displayMaxLevel = 20,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dimensions
        const gapWidth = 4.0;
        final totalGaps = (displayMaxLevel - 1) * gapWidth;
        final barWidth = (constraints.maxWidth - totalGaps) / displayMaxLevel;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,

          onHorizontalDragUpdate: (details) {
            _handleTouch(context, details.globalPosition, barWidth, gapWidth);
          },

          onTapDown: (details) {
            _handleTouch(context, details.globalPosition, barWidth, gapWidth);
          },

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(displayMaxLevel, (i) {
              final isActive = i < level;
              return Container(
                width: barWidth,
                height: 20,
                decoration: BoxDecoration(
                  color: isActive ? Colors.orange : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  /// Handle touch/drag events and calculate new level
  void _handleTouch(BuildContext context, Offset globalPosition, double barWidth, double gapWidth) {
    final box = context.findRenderObject() as RenderBox;
    final localX = box.globalToLocal(globalPosition).dx;

    final ratio = (localX / box.size.width).clamp(0.0, 1.0);
    int newLevel = (ratio * displayMaxLevel).round().clamp(0, displayMaxLevel);

    onChanged(newLevel);
  }
}


/*class LevelBarSlider extends StatelessWidget {
  final int level;
  final int displayMaxLevel;
  final ValueChanged<int> onChanged;

  const LevelBarSlider({super.key, required this.level, this.displayMaxLevel = 21, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // final screenWidth = MediaQuery.of(context).size.width;
        // int displayMaxLevel = screenWidth < 350 ? 21 : 21;

        final barWidth = (constraints.maxWidth - (displayMaxLevel - 1) * 5) / displayMaxLevel;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localX = box.globalToLocal(details.globalPosition).dx;
            int newLevel = (localX / (barWidth + 4)).ceil().clamp(0, displayMaxLevel);
            onChanged(newLevel);
          },
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localX = box.globalToLocal(details.globalPosition).dx;
            int newLevel = (localX / (barWidth + 4)).ceil().clamp(0, displayMaxLevel);
            onChanged(newLevel);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(displayMaxLevel, (i) {
              final isActive = i < level;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: barWidth,
                height: 20,
                decoration: BoxDecoration(color: isActive ? Colors.orange : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              );
            }),
          ),
        );
      },
    );
  }
}*/


