enum ItemKind {
  mainCourse(0, 'Main Course'),
  appetizer(1, 'Appetizer'),
  dessert(2, 'Dessert'),
  beverage(3, 'Beverage');

  const ItemKind(this.value, this.displayName);

  final int value;
  final String displayName;

  static ItemKind fromValue(int value) =>
      ItemKind.values.firstWhere((e) => e.value == value);
}

class MenuItem {
  final String id;
  final String name;
  final ItemKind kind;
  final double price;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.price,
    this.description,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'],
    name: json['name'],
    kind: ItemKind.fromValue(json['kind']),
    price: (json['price'] as num).toDouble(),
    description: json['description'],
    imageUrl: json['imageUrl'],
    isAvailable: json['isAvailable'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind.value,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CreateMenuItemRequest {
  final String name;
  final ItemKind kind;
  final double price;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;

  CreateMenuItemRequest({
    required this.name,
    required this.kind,
    required this.price,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'kind': kind.value,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}

class UpdateMenuItemRequest {
  final String? name;
  final ItemKind? kind;
  final double? price;
  final String? description;
  final String? imageUrl;
  final bool? isAvailable;

  UpdateMenuItemRequest({
    this.name,
    this.kind,
    this.price,
    this.description,
    this.imageUrl,
    this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (kind != null) data['kind'] = kind!.value;
    if (price != null) data['price'] = price;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    return data;
  }
}
