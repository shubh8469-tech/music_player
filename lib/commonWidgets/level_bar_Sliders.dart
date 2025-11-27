import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class LevelBarSlider extends StatelessWidget {
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
}

/*
class LevelBarSlider extends StatelessWidget {
  final int level;
  final int maxLevel;
  final ValueChanged<int> onChanged;

  const LevelBarSlider({
    super.key,
    required this.level,
    this.maxLevel = 21,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = box.globalToLocal(details.globalPosition).dx;

        final barWidth = box.size.width / maxLevel;
        int newLevel = (localX / barWidth).ceil().clamp(0, maxLevel);
        onChanged(newLevel);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLevel, (i) {
          final isActive = i < level;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 20,
            decoration: BoxDecoration(
              color: isActive ? Colors.orange : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
*/
