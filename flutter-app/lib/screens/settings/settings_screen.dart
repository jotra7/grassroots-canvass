import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voter_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/analytics_service.dart';
import '../../config/app_constants.dart';
import '../../utils/platform_utils.dart';
import '../../utils/adaptive_icons.dart';
import '../../utils/adaptive_feedback.dart';
import '../../widgets/adaptive/adaptive_dialogs.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('settings');
  }

  Future<void> _signOut() async {
    final confirmed = await AdaptiveDialogs.showConfirmation(
      context: context,
      title: 'Sign Out',
      content: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      AnalyticsService.instance.trackAction('signed_out');
    }
  }

  Future<void> _refreshData() async {
    final confirmed = await AdaptiveDialogs.showConfirmation(
      context: context,
      title: 'Refresh Data',
      content: 'This will reload all voter data from the cloud. Continue?',
      confirmText: 'Refresh',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      await ref.read(voterProvider.notifier).loadVoters();
      AnalyticsService.instance.trackAction('data_refreshed');
      if (mounted) {
        AdaptiveFeedback.showSuccess(context, 'Data refreshed');
      }
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await AdaptiveDialogs.showConfirmation(
      context: context,
      title: 'Clear Local Data',
      content: 'This will clear all locally cached data. Your changes have already been synced to the cloud.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      ref.read(voterProvider.notifier).clearAll();
      AnalyticsService.instance.trackAction('local_data_cleared');
      if (mounted) {
        AdaptiveFeedback.showSuccess(context, 'Local data cleared');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final voterState = ref.watch(voterProvider);
    final isApple = PlatformUtils.isApple;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Settings'),
      ),
      body: isApple ? _buildCupertinoContent(authState, voterState) : _buildMaterialContent(authState, voterState),
    );
  }

  Widget _buildCupertinoContent(AuthStateData authState, VoterState voterState) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return ListView(
      children: [
        // Appearance section
        CupertinoListSection.insetGrouped(
          header: const Text('APPEARANCE'),
          children: [
            CupertinoListTile(
              leading: Icon(_getThemeModeIcon(themeMode)),
              title: const Text('Theme'),
              additionalInfo: Text(themeNotifier.themeModeLabel),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _showThemePicker(context),
            ),
          ],
        ),

        // Account section
        CupertinoListSection.insetGrouped(
          header: const Text('ACCOUNT'),
          children: [
            CupertinoListTile(
              leading: CircleAvatar(
                backgroundColor: CupertinoColors.systemBlue.resolveFrom(context),
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: CupertinoColors.white,
                ),
              ),
              title: Text(authState.user?.email ?? 'Not signed in'),
              subtitle: Text(
                authState.isDemoMode
                    ? 'Demo Mode'
                    : authState.isAdmin
                        ? 'Administrator'
                        : 'Canvasser',
              ),
            ),
            CupertinoListTile(
              leading: Icon(CupertinoIcons.square_arrow_right, color: CupertinoColors.destructiveRed),
              title: const Text('Sign Out', style: TextStyle(color: CupertinoColors.destructiveRed)),
              onTap: _signOut,
            ),
          ],
        ),

        // Data section
        CupertinoListSection.insetGrouped(
          header: const Text('DATA'),
          children: [
            CupertinoListTile(
              leading: Icon(CupertinoIcons.cloud_download),
              title: const Text('Refresh Data'),
              subtitle: Text('${voterState.totalVoters} voters loaded'),
              trailing: const CupertinoListTileChevron(),
              onTap: _refreshData,
            ),
            CupertinoListTile(
              leading: Icon(CupertinoIcons.trash),
              title: const Text('Clear Local Data'),
              subtitle: const Text('Remove cached data'),
              trailing: const CupertinoListTileChevron(),
              onTap: _clearLocalData,
            ),
          ],
        ),

        // Statistics section
        CupertinoListSection.insetGrouped(
          header: const Text('STATISTICS'),
          children: [
            _buildCupertinoStatRow('Total Voters', voterState.totalVoters.toString()),
            _buildCupertinoStatRow('Contacted', voterState.contactedCount.toString()),
            _buildCupertinoStatRow('Supportive', voterState.supportiveCount.toString()),
            _buildCupertinoStatRow(
              'Contact Rate',
              voterState.totalVoters > 0
                  ? '${((voterState.contactedCount / voterState.totalVoters) * 100).toStringAsFixed(1)}%'
                  : '0%',
            ),
          ],
        ),

        // About section
        CupertinoListSection.insetGrouped(
          header: const Text('ABOUT'),
          children: [
            CupertinoListTile(
              leading: Icon(CupertinoIcons.info),
              title: const Text('Version'),
              additionalInfo: Text(AppConstants.appVersion),
            ),
            CupertinoListTile(
              leading: Icon(CupertinoIcons.doc_plaintext),
              title: const Text('Terms of Service'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _showTerms(),
            ),
            CupertinoListTile(
              leading: Icon(CupertinoIcons.shield),
              title: const Text('Privacy Policy'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _showPrivacy(),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCupertinoStatRow(String label, String value) {
    return CupertinoListTile(
      title: Text(label),
      additionalInfo: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMaterialContent(AuthStateData authState, VoterState voterState) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return ListView(
      children: [
        // Appearance section
        _buildSectionHeader('Appearance'),
        ListTile(
          leading: Icon(_getThemeModeIcon(themeMode)),
          title: const Text('Theme'),
          subtitle: Text(themeNotifier.themeModeLabel),
          trailing: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Dark'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              themeNotifier.setThemeMode(selection.first);
            },
          ),
        ),
        const Divider(),

        // Account section
        _buildSectionHeader('Account'),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              AdaptiveIcons.person,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(authState.user?.email ?? 'Not signed in'),
          subtitle: Text(
            authState.isDemoMode
                ? 'Demo Mode'
                : authState.isAdmin
                    ? 'Administrator'
                    : 'Canvasser',
          ),
        ),
        ListTile(
          leading: Icon(AdaptiveIcons.logout, color: Colors.red),
          title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          onTap: _signOut,
        ),
        const Divider(),

        // Data section
        _buildSectionHeader('Data'),
        ListTile(
          leading: Icon(AdaptiveIcons.cloudDownload),
          title: const Text('Refresh Data'),
          subtitle: Text('${voterState.totalVoters} voters loaded'),
          onTap: _refreshData,
        ),
        ListTile(
          leading: Icon(AdaptiveIcons.deleteOutlined),
          title: const Text('Clear Local Data'),
          subtitle: const Text('Remove cached data'),
          onTap: _clearLocalData,
        ),
        const Divider(),

        // Statistics section
        _buildSectionHeader('Statistics'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Total Voters', voterState.totalVoters.toString()),
                  _buildStatRow('Contacted', voterState.contactedCount.toString()),
                  _buildStatRow('Supportive', voterState.supportiveCount.toString()),
                  _buildStatRow(
                    'Contact Rate',
                    voterState.totalVoters > 0
                        ? '${((voterState.contactedCount / voterState.totalVoters) * 100).toStringAsFixed(1)}%'
                        : '0%',
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(),

        // About section
        _buildSectionHeader('About'),
        ListTile(
          leading: Icon(AdaptiveIcons.infoOutlined),
          title: const Text('Version'),
          subtitle: Text(AppConstants.appVersion),
        ),
        ListTile(
          leading: Icon(AdaptiveIcons.gavel),
          title: const Text('Terms of Service'),
          onTap: () => _showTerms(),
        ),
        ListTile(
          leading: Icon(AdaptiveIcons.privacy),
          title: const Text('Privacy Policy'),
          onTap: () => _showPrivacy(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return CupertinoIcons.circle_lefthalf_fill;
      case ThemeMode.light:
        return CupertinoIcons.sun_max;
      case ThemeMode.dark:
        return CupertinoIcons.moon;
    }
  }

  void _showThemePicker(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Choose Theme'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              themeNotifier.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.circle_lefthalf_fill, size: 20),
                const SizedBox(width: 8),
                const Text('System'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              themeNotifier.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.sun_max, size: 20),
                const SizedBox(width: 8),
                const Text('Light'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              themeNotifier.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.moon, size: 20),
                const SizedBox(width: 8),
                const Text('Dark'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showTerms() {
    AdaptiveDialogs.showAlert(
      context: context,
      title: 'Terms of Service',
      content: 'This application is provided for authorized campaign volunteers only. '
          'By using this app, you agree to:\n\n'
          '1. Use voter data only for legitimate campaign purposes\n'
          '2. Not share voter data with unauthorized parties\n'
          '3. Respect voter privacy and preferences\n'
          '4. Follow all applicable election laws\n'
          '5. Report any data security concerns immediately\n\n'
          'Unauthorized use may result in account termination and legal action.',
      okText: 'Close',
    );
  }

  void _showPrivacy() {
    AdaptiveDialogs.showAlert(
      context: context,
      title: 'Privacy Policy',
      content: 'We take privacy seriously. This app:\n\n'
          '- Collects only necessary voter contact information\n'
          '- Stores data securely in encrypted cloud storage\n'
          '- Does not sell or share data with third parties\n'
          '- Tracks anonymous usage analytics to improve the app\n'
          '- Allows you to request data deletion at any time\n\n'
          'For questions about your data, contact the campaign administrator.',
      okText: 'Close',
    );
  }
}
