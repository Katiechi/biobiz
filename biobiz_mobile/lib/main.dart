import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/services/guest_mode_service.dart';

// BioBiz Supabase Configuration
const supabaseUrl = 'https://drlkcvsgxqmayxzzrjmu.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRybGtjdnNneHFtYXl4enpyam11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NDA1NjksImV4cCI6MjA4OTMxNjU2OX0.vRdOoMBVlVAFHfHnc8vF6mOZNWZU3ve9DPTw01MH14M';

void main() async {
  print('Supabase URL: $supabaseUrl');
  print('Supabase Key length: ${supabaseAnonKey.length}');
  print('Supabase Key first 20 chars: ${supabaseAnonKey.substring(0, 20)}');
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize Guest Mode Service for local storage
  await GuestModeService().initialize();

  runApp(const ProviderScope(child: BioBizApp()));
}
