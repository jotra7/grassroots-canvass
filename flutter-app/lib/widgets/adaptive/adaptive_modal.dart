import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_utils.dart';

/// Utility class for showing platform-adaptive modal sheets.
class AdaptiveModal {
  /// Shows a modal bottom sheet.
  /// Uses showModalBottomSheet on Android/Web and showCupertinoModalPopup on iOS/macOS.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    Color? backgroundColor,
    double? height,
  }) {
    if (PlatformUtils.isApple) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => Container(
          height: height ?? MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: backgroundColor ?? CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: SafeArea(
            top: false,
            child: child,
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => child,
    );
  }

  /// Shows a draggable scrollable modal sheet.
  static Future<T?> showDraggable<T>({
    required BuildContext context,
    required Widget Function(ScrollController) builder,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    if (PlatformUtils.isApple) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: builder(scrollController),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (context, scrollController) => builder(scrollController),
      ),
    );
  }

  /// Shows a full-screen modal.
  static Future<T?> showFullScreen<T>({
    required BuildContext context,
    required Widget child,
  }) {
    if (PlatformUtils.isApple) {
      return Navigator.of(context).push<T>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => child,
        ),
      );
    }

    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => child,
      ),
    );
  }
}
