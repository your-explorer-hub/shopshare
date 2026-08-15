import 'package:flutter/material.dart';

class ListBannerVariant {
  ListBannerVariant._();

  static const List<List<Color>> _variants = [
    [Color(0xFF1565C0), Color(0xFF0097A7)], // 0 Ocean
    [Color(0xFFE53935), Color(0xFFFB8C00)], // 1 Sunset
    [Color(0xFF2E7D32), Color(0xFF00796B)], // 2 Forest
    [Color(0xFF6A1B9A), Color(0xFF3949AB)], // 3 Lavender
    [Color(0xFFBF360C), Color(0xFFF57F17)], // 4 Ember
    [Color(0xFF1A237E), Color(0xFF4527A0)], // 5 Midnight
    [Color(0xFF880E4F), Color(0xFFE91E63)], // 6 Rose
    [Color(0xFF37474F), Color(0xFF00695C)], // 7 Slate
  ];

  static const List<Color> _myListColors = [
    Color(0xFF6A3DE8),
    Color(0xFFB06AB3),
  ];

  static LinearGradient gradientForList(String listId) {
    final index = listId.hashCode.abs() % 8;
    return LinearGradient(
      colors: _variants[index],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static LinearGradient gradientForMyList() {
    return const LinearGradient(
      colors: _myListColors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  // ignore: avoid_unused_parameters
  static Color iconColorForList(String listId) => Colors.white;

  static Color startColorForList(String listId) =>
      _variants[listId.hashCode.abs() % 8][0];

  static Color endColorForList(String listId) =>
      _variants[listId.hashCode.abs() % 8][1];
}
