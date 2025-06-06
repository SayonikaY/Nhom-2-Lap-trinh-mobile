import '../models/api_response.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  static const String _endpoint = '/orders';

  /// Get all orders with optional filters
  static Future<ApiResponse<List<Order>>> getOrders({
    OrderStatus? status,
    String? tableId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{};

    if (status != null) {
      queryParams['status'] = status.value.toString();
    }

    if (tableId != null) {
      queryParams['tableId'] = tableId;
    }

    if (fromDate != null) {
      queryParams['fromDate'] = fromDate.toIso8601String();
    }

    if (toDate != null) {
      queryParams['toDate'] = toDate.toIso8601String();
    }

    return await ApiClient.getList(
      _endpoint,
      (json) => Order.fromJson(json),
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Get order by ID
  static Future<ApiResponse<Order>> getOrder(String id) async {
    return await ApiClient.get(
      '$_endpoint/$id',
      (json) => Order.fromJson(json),
    );
  }

  /// Create a new order
  static Future<ApiResponse<Order>> createOrder(
    CreateOrderRequest request,
  ) async {
    return await ApiClient.post(
      _endpoint,
      request.toJson(),
      (json) => Order.fromJson(json),
    );
  }

  /// Update order status
  static Future<ApiResponse<Map<String, dynamic>>> updateOrderStatus(
    String id,
    OrderStatus status,
  ) async {
    final request = UpdateOrderStatusRequest(status: status);

    return await ApiClient.put(
      '$_endpoint/$id/status',
      request.toJson(),
      (json) => json,
    );
  }

  /// Get all orders
  static Future<ApiResponse<List<Order>>> getAllOrders() async {
    return await getOrders();
  }

  /// Delete an order (only pending orders)
  static Future<ApiResponse<String>> deleteOrder(String id) async {
    return await ApiClient.delete('$_endpoint/$id');
  }

  /// Get orders by status
  static Future<ApiResponse<List<Order>>> getOrdersByStatus(
    OrderStatus status,
  ) async {
    return await getOrders(status: status);
  }

  /// Get orders by table
  static Future<ApiResponse<List<Order>>> getOrdersByTable(
    String tableId,
  ) async {
    return await getOrders(tableId: tableId);
  }

  /// Get today's orders
  static Future<ApiResponse<List<Order>>> getTodaysOrders() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return await getOrders(fromDate: startOfDay, toDate: endOfDay);
  }

  /// Get pending orders
  static Future<ApiResponse<List<Order>>> getPendingOrders() async {
    return await getOrdersByStatus(OrderStatus.pending);
  }

  /// Get in-progress orders
  static Future<ApiResponse<List<Order>>> getInProgressOrders() async {
    return await getOrdersByStatus(OrderStatus.inProgress);
  }

  /// Get completed orders
  static Future<ApiResponse<List<Order>>> getCompletedOrders() async {
    return await getOrdersByStatus(OrderStatus.completed);
  }

  /// Mark order as in progress
  static Future<ApiResponse<Map<String, dynamic>>> markOrderAsInProgress(
    String id,
  ) async {
    return await updateOrderStatus(id, OrderStatus.inProgress);
  }

  /// Mark order as completed
  static Future<ApiResponse<Map<String, dynamic>>> markOrderAsCompleted(
    String id,
  ) async {
    return await updateOrderStatus(id, OrderStatus.completed);
  }

  /// Cancel order
  static Future<ApiResponse<Map<String, dynamic>>> cancelOrder(
    String id,
  ) async {
    return await updateOrderStatus(id, OrderStatus.cancelled);
  }

  /// Get all order statuses
  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getOrderStatuses() async {
    return await ApiClient.getList(
      '$_endpoint/statuses',
      (json) => json,
      includeAuth: false,
    );
  }
}
