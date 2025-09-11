import 'package:flutter/material.dart';
import '../themes/font.dart';

class Texts extends StatelessWidget {
  final String text;
  final String fontFamily;
  final FontWeight fontWeight;
  final double fontSize;
  final Color color;
  final TextAlign? align;
  final int? maxLines;
  final double? height;
  final TextDecoration? decoration;
  final TextOverflow? overflow; // 👈 new parameter

  const Texts(
      this.text, {
        super.key,
        this.fontFamily = AppFonts.inter,
        this.fontWeight = AppFontWeights.regular,
        this.fontSize = 14,
        this.color = Colors.black,
        this.align,
        this.maxLines,
        this.height,
        this.decoration,
        this.overflow, // 👈 optional
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow ?? // 👈 priority to user
          (maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip),
      style: TextStyle(
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
        height: height,
        decoration: decoration,
      ),
    );
  }
}
