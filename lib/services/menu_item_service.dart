import '../models/api_response.dart';
import '../models/menu_item.dart';
import 'api_client.dart';

class MenuItemService {
  static const String _endpoint = '/menuitems';

  /// Get all menu items
  static Future<ApiResponse<List<MenuItem>>> getMenuItems({
    ItemKind? kind,
    bool includeUnavailable = false,
  }) async {
    final queryParams = <String, String>{};

    if (kind != null) {
      queryParams['kind'] = kind.value.toString();
    }

    if (includeUnavailable) {
      queryParams['includeUnavailable'] = 'true';
    }

    return await ApiClient.getList(
      _endpoint,
      (json) => MenuItem.fromJson(json),
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Get menu item by ID
  static Future<ApiResponse<MenuItem>> getMenuItem(String id) async {
    return await ApiClient.get(
      '$_endpoint/$id',
      (json) => MenuItem.fromJson(json),
    );
  }

  /// Create a new menu item
  static Future<ApiResponse<MenuItem>> createMenuItem(
    CreateMenuItemRequest request,
  ) async {
    return await ApiClient.post(
      _endpoint,
      request.toJson(),
      (json) => MenuItem.fromJson(json),
    );
  }

  /// Update an existing menu item
  static Future<ApiResponse<MenuItem>> updateMenuItem(
    String id,
    UpdateMenuItemRequest request,
  ) async {
    return await ApiClient.put(
      '$_endpoint/$id',
      request.toJson(),
      (json) => MenuItem.fromJson(json),
    );
  }

  /// Get all menu items
  static Future<ApiResponse<List<MenuItem>>> getAllMenuItems() async {
    return await getMenuItems(includeUnavailable: true);
  }

  /// Delete a menu item
  static Future<ApiResponse<String>> deleteMenuItem(String id) async {
    return await ApiClient.delete('$_endpoint/$id');
  }

  /// Get available menu items only
  static Future<ApiResponse<List<MenuItem>>> getAvailableMenuItems({
    ItemKind? kind,
  }) async {
    return await getMenuItems(kind: kind, includeUnavailable: false);
  }

  /// Get menu items by category
  static Future<ApiResponse<List<MenuItem>>> getMenuItemsByKind(
    ItemKind kind,
  ) async {
    return await getMenuItems(kind: kind);
  }

  /// Update menu item availability
  static Future<ApiResponse<MenuItem>> updateMenuItemAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    return await updateMenuItem(
      id,
      UpdateMenuItemRequest(isAvailable: isAvailable),
    );
  }

  /// Get all item kinds/categories
  static Future<ApiResponse<List<Map<String, dynamic>>>> getItemKinds() async {
    return await ApiClient.getList(
      '$_endpoint/kinds',
      (json) => json,
      includeAuth: false,
    );
  }
}
