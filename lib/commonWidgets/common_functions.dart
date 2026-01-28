

import 'package:flutter/cupertino.dart';
import 'package:music_app/commonWidgets/textWidget.dart';

import '../themes/color.dart';
import '../themes/font.dart';

String formatDuration(int durationMs) {
  final duration = Duration(milliseconds: durationMs);

  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:$minutesStr:$secondsStr';
  } else {
    // We use minutes without padding here so 5:01 stays 5:01,
    // but you can add .padLeft(2, '0') if you prefer 05:01.
    return '$minutes:$secondsStr';
  }
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