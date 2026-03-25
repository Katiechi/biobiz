import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router.dart';
import 'theme.dart';

class BioBizApp extends StatefulWidget {
  const BioBizApp({super.key});

  @override
  State<BioBizApp> createState() => _BioBizAppState();
}

class _BioBizAppState extends State<BioBizApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _listenForAuthEvents();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _listenForAuthEvents() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        // User clicked password reset link — navigate to reset screen
        AppRouter.router.go('/reset-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BioBiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
