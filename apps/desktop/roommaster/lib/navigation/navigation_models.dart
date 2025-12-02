import 'package:flutter/material.dart';

class NavigationSection {
  final String title;
  final List<NavigationItem> items;

  const NavigationSection({required this.title, required this.items});
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;
  final Gradient gradient;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
    required this.gradient,
  });
}
