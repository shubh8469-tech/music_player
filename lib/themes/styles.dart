import 'package:flutter/material.dart';

class Styles {
  static customTextStyle({
    Color? color,
     fontWeight= FontWeight.w500,
    double fontSize= 16.0,
    double height= 1.5,
    TextDecoration? textDecoration= TextDecoration.none,
    double? letterSpacing,
    String? fontFamily,
    var shadows,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      fontFamily: fontFamily,
      decoration: textDecoration,
      letterSpacing: letterSpacing,
      shadows: shadows,
      fontStyle: fontStyle,
    );
  }

}
