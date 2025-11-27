import 'package:flutter/material.dart';

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
