import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_constants.dart';
import '../../utils/platform_utils.dart';
import '../../utils/adaptive_icons.dart';
import '../../widgets/adaptive/adaptive_buttons.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);
    final isApple = PlatformUtils.isApple;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text(AppConstants.appName),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(AdaptiveIcons.refresh),
            onPressed: () => authNotifier.refreshProfile(),
            material: (_, __) => MaterialIconButtonData(
              tooltip: 'Refresh Status',
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AdaptiveIcons.hourglass,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Pending Approval',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is waiting for admin approval. '
                'You will be able to access the app once approved.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              AdaptiveOutlinedButton(
                onPressed: () => authNotifier.refreshProfile(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AdaptiveIcons.refresh, size: 18),
                    const SizedBox(width: 8),
                    const Text('Check Status'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdaptiveTextButton(
                onPressed: () => authNotifier.signOut(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AdaptiveIcons.logout, size: 18),
                    const SizedBox(width: 8),
                    const Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
