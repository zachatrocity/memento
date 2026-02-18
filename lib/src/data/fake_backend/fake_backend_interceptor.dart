import 'dart:math';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class FakeBackendInterceptor extends Interceptor {
  FakeBackendInterceptor({required Logger logger}) : _logger = logger;

  final Logger _logger;

  static final _items = List.generate(
    20,
    (i) => {
      'id': '${i + 1}',
      'title': 'Item ${i + 1}',
      'subtitle': 'This is a mocked item from the dev fake backend.',
      'body': 'Detail text for item ${i + 1}.',
    },
  );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Simulate network latency.
    await Future<void>.delayed(
      Duration(milliseconds: 250 + Random().nextInt(250)),
    );

    try {
      final path = options.path;

      if (options.method == 'POST' && path == '/auth/login') {
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {'token': 'dev-token'},
          ),
        );
        return;
      }

      if (options.method == 'GET' && path == '/items') {
        handler.resolve(
          Response<List<dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: _items,
          ),
        );
        return;
      }

      final itemMatch = RegExp(r'^/items/(\\w+)$').firstMatch(path);
      if (options.method == 'GET' && itemMatch != null) {
        final id = itemMatch.group(1)!;
        final item = _items.cast<Map<String, dynamic>>().firstWhere(
          (it) => it['id'] == id,
          orElse: () => {},
        );

        if (item.isEmpty) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 404,
              data: {'message': 'Not found'},
            ),
          );
          return;
        }

        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: item,
          ),
        );
        return;
      }

      // Unknown route - pass through to real backend.
      handler.next(options);
    } catch (e, st) {
      _logger.e('Fake backend error', error: e, stackTrace: st);
      handler.next(options);
    }
  }
}
