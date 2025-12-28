import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum AppPlatform { ios, android, macos, linux, windows, web }

class PlatformUtils {
  /// Returns true on iOS or macOS (Apple platforms)
  static bool get isApple {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Returns true on Android, Linux, Windows, or Web (Material platforms)
  static bool get isMaterial => !isApple;

  /// Returns true when running on web
  static bool get isWeb => kIsWeb;

  /// Returns true on mobile platforms (iOS or Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Returns true on desktop platforms (macOS, Linux, Windows)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  /// Returns true on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Returns true on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Returns true on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Returns the current platform as an enum
  static AppPlatform get current {
    if (kIsWeb) return AppPlatform.web;
    if (Platform.isIOS) return AppPlatform.ios;
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isMacOS) return AppPlatform.macos;
    if (Platform.isLinux) return AppPlatform.linux;
    return AppPlatform.windows;
  }
}
