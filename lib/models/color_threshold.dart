// lib/models/color_threshold.dart

import 'package:flutter/material.dart';

class ColorThreshold {
  final Color color;
  final String label;
  int days;
  bool enabled;

  ColorThreshold({
    required this.color,
    required this.label,
    required this.days,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
    'days': days,
    'enabled': enabled,
  };
}