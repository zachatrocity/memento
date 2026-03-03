import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/secure_storage_provider.dart';
import 'app_theme.dart';

final appThemeControllerProvider =
    AsyncNotifierProvider<AppThemeController, AppTheme>(
  AppThemeController.new,
);

class AppThemeController extends AsyncNotifier<AppTheme> {
  static const _key = 'app_theme';

  @override
  Future<AppTheme> build() async {
    try {
      final store = ref.watch(secureStoreProvider);
      final existing = await store.read(_key);
      if (existing == null || existing.isEmpty) return AppTheme.light;
      return AppThemeX.fromString(existing);
    } catch (e) {
      // If secure storage fails on startup, use default theme
      return AppTheme.light;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    final store = ref.read(secureStoreProvider);
    state = AsyncData(theme);
    await store.write(_key, theme.name);
  }
}
