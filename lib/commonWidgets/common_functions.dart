

String formatDuration(int durationMs) {
  final duration = Duration(milliseconds: durationMs);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  final secondsStr = seconds.toString().padLeft(2, '0'); // ensures 2 digits
  return '$minutes:$secondsStr';
}