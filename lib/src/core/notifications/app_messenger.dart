import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized place to show SnackBars / Banners without threading BuildContext
/// through every layer.
final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

final appMessengerProvider = Provider<AppMessenger>((ref) {
  final key = ref.watch(scaffoldMessengerKeyProvider);
  return AppMessenger._(key);
});

class AppMessenger {
  AppMessenger._(this._key);

  final GlobalKey<ScaffoldMessengerState> _key;

  ScaffoldMessengerState? get _messenger => _key.currentState;

  void showToast(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = _messenger;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
        ),
      );
  }

  void showBanner(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = _messenger;
    if (messenger == null) return;

    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          content: Text(message),
          actions: [
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentMaterialBanner();
                  onAction();
                },
                child: Text(actionLabel),
              ),
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
  }

  void dismissBanner() {
    _messenger?.hideCurrentMaterialBanner();
  }
}
