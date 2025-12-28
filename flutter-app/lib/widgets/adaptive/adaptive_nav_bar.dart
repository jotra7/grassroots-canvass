import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/adaptive_theme.dart';
import '../../utils/platform_utils.dart';

/// Represents a navigation destination with platform-specific icons.
class AdaptiveNavDestination {
  const AdaptiveNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.cupertinoIcon,
    this.cupertinoSelectedIcon,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final IconData? cupertinoIcon;
  final IconData? cupertinoSelectedIcon;
}

/// An adaptive bottom navigation bar.
/// Uses NavigationBar on Android/Web and CupertinoTabBar on iOS/macOS.
class AdaptiveNavBar extends StatelessWidget {
  const AdaptiveNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApple) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onDestinationSelected,
        activeColor: AdaptiveTheme.primaryOrange,
        items: destinations
            .map(
              (d) => BottomNavigationBarItem(
                icon: Icon(d.cupertinoIcon ?? d.icon),
                activeIcon: Icon(d.cupertinoSelectedIcon ?? d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations
          .map(
            (d) => NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
          )
          .toList(),
    );
  }
}
