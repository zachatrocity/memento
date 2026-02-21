import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    // Avoid instantiating auth machinery when auth is disabled.
    final auth = config.enableAuth ? ref.watch(authControllerProvider) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Environment'),
            subtitle: Text(config.env.name),
          ),
          ListTile(
            title: const Text('API base URL'),
            subtitle: Text(config.apiBaseUrl),
          ),
          if (config.enableAuth) ...[
            const Divider(height: 1),
            ListTile(
              title: const Text('Logout'),
              subtitle: const Text('Clear stored token and return to login'),
              trailing: auth!.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: auth.isLoading
                  ? null
                  : () async {
                      await ref.read(authControllerProvider.notifier).logout();
                    },
            ),
          ],
        ],
      ),
    );
  }
}
