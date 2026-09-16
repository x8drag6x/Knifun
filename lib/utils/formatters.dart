String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} متر';
  }
  return '${(meters / 1000).toStringAsFixed(1)} کیلومتر';
}

String lineText(List<int> lines) {
  if (lines.isEmpty) return 'مترو';
  return lines.map((line) => 'خط $line').join('، ');
}
