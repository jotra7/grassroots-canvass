import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../utils/platform_utils.dart';
import '../utils/adaptive_icons.dart';
import '../utils/adaptive_colors.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    if (connectivity.isOnline && connectivity.pendingUpdates == 0) {
      return const SizedBox.shrink();
    }

    final isApple = PlatformUtils.isApple;
    final colors = AdaptiveColors.of(context);
    final isDark = colors.isDark;

    return Material(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: connectivity.isOnline
            ? (isDark ? Colors.orange.shade800 : Colors.orange.shade700)
            : (isDark ? Colors.red.shade800 : Colors.red.shade700),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  connectivity.isOnline
                      ? AdaptiveIcons.cloudSync
                      : AdaptiveIcons.cloudOff,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getMessage(connectivity),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!connectivity.isOnline)
                  isApple
                      ? CupertinoButton(
                          onPressed: () => _retry(ref),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minSize: 0,
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: () => _retry(ref),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMessage(ConnectivityState connectivity) {
    if (!connectivity.isOnline) {
      return 'Offline - Changes saved locally';
    }
    if (connectivity.pendingUpdates > 0) {
      return 'Syncing ${connectivity.pendingUpdates} pending update${connectivity.pendingUpdates > 1 ? 's' : ''}...';
    }
    return '';
  }

  void _retry(WidgetRef ref) {
    ref.read(connectivityProvider.notifier).setOnline(true);
  }
}
