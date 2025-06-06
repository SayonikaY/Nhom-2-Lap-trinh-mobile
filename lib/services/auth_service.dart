import '../models/api_response.dart';
import '../models/employee.dart';
import 'api_client.dart';

class AuthService {
  static const String _endpoint = '/auth';

  /// Login with username and password
  static Future<ApiResponse<LoginResponse>> login({
    required String username,
    required String password,
  }) async {
    final request = LoginRequest(username: username, password: password);

    final response = await ApiClient.post(
      '$_endpoint/login',
      request.toJson(),
      (json) => LoginResponse.fromJson(json),
      includeAuth: false,
    );

    if (response.success && response.data != null) {
      // Set the auth token for future requests
      ApiClient.setAuthToken(response.data!.token);
    }

    return response;
  }

  /// Register a new employee
  static Future<ApiResponse<Employee>> register({
    required String fullName,
    required String username,
    required String password,
  }) async {
    final request = CreateEmployeeRequest(
      fullName: fullName,
      username: username,
      password: password,
    );

    return await ApiClient.post(
      '$_endpoint/register',
      request.toJson(),
      (json) => Employee.fromJson(json),
      includeAuth: false,
    );
  }

  /// Get current user profile
  static Future<ApiResponse<Employee>> getProfile() async {
    return await ApiClient.get(
      '$_endpoint/profile',
      (json) => Employee.fromJson(json),
    );
  }

  /// Logout (clear auth token)
  static Future<void> logout() async {
    ApiClient.setAuthToken(null);
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => ApiClient.isAuthenticated;

  /// Get current auth token
  static String? get authToken => ApiClient.authToken;
}
