//Scam Radar Mobile Application main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize notifications
  await NotificationService().initialize();

  // Request runtime permissions
  await PermissionService.requestAll();

  runApp(const ProviderScope(child: ScamRadarApp()));
}
