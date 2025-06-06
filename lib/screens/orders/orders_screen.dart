import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import 'create_order_screen.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = false;
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await OrderService.getAllOrders();
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _orders = response.data!;
          });
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to load orders');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Network error. Please try again.');
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

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      final response = await OrderService.updateOrderStatus(
        order.id,
        newStatus,
      );
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders(); // Refresh the list
        } else {
          _showErrorSnackBar(
            response.message ?? 'Failed to update order status',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Network error. Please try again.');
      }
    }
  }

  Future<void> _deleteOrder(Order order) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Order'),
            content: Text(
              'Are you sure you want to delete order "${order.number}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      try {
        final response = await OrderService.deleteOrder(order.id);
        if (mounted) {
          if (response.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadOrders(); // Refresh the list
          } else {
            _showErrorSnackBar(response.message ?? 'Failed to delete order');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Network error. Please try again.');
        }
      }
    }
  }

  List<Order> get filteredOrders {
    if (_selectedStatus == null) return _orders;
    return _orders.where((order) => order.status == _selectedStatus).toList();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...OrderStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.displayName),
                        selected: _selectedStatus == status,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? status : null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child:
                          filteredOrders.isEmpty
                              ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No orders found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap + to create a new order',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = filteredOrders[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            order.status,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.receipt,
                                          color: _getStatusColor(order.status),
                                        ),
                                      ),
                                      title: Text(
                                        'Order #${order.number}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Table: ${order.tableName}'),
                                          Text(
                                            'Employee: ${order.employeeName}',
                                          ),
                                          Text(
                                            'Total: ₫${order.totalAmount.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            order.status.displayName,
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                order.status,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'view':
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          OrderDetailsScreen(
                                                            order: order,
                                                          ),
                                                ),
                                              );
                                              break;
                                            case 'pending':
                                              _updateOrderStatus(
                                                order,
                                                OrderStatus.pending,
                                              );
                                              break;
                                            case 'inProgress':
                                              _updateOrderStatus(
                                                order,
                                                OrderStatus.inProgress,
                                              );
                                              break;
                                            case 'completed':
                                              _updateOrderStatus(
                                                order,
                                                OrderStatus.completed,
                                              );
                                              break;
                                            case 'cancelled':
                                              _updateOrderStatus(
                                                order,
                                                OrderStatus.cancelled,
                                              );
                                              break;
                                            case 'delete':
                                              _deleteOrder(order);
                                              break;
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              const PopupMenuItem(
                                                value: 'view',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.visibility,
                                                  ),
                                                  title: Text('View Details'),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                              const PopupMenuDivider(),
                                              const PopupMenuItem(
                                                value: 'pending',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.pending,
                                                    color: Colors.orange,
                                                  ),
                                                  title: Text(
                                                    'Mark as Pending',
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'inProgress',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.hourglass_empty,
                                                    color: Colors.blue,
                                                  ),
                                                  title: Text(
                                                    'Mark as In Progress',
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'completed',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  ),
                                                  title: Text(
                                                    'Mark as Completed',
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'cancelled',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                  title: Text(
                                                    'Mark as Cancelled',
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                              const PopupMenuDivider(),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  title: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            ],
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) => OrderDetailsScreen(
                                                  order: order,
                                                ),
                                          ),
                                        );
                                      },
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const CreateOrderScreen(),
                ),
              )
              .then((result) {
                if (result == true) {
                  _loadOrders(); // Refresh the list if an order was created
                }
              });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
