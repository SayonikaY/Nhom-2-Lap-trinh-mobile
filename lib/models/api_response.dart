class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) =>
      ApiResponse(
        success: true,
        statusCode: statusCode,
        data: data,
      );

  factory ApiResponse.error(String message, {int? statusCode, dynamic data}) =>
      ApiResponse(
        success: false,
        message: message,
        statusCode: statusCode,
        data: data,
      );
}
