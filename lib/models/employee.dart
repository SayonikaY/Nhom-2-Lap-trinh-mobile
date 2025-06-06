class Employee {
  final String id;
  final String fullName;
  final String username;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.fullName,
    required this.username,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'],
    fullName: json['fullName'],
    username: json['username'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponse {
  final String token;
  final DateTime expiresAt;
  final Employee employee;

  LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.employee,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'],
    expiresAt: DateTime.parse(json['expiresAt']),
    employee: Employee.fromJson(json['employee']),
  );

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      'employee': employee.toJson(),
    };
  }
}

class CreateEmployeeRequest {
  final String fullName;
  final String username;
  final String password;

  CreateEmployeeRequest({
    required this.fullName,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'username': username,
      'password': password,
    };
  }
}
