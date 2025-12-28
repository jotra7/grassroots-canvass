// Basic Flutter widget test for Grassroots Canvass app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:grassroots_canvass/providers/auth_provider.dart';
import 'package:grassroots_canvass/screens/auth/auth_screen.dart';

void main() {
  testWidgets('AuthScreen builds without error', (WidgetTester tester) async {
    // Build just the auth screen without initializing Supabase
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override auth provider to avoid Supabase initialization
          authProvider.overrideWith(() => TestAuthNotifier()),
        ],
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    // Wait for widget to settle
    await tester.pump();

    // Verify that the auth screen builds
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}

// Test auth notifier that doesn't try to connect to Supabase
class TestAuthNotifier extends AuthNotifier {
  @override
  AuthStateData build() {
    // Return a simple not authenticated state without initializing Supabase
    return const AuthStateData(
      isLoading: false,
      isAuthenticated: false,
      isPendingApproval: false,
      errorMessage: null,
      user: null,
      isDemoMode: false,
      isAdmin: false,
    );
  }
}
