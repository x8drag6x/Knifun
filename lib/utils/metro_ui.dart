import 'package:flutter/material.dart';

const Map<int, Color> metroLineColors = {
  1: Color(0xFFE53935), // red
  2: Color(0xFF1565C0), // dark blue
  3: Color(0xFF29B6F6), // light blue
  4: Color(0xFFF9A825), // yellow
  5: Color(0xFF43A047), // green
  6: Color(0xFFEC407A), // pink
  7: Color(0xFF7E57C2), // purple
};

Color metroLineColor(int line) => metroLineColors[line] ?? const Color(0xFF607D8B);

String metroLineLabel(int line) => 'خط $line';
