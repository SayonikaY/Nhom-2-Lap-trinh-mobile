import 'package:flutter/material.dart';

import '../../models/table.dart';
import '../../services/table_service.dart';
import 'table_form_dialog.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await TableService.getAllTables();
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _tables = response.data!;
          });
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to load tables');
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

  Future<void> _showTableForm({RestaurantTable? table}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TableFormDialog(table: table),
    );

    if (result == true) {
      _loadTables(); // Refresh the list
    }
  }

  Future<void> _deleteTable(RestaurantTable table) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Table'),
            content: Text(
              'Are you sure you want to delete table "${table.name}"?',
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
        final response = await TableService.deleteTable(table.id);
        if (mounted) {
          if (response.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Table deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadTables(); // Refresh the list
          } else {
            _showErrorSnackBar(response.message ?? 'Failed to delete table');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Network error. Please try again.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadTables,
                child:
                    _tables.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_restaurant,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tables found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap + to add a new table',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tables.length,
                          itemBuilder: (context, index) {
                            final table = _tables[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        table.isAvailable
                                            ? Colors.green.withValues(
                                              alpha: 0.1,
                                            )
                                            : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.table_restaurant,
                                    color:
                                        table.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  table.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Capacity: ${table.capacity} people'),
                                    if (table.description?.isNotEmpty == true)
                                      Text(table.description!),
                                    Text(
                                      table.isAvailable
                                          ? 'Available'
                                          : 'Occupied',
                                      style: TextStyle(
                                        color:
                                            table.isAvailable
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
                                        _showTableForm(table: table);
                                        break;
                                      case 'delete':
                                        _deleteTable(table);
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
                                            contentPadding: EdgeInsets.zero,
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
                                            contentPadding: EdgeInsets.zero,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTableForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
