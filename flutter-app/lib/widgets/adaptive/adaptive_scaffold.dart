import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../config/adaptive_theme.dart';

/// An adaptive scaffold that provides platform-specific styling.
/// Uses Material Scaffold on Android/Web and CupertinoPageScaffold on iOS/macOS.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: title != null
          ? PlatformAppBar(
              title: Text(title!),
              leading: leading,
              trailingActions: actions,
              cupertino: (_, __) => CupertinoNavigationBarData(
                backgroundColor: AdaptiveTheme.primaryOrange,
                brightness: Brightness.dark,
              ),
              material: (_, __) => MaterialAppBarData(
                centerTitle: true,
              ),
            )
          : null,
      body: body,
      backgroundColor: backgroundColor,
      bottomNavBar: bottomNavBar != null
          ? PlatformNavBar(
              material: (_, __) => MaterialNavBarData(
                height: 80,
              ),
              cupertino: (_, __) => CupertinoTabBarData(),
              items: const [],
            )
          : null,
      material: (_, __) => MaterialScaffoldData(
        floatingActionButton: floatingActionButton,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
      cupertino: (_, __) => CupertinoPageScaffoldData(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}
