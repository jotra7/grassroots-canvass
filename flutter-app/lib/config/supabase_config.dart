/// Supabase configuration
///
/// Replace these values with your own Supabase project credentials.
/// You can find these in your Supabase dashboard under Project Settings > API.
///
/// For production builds, consider using --dart-define flags:
/// flutter run --dart-define=SUPABASE_URL=https://yourproject.supabase.co --dart-define=SUPABASE_ANON_KEY=your_key
///
/// Or update these constants directly for development.
class SupabaseConfig {
  // Your Supabase project URL (found in Project Settings > API)
  static const String projectURL = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  // Your Supabase anon/public key (found in Project Settings > API)
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  static bool get isConfigured =>
      projectURL.isNotEmpty &&
      !projectURL.contains('your-project') &&
      anonKey.isNotEmpty &&
      !anonKey.contains('your-anon-key');

  // Demo account credentials (for App Store / Play Store review)
  // Set these via environment variables or --dart-define flags:
  // flutter run --dart-define=DEMO_EMAIL=demo@example.com --dart-define=DEMO_PASSWORD=your_password
  static const String demoEmail = String.fromEnvironment(
    'DEMO_EMAIL',
    defaultValue: '',
  );

  static const String demoPassword = String.fromEnvironment(
    'DEMO_PASSWORD',
    defaultValue: '',
  );

  static bool get hasDemoAccount => demoEmail.isNotEmpty && demoPassword.isNotEmpty;
}
