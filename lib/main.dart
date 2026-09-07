import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/core/routes/app_route.dart';
import 'package:safe_watch/core/theme/theme.dart';

/// Safe Watch — Entry Point
///
/// Fluxo principal do app:
/// 1. [ProviderScope] envelopa todo o app para habilitar Riverpod
/// 2. [MaterialApp.router] usa [GoRouter] para navegação declarativa
/// 3. [SwTheme] aplica o tema visual do design system
void main() {
  runApp(
    const ProviderScope(
      child: SafeWatchApp(),
    ),
  );
}

/// Root widget do aplicativo Safe Watch.
///
/// Usa [MaterialApp.router] com [GoRouter] para navegação
/// e aplica o tema do design system via [SwTheme].
class SafeWatchApp extends StatelessWidget {
  const SafeWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Safe Watch',
      debugShowCheckedModeBanner: false,
      theme: SwTheme.lightTheme,
      darkTheme: SwTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
