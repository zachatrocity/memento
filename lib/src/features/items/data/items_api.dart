import 'package:dio/dio.dart';

import '../../../core/errors/dio_exception_mapper.dart';
import '../../../features/items/domain/item.dart';

abstract class ItemsApi {
  Future<List<Item>> list();
  Future<Item> getById(String id);
}

class DioItemsApi implements ItemsApi {
  DioItemsApi(this._dio);

  final Dio _dio;

  @override
  Future<List<Item>> list() async {
    try {
      final res = await _dio.get<List<dynamic>>('/items');
      final data = res.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Item.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Item> getById(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/items/$id');
      return Item.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
