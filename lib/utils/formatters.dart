String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} متر';
  }
  final kilometers = meters / 1000;
  final digits = kilometers % 1 == 0 ? 0 : 1;
  return '${kilometers.toStringAsFixed(digits)} کیلومتر';
}

String lineText(List<int> lines) {
  if (lines.isEmpty) return 'مترو';
  return lines.map((line) => 'خط $line').join('، ');
}
