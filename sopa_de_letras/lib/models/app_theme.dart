import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color background;
  final Color primary;
  final Color surface;
  final Color text;
  final Color accent;
  final Brightness brightness;

  AppTheme({
    required this.name,
    required this.background,
    required this.primary,
    required this.surface,
    required this.text,
    required this.accent,
    required this.brightness,
  });
}

final List<AppTheme> myThemes = [
  AppTheme(
    name: "Clásico",
    background: const Color(0xFFFDFBF7),
    primary: const Color(0xFF6D4C41),
    surface: const Color(0xFFFFF8E1),
    text: const Color(0xFF4E342E),
    accent: const Color(0xFFFFA726),
    brightness: Brightness.light,
  ),
  AppTheme(
    name: "Noche",
    background: const Color(0xFF121212),
    primary: const Color(0xFF90CAF9),
    surface: const Color(0xFF1E1E1E),
    text: const Color(0xFFEEEEEE),
    accent: const Color(0xFF64B5F6),
    brightness: Brightness.dark,
  ),
  AppTheme(
    name: "Lavanda",
    background: const Color(0xFFF3E5F5),
    primary: const Color(0xFF6A1B9A),
    surface: const Color(0xFFFFFFFF),
    text: const Color(0xFF4A148C),
    accent: const Color(0xFFAB47BC),
    brightness: Brightness.light,
  ),
];
