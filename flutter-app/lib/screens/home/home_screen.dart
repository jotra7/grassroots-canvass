import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/platform_utils.dart';
import '../../utils/adaptive_icons.dart';
import '../../widgets/offline_banner.dart';
import '../voters/voter_list_screen.dart';
import '../map/map_screen.dart';
import '../admin/admin_screen.dart';
import '../team/team_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAdmin;
    final isTeamLead = authState.isTeamLead;
    final isApple = PlatformUtils.isApple;

    final screens = [
      const VoterListScreen(),
      const MapScreen(),
      // Team leads get Team tab, Admins get Admin tab
      if (isTeamLead && !isAdmin) const TeamScreen(),
      if (isAdmin) const AdminScreen(),
      const SettingsScreen(),
    ];

    if (isApple) {
      return _buildCupertinoTabScaffold(screens, isAdmin, isTeamLead);
    }

    return _buildMaterialScaffold(screens, isAdmin, isTeamLead);
  }

  Widget _buildCupertinoTabScaffold(List<Widget> screens, bool isAdmin, bool isTeamLead) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            activeIcon: Icon(CupertinoIcons.list_bullet),
            label: 'Voters',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map),
            activeIcon: Icon(CupertinoIcons.map_fill),
            label: 'Map',
          ),
          // Team leads get Team tab
          if (isTeamLead && !isAdmin)
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_3),
              activeIcon: Icon(CupertinoIcons.person_3_fill),
              label: 'Team',
            ),
          // Admins get Admin tab
          if (isAdmin)
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_badge_plus),
              activeIcon: Icon(CupertinoIcons.person_badge_plus_fill),
              label: 'Admin',
            ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            activeIcon: Icon(CupertinoIcons.settings_solid),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return Column(
              children: [
                const OfflineBanner(),
                Expanded(child: screens[index]),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialScaffold(List<Widget> screens, bool isAdmin, bool isTeamLead) {
    final destinations = [
      NavigationDestination(
        icon: Icon(AdaptiveIcons.list),
        selectedIcon: Icon(AdaptiveIcons.listAlt),
        label: 'Voters',
      ),
      NavigationDestination(
        icon: Icon(AdaptiveIcons.mapOutlined),
        selectedIcon: Icon(AdaptiveIcons.map),
        label: 'Map',
      ),
      // Team leads get Team tab
      if (isTeamLead && !isAdmin)
        NavigationDestination(
          icon: Icon(AdaptiveIcons.groupsOutlined),
          selectedIcon: Icon(AdaptiveIcons.groups),
          label: 'Team',
        ),
      // Admins get Admin tab
      if (isAdmin)
        NavigationDestination(
          icon: Icon(AdaptiveIcons.adminOutlined),
          selectedIcon: Icon(AdaptiveIcons.admin),
          label: 'Admin',
        ),
      NavigationDestination(
        icon: Icon(AdaptiveIcons.settingsOutlined),
        selectedIcon: Icon(AdaptiveIcons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}
