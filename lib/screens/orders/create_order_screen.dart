import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../models/table.dart';
import '../../services/menu_item_service.dart';
import '../../services/order_service.dart';
import '../../services/table_service.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _noteController = TextEditingController();
  RestaurantTable? _selectedTable;
  List<RestaurantTable> _tables = [];
  List<MenuItem> _menuItems = [];
  List<OrderItem> _orderItems = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tablesResponse = await TableService.getAllTables();
      final menuItemsResponse = await MenuItemService.getAllMenuItems();

      if (mounted) {
        if (tablesResponse.success && tablesResponse.data != null) {
          _tables = tablesResponse.data!;
        }
        if (menuItemsResponse.success && menuItemsResponse.data != null) {
          _menuItems =
              menuItemsResponse.data!
                  .where((item) => item.isAvailable)
                  .toList();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load data. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _addMenuItem(MenuItem menuItem) {
    setState(() {
      final existingIndex = _orderItems.indexWhere(
        (item) => item.menuItemId == menuItem.id,
      );

      if (existingIndex >= 0) {
        _orderItems[existingIndex] = OrderItem(
          menuItemId: menuItem.id,
          menuItemName: menuItem.name,
          quantity: _orderItems[existingIndex].quantity + 1,
          unitPrice: menuItem.price,
        );
      } else {
        _orderItems.add(
          OrderItem(
            menuItemId: menuItem.id,
            menuItemName: menuItem.name,
            quantity: 1,
            unitPrice: menuItem.price,
          ),
        );
      }
    });
  }

  void _removeMenuItem(String menuItemId) {
    setState(() {
      _orderItems.removeWhere((item) => item.menuItemId == menuItemId);
    });
  }

  void _updateQuantity(String menuItemId, int newQuantity) {
    if (newQuantity <= 0) {
      _removeMenuItem(menuItemId);
      return;
    }

    setState(() {
      final index = _orderItems.indexWhere(
        (item) => item.menuItemId == menuItemId,
      );
      if (index >= 0) {
        _orderItems[index] = OrderItem(
          menuItemId: _orderItems[index].menuItemId,
          menuItemName: _orderItems[index].menuItemName,
          quantity: newQuantity,
          unitPrice: _orderItems[index].unitPrice,
        );
      }
    });
  }

  double get totalAmount {
    return _orderItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _submitOrder() async {
    if (_selectedTable == null) {
      _showErrorSnackBar('Please select a table');
      return;
    }

    if (_orderItems.isEmpty) {
      _showErrorSnackBar('Please add at least one item to the order');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = CreateOrderRequest(
        tableId: _selectedTable!.id,
        note:
            _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
        items:
            _orderItems
                .map(
                  (item) => CreateOrderDetailRequest(
                    menuItemId: item.menuItemId,
                    quantity: item.quantity,
                  ),
                )
                .toList(),
      );

      final response = await OrderService.createOrder(request);
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to create order');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Network error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_orderItems.isNotEmpty)
            TextButton.icon(
              onPressed: _isSubmitting ? null : _submitOrder,
              icon:
                  _isSubmitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              label: const Text('Submit'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Table selection
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<RestaurantTable>(
              value: _selectedTable,
              decoration: const InputDecoration(
                labelText: 'Select Table',
                border: OutlineInputBorder(),
              ),
              items:
                  _tables.where((table) => table.isAvailable).map((table) {
                    return DropdownMenuItem(
                      value: table,
                      child: Text('${table.name} (${table.capacity} people)'),
                    );
                  }).toList(),
              onChanged: (table) {
                setState(() {
                  _selectedTable = table;
                });
              },
            ),
          ),

          // Order items summary
          if (_orderItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Items',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._orderItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.menuItemName)),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed:
                                        () => _updateQuantity(
                                          item.menuItemId,
                                          item.quantity - 1,
                                        ),
                                    icon: const Icon(Icons.remove),
                                    iconSize: 16,
                                  ),
                                  Text(item.quantity.toString()),
                                  IconButton(
                                    onPressed:
                                        () => _updateQuantity(
                                          item.menuItemId,
                                          item.quantity + 1,
                                        ),
                                    icon: const Icon(Icons.add),
                                    iconSize: 16,
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '₫${item.totalPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₫${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Note field
            Container(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
          ],

          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final menuItem = _menuItems[index];
                final existingItem = _orderItems.firstWhere(
                  (item) => item.menuItemId == menuItem.id,
                  orElse:
                      () => OrderItem(
                        menuItemId: '',
                        menuItemName: '',
                        quantity: 0,
                        unitPrice: 0,
                      ),
                );
                final isInOrder = existingItem.menuItemId.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          menuItem.imageUrl?.isNotEmpty == true
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  menuItem.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.restaurant,
                                            color: Colors.green,
                                          ),
                                ),
                              )
                              : const Icon(
                                Icons.restaurant,
                                color: Colors.green,
                              ),
                    ),
                    title: Text(menuItem.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(menuItem.kind.displayName),
                        Text('₫${menuItem.price.toStringAsFixed(2)}'),
                        if (menuItem.description?.isNotEmpty == true)
                          Text(
                            menuItem.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing:
                        isInOrder
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${existingItem.quantity}'),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _addMenuItem(menuItem),
                                  child: const Icon(Icons.add, size: 16),
                                ),
                              ],
                            )
                            : ElevatedButton(
                              onPressed: () => _addMenuItem(menuItem),
                              child: const Text('Add'),
                            ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}
