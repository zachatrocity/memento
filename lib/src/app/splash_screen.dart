import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import 'router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  void _go(String location) {
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(location);
  }

  void _start() {
    final config = ref.read(appConfigProvider);

    if (!config.enableAuth) {
      // Basic app mode: show splash briefly, then go home.
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        _go(const HomeRoute().location);
      });
      return;
    }

    // Auth-enabled mode: go_router redirect handles navigation once auth is ready.
    // We just render the splash UI while auth hydrates.
  }

  @override
  Widget build(BuildContext context) {
    // Asset will be added in this PR (copied from dev/site).
    // Keep a progress indicator as a safe fallback.
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/brand/splashpad.png',
              width: 140,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
