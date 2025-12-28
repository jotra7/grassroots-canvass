import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.projectURL,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Analytics
  await AnalyticsService().initialize();

  // Initialize Push Notifications (Firebase)
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: GrassrootsCanvassApp(),
    ),
  );
}
