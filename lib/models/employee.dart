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

class EmployeeSalesSummary {
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final double totalAmount;
  final int totalOrders;
  final int totalItems;
  final List<SalesOrder> orders;

  EmployeeSalesSummary({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.totalAmount,
    required this.totalOrders,
    required this.totalItems,
    required this.orders,
  });

  factory EmployeeSalesSummary.fromJson(Map<String, dynamic> json) =>
      EmployeeSalesSummary(
        employeeId: json['employeeId'],
        employeeName: json['employeeName'],
        date: DateTime.parse(json['date']),
        totalAmount: json['totalAmount'].toDouble(),
        totalOrders: json['totalOrders'],
        totalItems: json['totalItems'],
        orders:
            (json['orders'] as List)
                .map((order) => SalesOrder.fromJson(order))
                .toList(),
      );

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'totalOrders': totalOrders,
      'totalItems': totalItems,
      'orders': orders.map((order) => order.toJson()).toList(),
    };
  }
}

class SalesOrder {
  final String orderId;
  final String orderNumber;
  final double totalAmount;
  final DateTime createdAt;
  final int itemCount;

  SalesOrder({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.createdAt,
    required this.itemCount,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) => SalesOrder(
    orderId: json['orderId'],
    orderNumber: json['orderNumber'],
    totalAmount: json['totalAmount'].toDouble(),
    createdAt: DateTime.parse(json['createdAt']),
    itemCount: json['itemCount'],
  );

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'itemCount': itemCount,
    };
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
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
    return {'fullName': fullName, 'username': username, 'password': password};
  }
}
