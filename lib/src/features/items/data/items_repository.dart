import '../domain/item.dart';
import 'items_api.dart';

class ItemsRepository {
  ItemsRepository(this._api);

  final ItemsApi _api;

  Future<List<Item>> list() => _api.list();

  Future<Item> getById(String id) => _api.getById(id);
}
