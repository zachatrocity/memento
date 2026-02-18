import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_providers.dart';
import 'data/items_api.dart';
import 'data/items_repository.dart';
import 'domain/item.dart';

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ItemsRepository(DioItemsApi(dio));
});

final itemsListProvider = FutureProvider<List<Item>>((ref) {
  return ref.watch(itemsRepositoryProvider).list();
});

final itemDetailProvider = FutureProvider.family<Item, String>((ref, id) {
  return ref.watch(itemsRepositoryProvider).getById(id);
});
