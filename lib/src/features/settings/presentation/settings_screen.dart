import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/theme_controller.dart';
import '../../../core/notifications/app_messenger.dart';
import '../../../core/photos/google_photos_service.dart';
import '../../../features/settings/data/credentials_provider.dart';
import '../../../features/settings/data/app_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(appThemeControllerProvider);
    final selectedTheme = themeAsync.value ?? AppTheme.light;
    final credentialsAsync = ref.watch(credentialsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Google Photos Integration Section
          _buildSectionHeader(context, 'Google Photos Integration'),
          credentialsAsync.when(
            data: (credentials) => _buildCredentialsTile(context, ref, credentials),
            loading: () => const ListTile(
              title: Text('Loading...'),
              trailing: CircularProgressIndicator(),
            ),
            error: (err, _) => ListTile(
              title: const Text('Error loading credentials'),
              subtitle: Text('$err'),
            ),
          ),
          const Divider(height: 1),
          
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(selectedTheme.label),
            trailing: DropdownButton<AppTheme>(
              value: selectedTheme,
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(appThemeControllerProvider.notifier).setTheme(
                      value,
                    );
              },
              items: AppTheme.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          
          // Debug Section
          _buildSectionHeader(context, 'Debug'),
          Consumer(
            builder: (context, ref, child) {
              final settingsAsync = ref.watch(appSettingsProvider);
              return settingsAsync.when(
                data: (settings) => SwitchListTile(
                  title: const Text('Debug Mode'),
                  subtitle: const Text('Enable detailed logging for troubleshooting'),
                  value: settings.debugModeEnabled,
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier).toggleDebugMode(value);
                    ref.read(appMessengerProvider).showToast(
                      value ? 'Debug mode enabled' : 'Debug mode disabled',
                    );
                  },
                ),
                loading: () => const ListTile(
                  title: Text('Debug Mode'),
                  trailing: CircularProgressIndicator(),
                ),
                error: (err, stack) => const ListTile(
                  title: Text('Debug Mode'),
                  subtitle: Text('Error loading settings'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('View Debug Logs'),
            subtitle: const Text('See detailed error logs'),
            trailing: const Icon(Icons.list_alt),
            onTap: () => _showDebugLogs(context, ref),
          ),
          ListTile(
            title: const Text('Clear Debug Logs'),
            subtitle: const Text('Remove all stored logs'),
            onTap: () {
              ref.read(debugLogsProvider.notifier).state = [];
              ref.read(appMessengerProvider).showToast('Debug logs cleared');
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildCredentialsTile(
    BuildContext context,
    WidgetRef ref,
    CredentialsState credentials,
  ) {
    if (credentials.hasCredentials) {
      return ListTile(
        title: const Text('Google OAuth Client ID'),
        subtitle: Text(
          credentials.clientId!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _showEditDialog(context, ref, credentials.clientId),
              child: const Text('Edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Configure Google Photos'),
          subtitle: const Text('Add your OAuth Client ID to connect'),
          trailing: FilledButton(
            onPressed: () => _showEditDialog(context, ref, null),
            child: const Text('Add'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            onPressed: () => _showSha1Helper(context),
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('Need help finding your SHA-1?'),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String? existingId) {
    final controller = TextEditingController(text: existingId ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingId == null ? 'Add OAuth Client ID' : 'Update OAuth Client ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                hintText: '1234567890-abc123.apps.googleusercontent.com',
                helperText: 'From Google Cloud Console',
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            const Text(
              'How to get your Client ID:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Go to Google Cloud Console\n'
              '2. Create a new project\n'
              '3. Enable Photos Library API\n'
              '4. Create OAuth credentials\n'
              '5. Copy the Client ID',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final clientId = controller.text.trim();
              if (clientId.isEmpty) {
                ref.read(appMessengerProvider).showToast(
                  'Client ID cannot be empty',
                );
                return;
              }
              
              Navigator.pop(context);
              await ref.read(credentialsProvider.notifier).saveClientId(clientId);
              
              final currentState = ref.read(credentialsProvider).valueOrNull;
              if (currentState?.hasCredentials == true) {
                ref.read(appMessengerProvider).showToast(
                  'Client ID saved successfully',
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Credentials?'),
        content: const Text(
          'This will remove your stored Google OAuth Client ID. '
          'You\'ll need to reconfigure it to access Google Photos again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(credentialsProvider.notifier).clearCredentials();
              ref.read(appMessengerProvider).showToast(
                'Credentials removed',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDebugLogs(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(debugLogsProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Debug Logs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${logs.length} entries'),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // TODO: Add clipboard support to copy logs
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet.\nEnable debug mode and try signing in.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[logs.length - 1 - index]; // Reverse order
                          return ExpansionTile(
                            title: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: log.level == 'ERROR' ? Colors.red : Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              log.timestamp.toLocal().toString().split('.').first,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Level: ${log.level}'),
                                    const SizedBox(height: 8),
                                    Text('Message: ${log.message}'),
                                    if (log.error != null) ...[
                                      const SizedBox(height: 8),
                                      const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(log.error.toString(), style: const TextStyle(color: Colors.red)),
                                    ],
                                    if (log.stackTrace != null) ...[
                                      const SizedBox(height: 8),
                                      const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(log.stackTrace.toString(), style: const TextStyle(fontSize: 10)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSha1Helper(BuildContext context) {
    const sha1Command = './gradlew signingReport';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get Your SHA-1 Fingerprint'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Google requires your SHA-1 fingerprint for Android OAuth. Here's how to get it:",
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Step 1: Run this command',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sha1Command,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.green,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                      onPressed: () {
                        // Copy to clipboard would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Command copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Step 2: Find this in the output',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variant: debug',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Text('Config: debug'),
                    const SizedBox(height: 4),
                    Text(
                      'SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Step 3: Paste in Google Cloud Console',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'When creating your Android OAuth credential, paste the SHA-1 value (without quotes).',
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Release builds need a separate SHA-1 from your release keystore.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
