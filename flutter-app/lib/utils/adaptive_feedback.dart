import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

/// Provides platform-adaptive feedback mechanisms like toasts and snackbars.
class AdaptiveFeedback {
  static OverlayEntry? _currentToast;
  static Timer? _toastTimer;

  /// Shows a brief message to the user.
  /// Uses SnackBar on Android/Web and a custom toast overlay on iOS/macOS.
  static void showMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    if (PlatformUtils.isApple) {
      _showIOSToast(context, message, duration: duration);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: onAction != null && actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction,
                )
              : null,
        ),
      );
    }
  }

  /// Shows an error message.
  static void showError(BuildContext context, String message) {
    if (PlatformUtils.isApple) {
      _showIOSToast(
        context,
        message,
        backgroundColor: CupertinoColors.systemRed,
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Shows a success message.
  static void showSuccess(BuildContext context, String message) {
    if (PlatformUtils.isApple) {
      _showIOSToast(
        context,
        message,
        backgroundColor: CupertinoColors.systemGreen,
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  /// Shows an iOS-style toast notification.
  static void _showIOSToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    // Remove any existing toast
    _dismissCurrentToast();

    final overlay = Overlay.of(context);

    _currentToast = OverlayEntry(
      builder: (context) => _IOSToast(
        message: message,
        backgroundColor: backgroundColor,
      ),
    );

    overlay.insert(_currentToast!);

    _toastTimer = Timer(duration, _dismissCurrentToast);
  }

  static void _dismissCurrentToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _currentToast?.remove();
    _currentToast = null;
  }
}

class _IOSToast extends StatefulWidget {
  const _IOSToast({
    required this.message,
    this.backgroundColor,
  });

  final String message;
  final Color? backgroundColor;

  @override
  State<_IOSToast> createState() => _IOSToastState();
}

class _IOSToastState extends State<_IOSToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ??
                        CupertinoColors.systemGrey.darkColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
