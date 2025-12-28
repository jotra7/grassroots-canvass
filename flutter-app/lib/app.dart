import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/adaptive_theme.dart';
import 'config/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/platform_utils.dart';

class GrassrootsCanvassApp extends ConsumerWidget {
  const GrassrootsCanvassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    return PlatformProvider(
      settings: PlatformSettingsData(
        iosUsesMaterialWidgets: false,
        iosUseZeroPaddingForAppbarPlatformIcon: true,
      ),
      builder: (context) => PlatformTheme(
        themeMode: themeMode,
        materialLightTheme: AdaptiveTheme.lightMaterial,
        materialDarkTheme: AdaptiveTheme.darkMaterial,
        cupertinoLightTheme: AdaptiveTheme.lightCupertino,
        cupertinoDarkTheme: AdaptiveTheme.darkCupertino,
        builder: (context) => PlatformApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          home: _buildHome(authState),
        ),
      ),
    );
  }

  Widget _buildHome(AuthStateData authState) {
    if (authState.isLoading) {
      return PlatformScaffold(
        body: Center(
          child: PlatformUtils.isApple
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const HomeScreen();
    }

    if (authState.isPendingApproval) {
      return const PendingApprovalScreen();
    }

    return const AuthScreen();
  }
}
