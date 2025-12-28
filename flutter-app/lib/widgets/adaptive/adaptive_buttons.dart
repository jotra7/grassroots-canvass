import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../config/adaptive_theme.dart';
import '../../utils/platform_utils.dart';

/// An adaptive filled/elevated button.
/// Uses FilledButton on Android/Web and CupertinoButton.filled on iOS/macOS.
class AdaptiveFilledButton extends StatelessWidget {
  const AdaptiveFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApple) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        padding: padding,
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: color != null
          ? FilledButton.styleFrom(backgroundColor: color)
          : null,
      child: child,
    );
  }
}

/// An adaptive outlined button.
/// Uses OutlinedButton on Android/Web and CupertinoButton on iOS/macOS.
class AdaptiveOutlinedButton extends StatelessWidget {
  const AdaptiveOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApple) {
      return CupertinoButton(
        onPressed: onPressed,
        padding: padding,
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

/// An adaptive text button.
/// Uses TextButton on Android/Web and CupertinoButton on iOS/macOS.
class AdaptiveTextButton extends StatelessWidget {
  const AdaptiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return PlatformTextButton(
      onPressed: onPressed,
      padding: padding,
      child: child,
    );
  }
}

/// An adaptive icon button.
/// Uses IconButton on Android/Web and CupertinoButton on iOS/macOS.
class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return PlatformIconButton(
      onPressed: onPressed,
      icon: icon,
      color: color,
      material: (_, __) => MaterialIconButtonData(
        tooltip: tooltip,
      ),
      cupertino: (_, __) => CupertinoIconButtonData(
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// An adaptive floating action button.
/// Uses FloatingActionButton on Android/Web and a styled CupertinoButton on iOS/macOS.
class AdaptiveFloatingButton extends StatelessWidget {
  const AdaptiveFloatingButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.mini = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApple) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          width: mini ? 44 : 56,
          height: mini ? 44 : 56,
          decoration: BoxDecoration(
            color: AdaptiveTheme.primaryOrange,
            borderRadius: BorderRadius.circular(mini ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: mini ? 20 : 24,
          ),
        ),
      );
    }

    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
      );
    }

    return mini
        ? FloatingActionButton.small(
            onPressed: onPressed,
            child: Icon(icon),
          )
        : FloatingActionButton(
            onPressed: onPressed,
            child: Icon(icon),
          );
  }
}
