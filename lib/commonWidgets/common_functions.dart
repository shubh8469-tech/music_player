

import 'package:flutter/cupertino.dart';
import 'package:music_app/commonWidgets/textWidget.dart';

import '../themes/color.dart';
import '../themes/font.dart';

String formatDuration(int durationMs) {
  final duration = Duration(milliseconds: durationMs);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  final secondsStr = seconds.toString().padLeft(2, '0'); // ensures 2 digits
  return '$minutes:$secondsStr';
}

Widget buildGenreInitialAvatar(String name, double fontSize) {
  final trimmed = name.trim();
  final initial =
  trimmed.isNotEmpty ? trimmed.characters.first.toUpperCase() : '?';
  return Texts(
    initial,
    fontSize: fontSize,
    fontWeight: AppFontWeights.semiBold,
    fontFamily: AppFonts.inter,
    color: AppColors.white,
  );
}