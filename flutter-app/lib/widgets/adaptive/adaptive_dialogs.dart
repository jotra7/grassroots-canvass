import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../utils/platform_utils.dart';

/// Utility class for showing platform-adaptive dialogs.
class AdaptiveDialogs {
  /// Shows a confirmation dialog with cancel and confirm actions.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) {
    return showPlatformDialog<bool>(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          PlatformDialogAction(
            onPressed: () => Navigator.pop(context, true),
            cupertino: (_, __) => CupertinoDialogActionData(
              isDestructiveAction: isDestructive,
            ),
            material: (_, __) => MaterialDialogActionData(
              style: isDestructive
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Shows a simple alert dialog with an OK button.
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String okText = 'OK',
  }) {
    return showPlatformDialog<void>(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(okText),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog with custom content.
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showPlatformDialog<T>(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
      ),
    );
  }

  /// Shows an action sheet (iOS) or bottom sheet dialog (Android).
  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<AdaptiveAction<T>> actions,
    String cancelText = 'Cancel',
  }) {
    if (PlatformUtils.isApple) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          message: message != null ? Text(message) : null,
          actions: actions
              .map(
                (action) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context, action.value),
                  isDestructiveAction: action.isDestructive,
                  child: Text(action.label),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const Divider(),
            ...actions.map(
              (action) => ListTile(
                title: Text(
                  action.label,
                  style: TextStyle(
                    color: action.isDestructive ? Colors.red : null,
                  ),
                ),
                leading: action.icon != null ? Icon(action.icon) : null,
                onTap: () => Navigator.pop(context, action.value),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(cancelText),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents an action in an action sheet.
class AdaptiveAction<T> {
  const AdaptiveAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool isDestructive;
}
