import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_env.dart';

class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableNetworkLogging,
    required this.useFakeBackend,
  });

  final AppEnv env;
  final String apiBaseUrl;
  final String appName;
  final bool enableNetworkLogging;
  final bool useFakeBackend;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  const baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

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
  );
});
