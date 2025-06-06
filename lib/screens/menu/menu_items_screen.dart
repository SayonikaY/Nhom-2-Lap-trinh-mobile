import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/menu_item_service.dart';
import 'menu_item_form_dialog.dart';

class MenuItemsScreen extends StatefulWidget {
  const MenuItemsScreen({super.key});

  @override
  State<MenuItemsScreen> createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  ItemKind? _selectedKind;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await MenuItemService.getAllMenuItems();
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _menuItems = response.data!;
          });
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to load menu items');
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

  Future<void> _showMenuItemForm({MenuItem? menuItem}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MenuItemFormDialog(menuItem: menuItem),
    );

    if (result == true) {
      _loadMenuItems(); // Refresh the list
    }
  }

  Future<void> _deleteMenuItem(MenuItem menuItem) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Menu Item'),
            content: Text(
              'Are you sure you want to delete "${menuItem.name}"?',
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
        final response = await MenuItemService.deleteMenuItem(menuItem.id);
        if (mounted) {
          if (response.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Menu item deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadMenuItems(); // Refresh the list
          } else {
            _showErrorSnackBar(
              response.message ?? 'Failed to delete menu item',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Network error. Please try again.');
        }
      }
    }
  }

  List<MenuItem> get filteredItems {
    if (_selectedKind == null) return _menuItems;
    return _menuItems.where((item) => item.kind == _selectedKind).toList();
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
                    selected: _selectedKind == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedKind = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...ItemKind.values.map(
                    (kind) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(kind.displayName),
                        selected: _selectedKind == kind,
                        onSelected: (selected) {
                          setState(() {
                            _selectedKind = selected ? kind : null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _loadMenuItems,
                      child:
                          filteredItems.isEmpty
                              ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No menu items found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap + to add a new menu item',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final menuItem = filteredItems[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color:
                                              menuItem.isAvailable
                                                  ? Colors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                  : Colors.grey.withValues(
                                                    alpha: 0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child:
                                            menuItem.imageUrl?.isNotEmpty ==
                                                    true
                                                ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    menuItem.imageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Icon(
                                                          Icons.restaurant,
                                                          color:
                                                              menuItem.isAvailable
                                                                  ? Colors.green
                                                                  : Colors.grey,
                                                        ),
                                                  ),
                                                )
                                                : Icon(
                                                  Icons.restaurant,
                                                  color:
                                                      menuItem.isAvailable
                                                          ? Colors.green
                                                          : Colors.grey,
                                                ),
                                      ),
                                      title: Text(
                                        menuItem.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(menuItem.kind.displayName),
                                          Text(
                                            '₫${menuItem.price.toStringAsFixed(2)}',
                                          ),
                                          if (menuItem
                                                  .description
                                                  ?.isNotEmpty ==
                                              true)
                                            Text(
                                              menuItem.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          Text(
                                            menuItem.isAvailable
                                                ? 'Available'
                                                : 'Not Available',
                                            style: TextStyle(
                                              color:
                                                  menuItem.isAvailable
                                                      ? Colors.green
                                                      : Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'edit':
                                              _showMenuItemForm(
                                                menuItem: menuItem,
                                              );
                                              break;
                                            case 'delete':
                                              _deleteMenuItem(menuItem);
                                              break;
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: ListTile(
                                                  leading: Icon(Icons.edit),
                                                  title: Text('Edit'),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
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
        onPressed: () => _showMenuItemForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
