import '../models/api_response.dart';
import '../models/table.dart';
import 'api_client.dart';

class TableService {
  static const String _endpoint = '/tables';

  /// Get all tables
  static Future<ApiResponse<List<RestaurantTable>>> getTables({
    bool includeUnavailable = false,
  }) async {
    final queryParams = <String, String>{};
    if (includeUnavailable) {
      queryParams['includeUnavailable'] = 'true';
    }

    return await ApiClient.getList(
      _endpoint,
      (json) => RestaurantTable.fromJson(json),
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Get table by ID
  static Future<ApiResponse<RestaurantTable>> getTable(String id) async {
    return await ApiClient.get(
      '$_endpoint/$id',
      (json) => RestaurantTable.fromJson(json),
    );
  }

  /// Create a new table
  static Future<ApiResponse<RestaurantTable>> createTable({
    required String name,
    required int capacity,
    String? description,
  }) async {
    final request = CreateTableRequest(
      name: name,
      capacity: capacity,
      description: description,
    );

    return await ApiClient.post(
      _endpoint,
      request.toJson(),
      (json) => RestaurantTable.fromJson(json),
    );
  }

  /// Update an existing table
  static Future<ApiResponse<RestaurantTable>> updateTable({
    required String id,
    String? name,
    int? capacity,
    String? description,
    bool? isAvailable,
  }) async {
    final request = UpdateTableRequest(
      name: name,
      capacity: capacity,
      description: description,
      isAvailable: isAvailable,
    );

    return await ApiClient.put(
      '$_endpoint/$id',
      request.toJson(),
      (json) => RestaurantTable.fromJson(json),
    );
  }

  /// Delete a table
  static Future<ApiResponse<String>> deleteTable(String id) async {
    return await ApiClient.delete('$_endpoint/$id');
  }

  /// Get available tables only
  static Future<ApiResponse<List<RestaurantTable>>> getAvailableTables() async {
    return await getTables(includeUnavailable: false);
  }

  /// Update table availability
  static Future<ApiResponse<RestaurantTable>> updateTableAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    return await updateTable(id: id, isAvailable: isAvailable);
  }
}
