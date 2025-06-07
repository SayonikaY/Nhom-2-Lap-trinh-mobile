enum OrderStatus {
  pending(0, 'Pending'),
  inProgress(1, 'In Progress'),
  completed(2, 'Completed'),
  cancelled(3, 'Cancelled');

  const OrderStatus(this.value, this.displayName);

  final int value;
  final String displayName;

  static OrderStatus fromValue(int value) =>
      OrderStatus.values.firstWhere((e) => e.value == value);
}

class Order {
  final String id;
  final String number;
  final String tableId;
  final String tableName;
  final OrderStatus status;
  final String? note;
  final double totalAmount;
  final String employeeId;
  final String employeeName;
  final DateTime createdAt;
  final List<OrderDetail> items;

  Order({
    required this.id,
    required this.number,
    required this.tableId,
    required this.tableName,
    required this.status,
    this.note,
    required this.totalAmount,
    required this.employeeId,
    required this.employeeName,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    number: json['number'],
    tableId: json['tableId'],
    tableName: json['tableName'],
    status: OrderStatus.fromValue(json['status']),
    note: json['note'],
    totalAmount: (json['totalAmount'] as num).toDouble(),
    employeeId: json['employeeId'],
    employeeName: json['employeeName'],
    createdAt: DateTime.parse(json['createdAt']),
    items:
        (json['items'] as List<dynamic>)
            .map((item) => OrderDetail.fromJson(item))
            .toList(),
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'tableId': tableId,
      'tableName': tableName,
      'status': status.value,
      'note': note,
      'totalAmount': totalAmount,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderDetail {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderDetail({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
    id: json['id'],
    menuItemId: json['menuItemId'],
    menuItemName: json['menuItemName'],
    quantity: json['quantity'],
    price: (json['price'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
    };
  }
}

class CreateOrderRequest {
  final String tableId;
  final String? note;
  final List<CreateOrderDetailRequest> items;

  CreateOrderRequest({required this.tableId, this.note, required this.items});

  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateOrderDetailRequest {
  final String menuItemId;
  final int quantity;

  CreateOrderDetailRequest({required this.menuItemId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {'menuItemId': menuItemId, 'quantity': quantity};
  }
}

class UpdateOrderStatusRequest {
  final OrderStatus status;

  UpdateOrderStatusRequest({required this.status});

  Map<String, dynamic> toJson() {
    return {'status': status.value};
  }
}
