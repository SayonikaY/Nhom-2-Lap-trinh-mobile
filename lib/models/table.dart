import 'order.dart';

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  final String? description;
  final bool isAvailable;
  final DateTime createdAt;
  final Order? currentOrder;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.description,
    required this.isAvailable,
    required this.createdAt,
    this.currentOrder,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      RestaurantTable(
        id: json['id'],
        name: json['name'],
        capacity: json['capacity'],
        description: json['description'],
        isAvailable: json['isAvailable'],
        createdAt: DateTime.parse(json['createdAt']),
        currentOrder:
            json['currentOrder'] != null
                ? Order.fromJson(json['currentOrder'])
                : null,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'description': description,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'currentOrder': currentOrder?.toJson(),
    };
  }

  bool get isAvailableForPreOrder => isAvailable;
}

class CreateTableRequest {
  final String name;
  final int capacity;
  final String? description;

  CreateTableRequest({
    required this.name,
    required this.capacity,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'capacity': capacity, 'description': description};
  }
}

class UpdateTableRequest {
  final String? name;
  final int? capacity;
  final String? description;
  final bool? isAvailable;

  UpdateTableRequest({
    this.name,
    this.capacity,
    this.description,
    this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (capacity != null) data['capacity'] = capacity;
    if (description != null) data['description'] = description;
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    return data;
  }
}
