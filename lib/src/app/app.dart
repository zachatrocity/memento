import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../core/notifications/app_messenger.dart';
import 'router.dart';
import 'app_theme.dart';
import 'theme_controller.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final config = ref.watch(appConfigProvider);
    final messengerKey = ref.watch(scaffoldMessengerKeyProvider);

    final themeAsync = ref.watch(appThemeControllerProvider);
    final theme = themeAsync.value ?? AppTheme.light;

    return MaterialApp.router(
      title: config.appName,
      theme: buildTheme(theme),
      scaffoldMessengerKey: messengerKey,
      routerConfig: router,
    );
  }
}
