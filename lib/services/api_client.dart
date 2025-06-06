import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';

class ApiClient {
  // 10.0.2.2 is used to access the host machine's localhost from the Android emulator.
  static const String baseUrl = 'http://10.0.2.2:5127/api';
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  static bool get isAuthenticated =>
      _authToken != null && _authToken!.isNotEmpty;

  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  static Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final body = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return ApiResponse.success(
            fromJson(body),
            statusCode: response.statusCode,
          );
        } else if (body is List) {
          // Handle list responses
          final List<T> items =
              body
                  .map((item) => fromJson(item as Map<String, dynamic>))
                  .toList();
          return ApiResponse.success(
            items as T,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse.success(
            body as T,
            statusCode: response.statusCode,
          );
        }
      } else {
        String message = 'Request failed';
        if (body is Map<String, dynamic> && body.containsKey('message')) {
          message = body['message'];
        } else if (body is String) {
          message = body;
        }

        return ApiResponse.error(
          message,
          statusCode: response.statusCode,
          data: body,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  static Future<ApiResponse<List<T>>> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> body = json.decode(response.body);
        final List<T> items =
            body.map((item) => fromJson(item as Map<String, dynamic>)).toList();
        return ApiResponse.success(items, statusCode: response.statusCode);
      } else {
        final body = json.decode(response.body);
        String message = 'Request failed';
        if (body is Map<String, dynamic> && body.containsKey('message')) {
          message = body['message'];
        }

        return ApiResponse.error(
          message,
          statusCode: response.statusCode,
          data: body,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  static Future<ApiResponse<String>> _handleStringResponse(
    http.Response response,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          response.body,
          statusCode: response.statusCode,
        );
      } else {
        final body = json.decode(response.body);
        String message = 'Request failed';
        if (body is Map<String, dynamic> && body.containsKey('message')) {
          message = body['message'];
        }

        return ApiResponse.error(
          message,
          statusCode: response.statusCode,
          data: body,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to handle response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  // GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      String url = '$baseUrl$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map(
              (e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
            )
            .join('&');
        url += '?$query';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
      );

      return await _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // GET request for lists
  static Future<ApiResponse<List<T>>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      String url = '$baseUrl$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map(
              (e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
            )
            .join('&');
        url += '?$query';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
      );

      return await _handleListResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // POST request
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
        body: json.encode(data),
      );

      return await _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // PUT request
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
        body: json.encode(data),
      );

      return await _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // DELETE request
  static Future<ApiResponse<String>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
      );

      return await _handleStringResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // POST request without expecting response data (for operations like logout)
  static Future<ApiResponse<String>> postNoContent(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
        body: json.encode(data),
      );

      return await _handleStringResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}
