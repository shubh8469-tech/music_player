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

  const Texts(
      this.text, {
        super.key,
        this.fontFamily = AppFonts.manrope,
        this.fontWeight = AppFontWeights.regular,
        this.fontSize = 14,
        this.color = Colors.black,
        this.align,
        this.maxLines,
        this.height,
        this.decoration,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
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
