import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class DaansetuApp extends ConsumerWidget {
  const DaansetuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'DAANSETU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,  // Using light theme by default for Zomato-style
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,  // Light mode for clean Zomato look
      routerConfig: router,
    );
  }
}
