import 'package:flutter/material.dart';

/// Provides dark-mode aware colors for the app.
/// Use these instead of hardcoded Colors.* values.
class AdaptiveColors {
  final BuildContext context;

  AdaptiveColors(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Shorthand constructor
  static AdaptiveColors of(BuildContext context) => AdaptiveColors(context);

  // Status colors - These maintain semantic meaning in both modes
  Color get success => isDark ? Colors.green.shade400 : Colors.green;
  Color get successLight => isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade100;

  Color get error => isDark ? Colors.red.shade400 : Colors.red;
  Color get errorLight => isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade100;

  Color get warning => isDark ? Colors.orange.shade400 : Colors.orange;
  Color get warningLight => isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade100;
  Color get warningText => isDark ? Colors.orange.shade300 : Colors.orange.shade800;

  Color get info => isDark ? Colors.blue.shade400 : Colors.blue;
  Color get infoLight => isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade100;

  // Role colors
  Color get adminColor => isDark ? Colors.purple.shade300 : Colors.purple;
  Color get adminLight => isDark ? Colors.purple.shade900.withValues(alpha: 0.3) : Colors.purple.shade100;

  Color get teamLeadColor => isDark ? Colors.teal.shade300 : Colors.teal;
  Color get teamLeadLight => isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade100;

  Color get canvasserColor => isDark ? Colors.blue.shade300 : Colors.blue;
  Color get canvasserLight => isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade100;

  // Party colors
  Color get democratColor => isDark ? Colors.blue.shade400 : Colors.blue;
  Color get republicanColor => isDark ? Colors.red.shade400 : Colors.red;
  Color get independentColor => isDark ? Colors.purple.shade300 : Colors.purple;
  Color get otherPartyColor => isDark ? Colors.grey.shade400 : Colors.grey;

  // Shadows and overlays
  Color get shadow => isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.2);
  Color get overlay => isDark
      ? Colors.black.withValues(alpha: 0.6)
      : Colors.black.withValues(alpha: 0.3);

  // Dividers and borders
  Color get divider => isDark ? Colors.white24 : Colors.black12;
  Color get border => isDark ? Colors.white30 : Colors.black26;

  // Card and surface backgrounds
  Color get cardBackground => Theme.of(context).colorScheme.surface;
  Color get elevatedBackground => isDark
      ? const Color(0xFF2A2F35)
      : Colors.white;

  // Selection colors
  Color get selected => Theme.of(context).colorScheme.primaryContainer;
  Color get selectedText => Theme.of(context).colorScheme.onPrimaryContainer;

  // Disabled state
  Color get disabled => isDark ? Colors.grey.shade700 : Colors.grey.shade400;
  Color get disabledText => isDark ? Colors.grey.shade500 : Colors.grey.shade600;

  // Get role color by role string
  Color getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return adminColor;
      case 'team_lead':
        return teamLeadColor;
      case 'canvasser':
        return canvasserColor;
      case 'pending':
        return warningColor;
      default:
        return otherPartyColor;
    }
  }

  Color getRoleBackgroundColor(String role) {
    switch (role) {
      case 'admin':
        return adminLight;
      case 'team_lead':
        return teamLeadLight;
      case 'canvasser':
        return canvasserLight;
      case 'pending':
        return warningLight;
      default:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }
  }

  // Alias for warning
  Color get warningColor => warning;
  Color get pendingColor => warning;
  Color get pendingLight => warningLight;
}
