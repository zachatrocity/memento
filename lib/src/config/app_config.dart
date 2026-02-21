import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_env.dart';

class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableNetworkLogging,
    required this.useFakeBackend,
    required this.enableAuth,
  });

  final AppEnv env;
  final String apiBaseUrl;
  final String appName;
  final bool enableNetworkLogging;
  final bool useFakeBackend;

  /// When false, the template runs as a basic app without any login flow.
  ///
  /// IMPORTANT: This is a *product mode* toggle, not a security boundary.
  /// Backends must still enforce authorization server-side.
  final bool enableAuth;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  const baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Default OFF so the template works out-of-the-box for "no auth" apps.
  const enableAuth = bool.fromEnvironment('ENABLE_AUTH', defaultValue: false);

  final env = AppEnv.fromString(envName);

  final defaultBaseUrl = switch (env) {
    AppEnv.dev => 'mock://',
    AppEnv.stage => 'https://api.stage.example.com',
    AppEnv.prod => 'https://api.example.com',
  };

  final apiBaseUrl = baseUrlOverride.isNotEmpty
      ? baseUrlOverride
      : defaultBaseUrl;

  final appName = switch (env) {
    AppEnv.dev => 'Swell (Dev)',
    AppEnv.stage => 'Swell (Stage)',
    AppEnv.prod => 'Swell',
  };

  return AppConfig(
    env: env,
    apiBaseUrl: apiBaseUrl,
    appName: appName,
    enableNetworkLogging: env != AppEnv.prod,
    useFakeBackend: env == AppEnv.dev && apiBaseUrl.startsWith('mock'),
    enableAuth: enableAuth,
  );
});
