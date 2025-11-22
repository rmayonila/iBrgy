import 'package:flutter/material.dart';

/// Centralized navigation helper for Moderator bottom navigation.
///
/// Usage:
/// ```dart
/// navigateModeratorIndex(context, index, currentIndex: _selectedIndex, onSamePage: (i) => setState(() => _selectedIndex = i));
/// ```
void navigateModeratorIndex(
  BuildContext context,
  int index, {
  int? currentIndex,
  void Function(int)? onSamePage,
}) {
  const Map<int, String> routes = {
    0: '/moderator-home',
    1: '/moderator-emergency-hotline',
    2: '/moderator-announcement',
    3: '/moderator-brgy-officials',
    4: '/moderator-account-settings',
  };

  // If the caller provided the current index and it's the same, call onSamePage
  if (currentIndex != null && currentIndex == index) {
    if (onSamePage != null) onSamePage(index);
    return;
  }

  final target = routes[index];
  if (target == null) return;

  Navigator.pushReplacementNamed(context, target);
}
