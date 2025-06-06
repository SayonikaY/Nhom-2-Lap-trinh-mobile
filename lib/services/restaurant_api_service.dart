import '../models/api_response.dart';
import '../models/employee.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table.dart';
import 'auth_service.dart';
import 'menu_item_service.dart';
import 'order_service.dart';
import 'table_service.dart';

/// Central service manager that provides access to all API services
class RestaurantApiService {
  // Private constructor
  RestaurantApiService._();

  // Singleton instance
  static final RestaurantApiService _instance = RestaurantApiService._();

  static RestaurantApiService get instance => _instance;

  // Service instances
  static const auth = AuthService;
  static const tables = TableService;
  static const menuItems = MenuItemService;
  static const orders = OrderService;

  /// Initialize the API service with base configuration
  static void initialize({String? baseUrl, String? authToken}) {
    if (authToken != null) {
      AuthService.logout(); // Clear any existing token
      // Set the token directly if provided
      // This would typically be loaded from secure storage
    }
  }

  /// Check if the service is authenticated
  static bool get isAuthenticated => AuthService.isAuthenticated;

  /// Get current auth token
  static String? get authToken => AuthService.authToken;

  /// Login and get user data
  static Future<ApiResponse<LoginResponse>> login({
    required String username,
    required String password,
  }) async {
    return await AuthService.login(username: username, password: password);
  }

  /// Logout and clear session
  static Future<void> logout() async {
    await AuthService.logout();
  }

  /// Get current user profile
  static Future<ApiResponse<Employee>> getCurrentUser() async {
    return await AuthService.getProfile();
  }

  // Convenience methods for common operations

  /// Get all available tables
  static Future<ApiResponse<List<RestaurantTable>>> getAvailableTables() async {
    return await TableService.getAvailableTables();
  }

  /// Get all available menu items
  static Future<ApiResponse<List<MenuItem>>> getAvailableMenuItems() async {
    return await MenuItemService.getAvailableMenuItems();
  }

  /// Get menu items by category
  static Future<ApiResponse<List<MenuItem>>> getMenuItemsByCategory(
    ItemKind kind,
  ) async {
    return await MenuItemService.getMenuItemsByKind(kind);
  }

  /// Get today's orders
  static Future<ApiResponse<List<Order>>> getTodaysOrders() async {
    return await OrderService.getTodaysOrders();
  }

  /// Get pending orders
  static Future<ApiResponse<List<Order>>> getPendingOrders() async {
    return await OrderService.getPendingOrders();
  }

  /// Create a new order
  static Future<ApiResponse<Order>> createOrder({
    required String tableId,
    String? note,
    required List<({String menuItemId, int quantity})> items,
  }) async {
    return await OrderService.createOrder(
      CreateOrderRequest(
        tableId: tableId,
        note: note,
        items:
            items
                .map(
                  (item) => CreateOrderDetailRequest(
                    menuItemId: item.menuItemId,
                    quantity: item.quantity,
                  ),
                )
                .toList(),
      ),
    );
  }

  /// Update order status
  static Future<ApiResponse<Map<String, dynamic>>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    return await OrderService.updateOrderStatus(orderId, status);
  }

  /// Get orders for a specific table
  static Future<ApiResponse<List<Order>>> getTableOrders(String tableId) async {
    return await OrderService.getOrdersByTable(tableId);
  }

  /// Get detailed order information
  static Future<ApiResponse<Order>> getOrderDetails(String orderId) async {
    return await OrderService.getOrder(orderId);
  }

  /// Mark table as available/unavailable
  static Future<ApiResponse<RestaurantTable>> updateTableAvailability({
    required String tableId,
    required bool isAvailable,
  }) async {
    return await TableService.updateTableAvailability(
      id: tableId,
      isAvailable: isAvailable,
    );
  }

  /// Mark menu item as available/unavailable
  static Future<ApiResponse<MenuItem>> updateMenuItemAvailability({
    required String menuItemId,
    required bool isAvailable,
  }) async {
    return await MenuItemService.updateMenuItemAvailability(
      id: menuItemId,
      isAvailable: isAvailable,
    );
  }
}
