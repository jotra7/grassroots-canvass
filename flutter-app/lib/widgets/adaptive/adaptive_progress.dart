import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_utils.dart';

/// An adaptive circular progress indicator.
/// Uses CircularProgressIndicator on Android/Web and CupertinoActivityIndicator on iOS/macOS.
class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.radius = 10.0,
  });

  /// If non-null, the progress indicator displays progress as a percentage.
  /// If null, shows an indeterminate indicator.
  final double? value;

  /// The color of the progress indicator.
  final Color? color;

  /// The radius of the indicator (iOS only).
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApple) {
      return CupertinoActivityIndicator(
        color: color,
        radius: radius,
      );
    }

    return CircularProgressIndicator(
      value: value,
      color: color,
    );
  }
}

/// An adaptive linear progress indicator.
/// Note: iOS doesn't have a native linear progress indicator,
/// so Material design is used on all platforms.
class AdaptiveLinearProgress extends StatelessWidget {
  const AdaptiveLinearProgress({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
  });

  /// If non-null, the progress indicator displays progress as a percentage.
  /// If null, shows an indeterminate indicator.
  final double? value;

  /// The color of the progress bar.
  final Color? color;

  /// The background color of the track.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // iOS doesn't have a native linear progress indicator
    // Use Material design on all platforms
    return LinearProgressIndicator(
      value: value,
      color: color,
      backgroundColor: backgroundColor,
    );
  }
}

/// A loading overlay that shows a centered progress indicator.
class AdaptiveLoadingOverlay extends StatelessWidget {
  const AdaptiveLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
  });

  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdaptiveProgressIndicator(radius: 14),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color: PlatformUtils.isApple
                      ? CupertinoColors.white
                      : Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
