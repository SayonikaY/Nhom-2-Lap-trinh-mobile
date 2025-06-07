import 'package:flutter/material.dart';
import 'package:nhom2_quanlynhahang/models/order.dart';

import '../../models/table.dart';
import '../../services/table_service.dart';

class TableFormDialog extends StatefulWidget {
  final RestaurantTable? table;

  const TableFormDialog({super.key, this.table});

  @override
  State<TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isAvailableForReservation = true;
  Order? _currentOrder;

  bool get isEditing => widget.table != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.table!.name;
      _capacityController.text = widget.table!.capacity.toString();
      _descriptionController.text = widget.table!.description ?? '';
      _isAvailableForReservation = widget.table!.isAvailableForPreOrder;
      _currentOrder = widget.table!.currentOrder;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final capacity = int.parse(_capacityController.text);
      final description = _descriptionController.text.trim();

      final response =
          isEditing
              ? await TableService.updateTable(
                widget.table!.id,
                UpdateTableRequest(
                  name: name,
                  capacity: capacity,
                  description: description.isEmpty ? null : description,
                  isAvailable: _isAvailableForReservation,
                ),
              )
              : await TableService.createTable(
                CreateTableRequest(
                  name: name,
                  capacity: capacity,
                  description: description.isEmpty ? null : description,
                ),
              );

      if (mounted) {
        if (response.success) {
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackBar(response.message ?? 'Operation failed');
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Table' : 'Add New Table'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Table Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter table name';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Capacity (people)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter capacity';
                }
                final capacity = int.tryParse(value);
                if (capacity == null || capacity <= 0) {
                  return 'Please enter a valid capacity';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Available for Reservation'),
              subtitle: const Text(
                'Allow customers to reserve this table in advance',
              ),
              value: _isAvailableForReservation,
              onChanged:
                  _isLoading
                      ? null
                      : (value) {
                        setState(() {
                          _isAvailableForReservation = value ?? true;
                        });
                      },
              controlAffinity: ListTileControlAffinity.leading,
              enabled:
                  !_isLoading &&
                  (!isEditing ||
                      _currentOrder == null ||
                      (_currentOrder!.status != OrderStatus.pending &&
                          _currentOrder!.status != OrderStatus.inProgress)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
